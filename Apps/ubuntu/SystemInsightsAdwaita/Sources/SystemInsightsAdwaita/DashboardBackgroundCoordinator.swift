import Adwaita
import Foundation
import SystemInsightCore

/// Cancellable background sampling for the operations dashboard (replaces stacked `Idle` loops).
@MainActor
final class DashboardBackgroundCoordinator {
    private var liveNetworkTask: Task<Void, Never>?
    private var socketTask: Task<Void, Never>?
    private var pathMonitoringTask: Task<Void, Never>?
    private var telemetryTask: Task<Void, Never>?
    private var snapshotTask: Task<Void, Never>?

    func start(
        canWork: @escaping @MainActor () -> Bool,
        onLiveNetworkRefresh: @escaping @Sendable () async -> Void,
        onSocketRefresh: @escaping @Sendable () async -> Void,
        onTelemetryRefresh: @escaping @Sendable () async -> Void,
        onSnapshotCollect: @escaping @Sendable () async -> Void
    ) {
        stop()
        liveNetworkTask = loop(every: .seconds(2), canWork: canWork, work: onLiveNetworkRefresh)
        socketTask = loop(every: .seconds(6), canWork: canWork, work: onSocketRefresh)
        #if os(macOS)
        pathMonitoringTask = Task {
            await NetworkSamplingService.shared.startPathMonitoring(onPathChange: onLiveNetworkRefresh)
        }
        #endif
        telemetryTask = loop(every: .seconds(15), canWork: canWork, work: onTelemetryRefresh)
        snapshotTask = loop(every: .seconds(10 * 60), canWork: canWork, work: onSnapshotCollect)
        scheduleInitialRefresh(
            onLiveNetworkRefresh: onLiveNetworkRefresh,
            onSocketRefresh: onSocketRefresh
        )
    }

    private func scheduleInitialRefresh(
        onLiveNetworkRefresh: @escaping @Sendable () async -> Void,
        onSocketRefresh: @escaping @Sendable () async -> Void
    ) {
        Task.detached(priority: .utility) {
            await onLiveNetworkRefresh()
            await onSocketRefresh()
        }
    }

    func stop() {
        liveNetworkTask?.cancel()
        socketTask?.cancel()
        pathMonitoringTask?.cancel()
        pathMonitoringTask = nil
        telemetryTask?.cancel()
        snapshotTask?.cancel()
        liveNetworkTask = nil
        socketTask = nil
        telemetryTask = nil
        snapshotTask = nil
        Task {
            await NetworkSamplingService.shared.stopPathMonitoring()
        }
    }

    /// Runs `work` on a fixed interval without compounding delay when `work` runs longer than the interval.
    private func loop(
        every interval: Duration,
        canWork: @escaping @MainActor () -> Bool,
        work: @escaping @Sendable () async -> Void
    ) -> Task<Void, Never> {
        #if os(Linux)
        return Task.detached(priority: .utility) {
            while !Task.isCancelled {
                let allowed = await UIViewDeferral.readOnMain { canWork() }
                guard allowed else {
                    try? await Task.sleep(for: .milliseconds(400))
                    continue
                }
                await work()
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: interval)
            }
        }
        #else
        Task {
            while !Task.isCancelled {
                while await MainActor.run(body: { !canWork() }) {
                    do {
                        try await Task.sleep(for: .milliseconds(400))
                    } catch {
                        return
                    }
                    if Task.isCancelled { return }
                }
                let startedAt = ContinuousClock.now
                await work()
                guard !Task.isCancelled else { return }
                let elapsed = startedAt.duration(to: ContinuousClock.now)
                let remainder = interval > elapsed ? interval - elapsed : .milliseconds(200)
                do {
                    try await Task.sleep(for: remainder)
                } catch {
                    return
                }
            }
        }
        #endif
    }
}
