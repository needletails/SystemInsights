import Foundation

/// Coalesces overlapping metric and socket samples so timers cannot stack subprocess work.
public actor NetworkSamplingService {
    public static let shared = NetworkSamplingService()

    private let collector = SystemMetricCollector()
    private var socketsTask: Task<[VisibleSocket], Never>?
    private var metricsTask: Task<PerformanceMetrics, Error>?
    private var liveNetworkTask: Task<NetworkMetrics, Error>?
    private var pathMonitoringTask: Task<Void, Never>?

    private init() {}

    public func visibleSockets() async -> [VisibleSocket] {
        if let socketsTask {
            return await socketsTask.value
        }
        let collector = collector
        let task = Task.detached(priority: .utility) {
            await collector.collectVisibleSockets()
        }
        socketsTask = task
        defer { socketsTask = nil }
        let sockets = await task.value
        return Array(sockets.prefix(NetworkSamplingLimits.maxVisibleSockets))
    }

    public func collectMetrics() async throws -> PerformanceMetrics {
        if let metricsTask {
            return try await metricsTask.value
        }
        let collector = collector
        let task = Task.detached(priority: .utility) {
            try await collector.collect()
        }
        metricsTask = task
        defer { metricsTask = nil }
        return try await task.value
    }

    public func liveNetworkMetrics(
        preserving status: NetworkMetrics,
        establishedTCPCount: Int? = nil
    ) async throws -> NetworkMetrics {
        if let liveNetworkTask {
            return try await liveNetworkTask.value
        }
        await NetworkPathObservationService.shared.ensureRunning()
        let refreshVPN = await NetworkPathObservationService.shared.shouldRefreshVPN()
        let inputs = LiveNetworkSampleInputs(
            preserving: status,
            establishedTCPCount: establishedTCPCount,
            refreshVPN: refreshVPN
        )
        let collector = collector
        let task = Task.detached(priority: .utility) {
            try await collector.collectLiveNetworkMetrics(inputs: inputs)
        }
        liveNetworkTask = task
        defer { liveNetworkTask = nil }
        return try await task.value
    }

    /// Observes route/path changes (macOS) and invokes `onPathChange` for an immediate network refresh.
    public func startPathMonitoring(onPathChange: @escaping @Sendable () async -> Void) {
        guard pathMonitoringTask == nil else { return }
        pathMonitoringTask = Task {
            await NetworkPathObservationService.shared.ensureRunning()
            for await _ in await NetworkPathObservationService.shared.pathUpdates() {
                guard !Task.isCancelled else { return }
                await onPathChange()
            }
        }
    }

    public func stopPathMonitoring() {
        pathMonitoringTask?.cancel()
        pathMonitoringTask = nil
        Task {
            await NetworkPathObservationService.shared.stop()
        }
    }

    public func fullSnapshot() async throws -> InsightSnapshot {
        try await Task.detached(priority: .utility) {
            try await InsightEngine().snapshot()
        }.value
    }
}
