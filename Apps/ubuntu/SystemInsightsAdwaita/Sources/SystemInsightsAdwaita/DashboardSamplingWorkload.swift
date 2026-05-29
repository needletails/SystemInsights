import Foundation
import SystemInsightCore

/// Background sampling and collection. ``Sendable`` async entry points run I/O off the UI actor
/// and apply results through ``DashboardGTKBridge``.
enum DashboardSamplingWorkload {
    nonisolated static func refreshLiveNetwork() async {
        await withLiveNetworkRefresh {
            let inputs = await DashboardGTKBridge.runOnMain {
                let model = DashboardViewModel.shared
                return (
                    model.liveNetwork ?? model.snapshot?.metrics.network ?? .unavailable,
                    model.visibleSockets.filter { $0.state == .established }.count
                )
            }
            do {
                let network = try await DashboardSamplingPipeline.pollLiveNetwork(
                    preserving: inputs.0,
                    establishedTCPCount: inputs.1
                )
                await DashboardGTKBridge.runOnMain {
                    DashboardViewModel.shared.applyLiveNetwork(network)
                }
                DashboardCollectDiagnostics.log(
                    "network poll: rx=\(Int(network.receivedBytesPerSecond)) tx=\(Int(network.sentBytesPerSecond)) if=\(network.interfaceName ?? "?")"
                )
            } catch {
                DashboardCollectDiagnostics.log("network refresh failed: \(error)")
            }
        }
    }

    nonisolated static func refreshSockets() async {
        await withSocketRefresh { context in
            let connections = await DashboardSamplingPipeline.pollSockets()
            let socketUpdate = await Task.detached {
                DashboardSamplingPipeline.prepareSocketUIUpdate(
                    connections: connections,
                    previousFingerprint: context.fingerprint,
                    previousConnections: context.previousConnections,
                    recentActivity: context.recentActivity,
                    force: context.force
                )
            }.value

            if let socketUpdate {
                await DashboardGTKBridge.runOnMain {
                    DashboardViewModel.shared.applyLiveSocketUpdate(socketUpdate)
                }
                DashboardCollectDiagnostics.log("socket poll: \(socketUpdate.connections.count) sockets")
            } else if !connections.isEmpty {
                await DashboardGTKBridge.runOnMain {
                    DashboardViewModel.shared.applyLiveSocketUpdate(
                        DashboardSamplingPipeline.SocketUIUpdate(
                            connections: connections,
                            fingerprint: VisibleSocketSampling.fingerprint(connections),
                            index: SocketConsoleFilter.buildIndex(connections: connections),
                            recentActivity: context.recentActivity,
                            previousConnections: Dictionary(uniqueKeysWithValues: connections.map { ($0.id, $0) })
                        )
                    )
                }
            }
        }
    }

    nonisolated static func refreshTelemetry() async {
        await withTelemetryRefresh { currentSnapshot, activitySnapshot in
            do {
                let refreshedSnapshot = try await Task.detached {
                    let refreshedMetrics = try await NetworkSamplingService.shared.collectMetrics()
                    return DashboardSamplingPipeline.buildTelemetrySnapshot(
                        current: currentSnapshot,
                        metrics: refreshedMetrics,
                        recentActivity: activitySnapshot
                    )
                }.value
                await DashboardGTKBridge.runOnMain {
                    DashboardViewModel.shared.applyTelemetrySnapshot(refreshedSnapshot)
                }
            } catch {
                DashboardCollectDiagnostics.log("telemetry refresh failed: \(error)")
            }
        }
    }

    nonisolated static func collectSnapshot() async {
        await DashboardGTKBridge.runOnMain {
            DashboardViewModel.shared.prepareCacheSessionIfNeeded()
            DashboardViewModel.shared.markCollectStarted()
        }

        let startedAt = Date()
        do {
            DashboardCollectDiagnostics.log("collect: policy scan…")
            let baseSnapshot = try await NetworkSamplingService.shared.fullSnapshot()
            DashboardCollectDiagnostics.log(
                "collect: policy scan done (score=\(baseSnapshot.score), elapsed=\(String(format: "%.1f", Date().timeIntervalSince(startedAt)))s)"
            )

            DashboardCollectDiagnostics.log("collect: visible sockets…")
            let sockets = await NetworkSamplingService.shared.visibleSockets()
            DashboardCollectDiagnostics.log("collect: sockets=\(sockets.count)")

            let prepContext = await DashboardGTKBridge.runOnMain {
                let model = DashboardViewModel.shared
                return (model.previousConnections, model.recentActivity)
            }
            let socketUpdate = await Task.detached {
                DashboardSamplingPipeline.prepareSocketUIUpdate(
                    connections: sockets,
                    previousFingerprint: nil,
                    previousConnections: prepContext.0,
                    recentActivity: prepContext.1,
                    force: true
                )
            }.value

            let collectedSnapshot = baseSnapshot.withNetworkActivity(
                Array((socketUpdate?.recentActivity ?? prepContext.1).prefix(NetworkSamplingLimits.maxActivityEvents))
            )
            try await Task.detached {
                try DashboardCacheLocations.writeSnapshot(collectedSnapshot)
            }.value
            DashboardCollectDiagnostics.log("collect: cache write ok")

            await DashboardGTKBridge.runOnMain {
                DashboardViewModel.shared.markCollectSucceeded(
                    snapshot: collectedSnapshot,
                    socketUpdate: socketUpdate
                )
            }
        } catch {
            DashboardCollectDiagnostics.log("collect failed: \(error)")
            await DashboardGTKBridge.runOnMain {
                DashboardViewModel.shared.markCollectFailed(error)
            }
        }
    }
}

private extension DashboardSamplingWorkload {
    struct SocketRefreshContext: Sendable {
        let fingerprint: UInt64?
        let previousConnections: [String: VisibleSocket]?
        let recentActivity: [NetworkActivityEvent]
        let force: Bool
    }

    static func withLiveNetworkRefresh(_ operation: () async -> Void) async {
        let started = await DashboardGTKBridge.runOnMain {
            guard DashboardViewModel.shared.cacheIsUnlockedForCollect() else { return false }
            DashboardViewModel.shared.isRefreshingLiveNetwork = true
            return true
        }
        guard started else { return }
        await operation()
        await DashboardGTKBridge.runOnMain {
            DashboardViewModel.shared.isRefreshingLiveNetwork = false
        }
    }

    static func withSocketRefresh(_ operation: (SocketRefreshContext) async -> Void) async {
        let context = await DashboardGTKBridge.runOnMain { () -> (Bool, SocketRefreshContext?) in
            guard DashboardViewModel.shared.cacheIsUnlockedForCollect() else {
                return (false, nil)
            }
            DashboardViewModel.shared.isRefreshingSockets = true
            let model = DashboardViewModel.shared
            let refresh = SocketRefreshContext(
                fingerprint: model.lastSocketFingerprint,
                previousConnections: model.previousConnections,
                recentActivity: model.recentActivity,
                force: model.visibleSockets.isEmpty
            )
            return (true, refresh)
        }
        guard context.0, let refresh = context.1 else { return }
        await operation(refresh)
        await DashboardGTKBridge.runOnMain {
            DashboardViewModel.shared.isRefreshingSockets = false
        }
    }

    static func withTelemetryRefresh(
        _ operation: (InsightSnapshot, [NetworkActivityEvent]) async -> Void
    ) async {
        let context = await DashboardGTKBridge.runOnMain { () -> (Bool, InsightSnapshot?, [NetworkActivityEvent]) in
            let model = DashboardViewModel.shared
            guard model.cacheIsUnlockedForCollect(), !model.isRefreshingTelemetry, let snap = model.snapshot else {
                return (false, nil, [])
            }
            model.isRefreshingTelemetry = true
            return (true, snap, model.recentActivity)
        }
        guard context.0, let snapshot = context.1 else { return }
        await operation(snapshot, context.2)
        await DashboardGTKBridge.runOnMain {
            DashboardViewModel.shared.isRefreshingTelemetry = false
        }
    }
}
