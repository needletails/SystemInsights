import Adwaita
import Foundation
import SystemInsightCore

/// Owns background sampling tasks. An ``actor`` serializes start/stop/collect so Linux/GTK never
/// relies on ``MainActor`` task scheduling for lifecycle work.
actor DashboardSamplingScheduler {
    static let shared = DashboardSamplingScheduler()

    private var liveNetworkTask: Task<Void, Never>?
    private var socketTask: Task<Void, Never>?
    private var pathMonitoringTask: Task<Void, Never>?
    private var telemetryTask: Task<Void, Never>?
    private var snapshotTask: Task<Void, Never>?
    private var initialRefreshTask: Task<Void, Never>?
    private var collectTask: Task<Void, Never>?

    func startMonitoring() {
        stopMonitoringTasks()
        DashboardCollectDiagnostics.log("monitoring loops scheduled")

        liveNetworkTask = intervalLoop(
            label: "network",
            every: .seconds(2),
            canWork: DashboardSamplingGate.canPollLiveNetwork,
            work: DashboardSamplingWorkload.refreshLiveNetwork
        )
        socketTask = intervalLoop(
            label: "sockets",
            every: .seconds(6),
            canWork: DashboardSamplingGate.canPollSockets,
            work: DashboardSamplingWorkload.refreshSockets
        )
        #if os(macOS)
        pathMonitoringTask = Task {
            await NetworkSamplingService.shared.startPathMonitoring(
                onPathChange: DashboardSamplingWorkload.refreshLiveNetwork
            )
        }
        #endif
        telemetryTask = intervalLoop(
            label: "telemetry",
            every: .seconds(15),
            canWork: DashboardSamplingGate.canPollTelemetry,
            work: DashboardSamplingWorkload.refreshTelemetry
        )
        snapshotTask = intervalLoop(
            label: "snapshot",
            every: .seconds(10 * 60),
            canWork: DashboardSamplingGate.canPollTelemetry,
            work: DashboardSamplingWorkload.collectSnapshot
        )
        initialRefreshTask = Task.detached(priority: .utility) {
            await DashboardSamplingWorkload.refreshLiveNetwork()
            await DashboardSamplingWorkload.refreshSockets()
        }
    }

    func stopMonitoring() {
        stopMonitoringTasks()
        DashboardCollectDiagnostics.log("monitoring loops stopped")
    }

    func requestCollect() async {
        if collectTask != nil {
            DashboardCollectDiagnostics.log("collect already scheduled")
            return
        }

        let shouldStart = await DashboardGTKBridge.runOnMain {
            let model = DashboardViewModel.shared
            guard model.cacheIsUnlockedForCollect() else { return false }
            return !model.isCollecting
        }
        guard shouldStart else {
            await DashboardGTKBridge.runOnMain {
                if !DashboardViewModel.shared.cacheIsUnlockedForCollect() {
                    DashboardViewModel.shared.reportCollectLocked()
                }
            }
            return
        }

        collectTask = Task.detached(priority: .userInitiated) {
            await DashboardSamplingWorkload.collectSnapshot()
            await DashboardSamplingScheduler.shared.releaseCollect()
        }
    }

    private func releaseCollect() {
        collectTask = nil
    }

    private func stopMonitoringTasks() {
        liveNetworkTask?.cancel()
        socketTask?.cancel()
        pathMonitoringTask?.cancel()
        pathMonitoringTask = nil
        telemetryTask?.cancel()
        snapshotTask?.cancel()
        initialRefreshTask?.cancel()
        liveNetworkTask = nil
        socketTask = nil
        telemetryTask = nil
        snapshotTask = nil
        initialRefreshTask = nil
        Task {
            await NetworkSamplingService.shared.stopPathMonitoring()
        }
    }

    private func intervalLoop(
        label: String,
        every interval: Duration,
        canWork: @escaping @Sendable () async -> Bool,
        work: @escaping @Sendable () async -> Void
    ) -> Task<Void, Never> {
        Task.detached(priority: .utility) {
            var ticks = 0
            while !Task.isCancelled {
                let allowed = await canWork()
                guard allowed else {
                    try? await Task.sleep(for: .milliseconds(400))
                    continue
                }
                if ticks == 0 {
                    DashboardCollectDiagnostics.log("monitoring loop active (\(label))")
                }
                ticks += 1
                let startedAt = ContinuousClock.now
                await work()
                guard !Task.isCancelled else { return }
                let elapsed = startedAt.duration(to: ContinuousClock.now)
                let remainder = interval > elapsed ? interval - elapsed : .milliseconds(200)
                try? await Task.sleep(for: remainder)
            }
        }
    }
}

/// MainActor state checks bridged for background loops.
enum DashboardSamplingGate {
    nonisolated static func canPollLiveNetwork() async -> Bool {
        await DashboardGTKBridge.runOnMain {
            let model = DashboardViewModel.shared
            return model.isMonitoring && model.cacheIsUnlockedForCollect()
        }
    }

    nonisolated static func canPollSockets() async -> Bool {
        await DashboardGTKBridge.runOnMain {
            let model = DashboardViewModel.shared
            return model.isMonitoring
                && model.cacheIsUnlockedForCollect()
                && !model.isCollecting
        }
    }

    nonisolated static func canPollTelemetry() async -> Bool {
        await canPollSockets()
    }
}
