import Adwaita
import Foundation
import SystemInsightCore

/// Owns background sampling tasks. An ``actor`` serializes start/stop/collect so Linux/GTK never
/// relies on ``MainActor`` task scheduling for lifecycle work.
actor DashboardSamplingScheduler {
    static let shared = DashboardSamplingScheduler()

    private var monitoringTask: Task<Void, Never>?
    private var pathMonitoringTask: Task<Void, Never>?
    private var collectTask: Task<Void, Never>?

    func startMonitoring() {
        stopMonitoringTasks()
        DashboardCollectDiagnostics.log("monitoring loop scheduled")

        #if os(macOS)
        pathMonitoringTask = Task {
            await NetworkSamplingService.shared.startPathMonitoring(
                onPathChange: DashboardSamplingWorkload.refreshLiveNetwork
            )
        }
        #endif

        monitoringTask = Task.detached(priority: .utility) {
            var tick = 0
            while !Task.isCancelled {
                guard await DashboardSamplingGate.canPollLiveNetwork() else {
                    try? await Task.sleep(for: .milliseconds(400))
                    continue
                }
                if tick == 0 {
                    DashboardCollectDiagnostics.log("monitoring loop active")
                }

                await DashboardSamplingWorkload.refreshLiveNetwork()

                if await DashboardSamplingGate.canPollSockets(), tick >= 3, tick.isMultiple(of: 3) {
                    await DashboardSamplingWorkload.refreshSockets()
                }
                if await DashboardSamplingGate.canPollSockets(), tick.isMultiple(of: 15), tick > 0 {
                    await DashboardSamplingWorkload.refreshTelemetry()
                }
                if await DashboardSamplingGate.canPollSockets(), tick.isMultiple(of: 300), tick > 0 {
                    await DashboardSamplingScheduler.shared.requestPeriodicSnapshot()
                }

                tick += 1
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    func stopMonitoring() {
        stopMonitoringTasks()
        DashboardCollectDiagnostics.log("monitoring loop stopped")
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

    private func requestPeriodicSnapshot() async {
        guard collectTask == nil else { return }
        let shouldStart = await DashboardGTKBridge.runOnMain {
            DashboardViewModel.shared.cacheIsUnlockedForCollect() && !DashboardViewModel.shared.isCollecting
        }
        guard shouldStart else { return }
        collectTask = Task.detached(priority: .utility) {
            await DashboardSamplingWorkload.collectSnapshot()
            await DashboardSamplingScheduler.shared.releaseCollect()
        }
    }

    private func releaseCollect() {
        collectTask = nil
    }

    private func stopMonitoringTasks() {
        monitoringTask?.cancel()
        pathMonitoringTask?.cancel()
        pathMonitoringTask = nil
        monitoringTask = nil
        Task {
            await NetworkSamplingService.shared.stopPathMonitoring()
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
}
