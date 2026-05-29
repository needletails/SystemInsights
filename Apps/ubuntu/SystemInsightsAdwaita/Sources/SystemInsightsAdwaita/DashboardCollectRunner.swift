import Adwaita
import Foundation
import SystemInsightCore

/// Linux/GTK collect pipeline (build marker: COLLECT_V3).
///
/// GNOME Builder + GTK do not run ``DispatchQueue.main`` or ``Task { @MainActor }`` scheduled from
/// button handlers. Collection runs on a worker thread; UI updates use ``Idle`` + ``MainActor.assumeIsolated``.
enum DashboardCollectRunner {
    private static let buildMarker = "COLLECT_V3"

    nonisolated static func start() {
        DashboardCollectDiagnostics.log("\(buildMarker) button -> worker thread")
        Thread.detachNewThread {
            workerThreadMain()
        }
    }

    nonisolated private static func workerThreadMain() {
        DashboardCollectDiagnostics.log("\(buildMarker) worker thread running")
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await runCollectWork()
            semaphore.signal()
        }
        semaphore.wait()
        DashboardCollectDiagnostics.log("\(buildMarker) worker thread finished")
    }

    nonisolated private static func runCollectWork() async {
        DashboardCollectDiagnostics.log("\(buildMarker) collect work entered")

        let unlocked = await gtkMain {
            DashboardViewModel.shared.cacheIsUnlockedForCollect()
        }
        guard unlocked else {
            await gtkMain {
                DashboardViewModel.shared.reportCollectLocked()
            }
            return
        }

        await gtkMain {
            DashboardViewModel.shared.prepareCacheSessionIfNeeded()
            DashboardViewModel.shared.markCollectStarted()
        }

        let startedAt = Date()
        do {
            DashboardCollectDiagnostics.log("\(buildMarker) metrics + policy scan…")
            let baseSnapshot = try await NetworkSamplingService.shared.fullSnapshot()
            DashboardCollectDiagnostics.log(
                "\(buildMarker) snapshot done score=\(baseSnapshot.score) elapsed=\(String(format: "%.1f", Date().timeIntervalSince(startedAt)))s"
            )

            DashboardCollectDiagnostics.log("\(buildMarker) visible sockets…")
            let sockets = await NetworkSamplingService.shared.visibleSockets()
            DashboardCollectDiagnostics.log("\(buildMarker) sockets=\(sockets.count)")

            let socketUpdate = DashboardSamplingPipeline.prepareSocketUIUpdate(
                connections: sockets,
                previousFingerprint: nil,
                previousConnections: nil,
                recentActivity: [],
                force: true
            )

            let activity = socketUpdate?.recentActivity ?? []
            let collectedSnapshot = baseSnapshot.withNetworkActivity(
                Array(activity.prefix(NetworkSamplingLimits.maxActivityEvents))
            )
            try await Task.detached {
                try DashboardCacheLocations.writeSnapshot(collectedSnapshot)
            }.value
            DashboardCollectDiagnostics.log("\(buildMarker) cache write ok")

            await gtkMain {
                DashboardViewModel.shared.markCollectSucceeded(
                    snapshot: collectedSnapshot,
                    socketUpdate: socketUpdate
                )
            }
        } catch {
            DashboardCollectDiagnostics.log("\(buildMarker) collect failed: \(error)")
            await gtkMain {
                DashboardViewModel.shared.markCollectFailed(error)
            }
        }
    }

    /// Schedule synchronous MainActor work on the GTK main loop.
    nonisolated private static func gtkMain<T: Sendable>(
        _ work: @escaping @MainActor () -> T
    ) async -> T {
        await withCheckedContinuation { continuation in
            Idle {
                let value = MainActor.assumeIsolated {
                    work()
                }
                continuation.resume(returning: value)
            }
        }
    }
}
