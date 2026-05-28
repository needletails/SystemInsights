import Foundation
import SystemInsightCore

/// Background preparation for dashboard refresh so GTK never blocks on lsof parsing or index builds.
enum DashboardSamplingPipeline {
    struct NetworkPollSample: Sendable {
        let network: NetworkMetrics
        let connections: [VisibleSocket]
    }

    struct SocketUIUpdate: Sendable {
        let connections: [VisibleSocket]
        let fingerprint: UInt64
        let index: [SocketConsoleFilter.IndexEntry]
        let recentActivity: [NetworkActivityEvent]
        let previousConnections: [String: VisibleSocket]
    }

    static func pollLiveNetwork(
        preserving baseline: NetworkMetrics,
        establishedTCPCount: Int
    ) async throws -> NetworkMetrics {
        try await NetworkSamplingService.shared.liveNetworkMetrics(
            preserving: baseline,
            establishedTCPCount: establishedTCPCount
        )
    }

    static func pollSockets() async -> [VisibleSocket] {
        await NetworkSamplingService.shared.visibleSockets()
    }

    /// Samples live throughput and socket inventory concurrently (does not wait for lsof before starting rates).
    static func pollNetwork(
        preserving baseline: NetworkMetrics,
        establishedTCPCount: Int? = nil
    ) async throws -> NetworkPollSample {
        let tcpEstimate = establishedTCPCount ?? baseline.activeTCPConnections
        async let network = NetworkSamplingService.shared.liveNetworkMetrics(
            preserving: baseline,
            establishedTCPCount: tcpEstimate
        )
        async let connections = NetworkSamplingService.shared.visibleSockets()
        let resolvedConnections = await connections
        var resolvedNetwork = try await network
        let tcpCount = resolvedConnections.filter { $0.state == .established }.count
        if tcpCount != resolvedNetwork.activeTCPConnections {
            resolvedNetwork = NetworkMetrics(
                interfaceName: resolvedNetwork.interfaceName,
                receivedBytesPerSecond: resolvedNetwork.receivedBytesPerSecond,
                sentBytesPerSecond: resolvedNetwork.sentBytesPerSecond,
                latencyMilliseconds: resolvedNetwork.latencyMilliseconds,
                activeTCPConnections: tcpCount,
                vpn: resolvedNetwork.vpn
            )
        }
        return NetworkPollSample(network: resolvedNetwork, connections: resolvedConnections)
    }

    /// Returns `nil` when the socket set is unchanged (skip GTK table rebuild).
    static func prepareSocketUIUpdate(
        connections: [VisibleSocket],
        previousFingerprint: UInt64?,
        previousConnections: [String: VisibleSocket]?,
        recentActivity: [NetworkActivityEvent],
        force: Bool = false
    ) -> SocketUIUpdate? {
        let fingerprint = VisibleSocketSampling.fingerprint(connections)
        if !force, fingerprint == previousFingerprint {
            return nil
        }

        let current = Dictionary(uniqueKeysWithValues: connections.map { ($0.id, $0) })
        let mergedActivity = mergeActivity(
            connections: connections,
            current: current,
            previousConnections: previousConnections,
            recentActivity: recentActivity
        )

        return SocketUIUpdate(
            connections: connections,
            fingerprint: fingerprint,
            index: SocketConsoleFilter.buildIndex(connections: connections),
            recentActivity: mergedActivity,
            previousConnections: current
        )
    }

    static func buildTelemetrySnapshot(
        current: InsightSnapshot,
        metrics: PerformanceMetrics,
        recentActivity: [NetworkActivityEvent]
    ) -> InsightSnapshot {
        let scorer = InsightScorer()
        let issues = scorer.issues(for: metrics, findings: current.securityFindings)
        let score = scorer.score(for: issues)
        let recommendations = issues.compactMap(\.recommendation).reduce(into: [String]()) { values, value in
            if !values.contains(value) { values.append(value) }
        }
        return InsightSnapshot(
            schemaVersion: current.schemaVersion,
            generatedAt: Date(),
            host: current.host,
            metrics: metrics,
            networkActivity: Array(recentActivity.prefix(NetworkSamplingLimits.maxActivityEvents)),
            securityFindings: current.securityFindings,
            securityEvents: current.securityEvents,
            issues: issues,
            score: score,
            rating: scorer.rating(for: score, issues: issues),
            recommendations: recommendations,
            topIssue: issues.first
        ).clampedForPersistence()
    }

    private static func mergeActivity(
        connections: [VisibleSocket],
        current: [String: VisibleSocket],
        previousConnections: [String: VisibleSocket]?,
        recentActivity: [NetworkActivityEvent]
    ) -> [NetworkActivityEvent] {
        let now = Date()
        guard let previousConnections else {
            let observed = connections.prefix(12).map {
                NetworkActivityEvent(
                    timestamp: now,
                    action: $0.state == .listening ? .listening : .observed,
                    connection: $0
                )
            }
            return Array((observed + recentActivity).prefix(NetworkSamplingLimits.maxActivityEvents))
        }

        let appeared = current.keys
            .filter { previousConnections[$0] == nil }
            .compactMap { current[$0] }
            .map {
                NetworkActivityEvent(
                    timestamp: now,
                    action: $0.state == .listening ? .listening : .opened,
                    connection: $0
                )
            }
        let disappeared = previousConnections.keys
            .filter { current[$0] == nil }
            .compactMap { previousConnections[$0] }
            .map {
                NetworkActivityEvent(
                    timestamp: now,
                    action: $0.state == .listening ? .stoppedListening : .closed,
                    connection: $0
                )
            }
        return Array((appeared + disappeared + recentActivity).prefix(NetworkSamplingLimits.maxActivityEvents))
    }
}
