import Foundation

/// Preformatted strings for the optional GNOME Shell panel indicator (`system-insights panel`).
public struct PanelPresentation: Codable, Sendable, Equatable {
    public let indicatorLabel: String
    public let ratingStyle: String
    public let statusLine: String
    public let metricsLine: String
    public let networkLine: String
    public let vpnLine: String
    public let issueLine: String
    public let activityLine: String
    public let protocolNoticeLine: String
    public let eventLine: String

    public static let protocolNotice =
        "Service labels use PORT MAP or HEURISTIC confidence — not packet inspection"

    public static func make(from snapshot: InsightSnapshot) -> PanelPresentation {
        let metrics = snapshot.metrics
        let network = metrics.network
        let vpn = network.vpn
        let activity = snapshot.networkActivity.first
        let issue = snapshot.topIssue?.title ?? "No action needed"
        let event = snapshot.securityEvents.first?.message ?? "No recent security activity reported"

        return PanelPresentation(
            indicatorLabel: "\(snapshot.score)  ↓\(shortRate(network.receivedBytesPerSecond)) ↑\(shortRate(network.sentBytesPerSecond)) \(shortLatency(network.latencyMilliseconds))",
            ratingStyle: snapshot.rating.rawValue.lowercased(),
            statusLine: "Health: \(snapshot.score)/100 (\(snapshot.rating.rawValue))",
            metricsLine: "CPU \(Int(metrics.cpuLoadPercent.rounded()))%  Memory \(Int(metrics.memoryPressurePercent.rounded()))%  Disk \(Int(metrics.diskUsagePercent.rounded()))%",
            networkLine: "Latest speed (\(network.interfaceName ?? "--")): Down \(rate(network.receivedBytesPerSecond))  Up \(rate(network.sentBytesPerSecond))  Latency \(latency(network.latencyMilliseconds))  TCP \(network.activeTCPConnections)",
            vpnLine: "VPN: \(vpn.state.rawValue)",
            issueLine: "Top issue: \(issue)",
            activityLine: activityLine(for: activity),
            protocolNoticeLine: protocolNotice,
            eventLine: "Security: \(event)"
        )
    }

    public static func locked() -> PanelPresentation {
        PanelPresentation(
            indicatorLabel: "Speed --",
            ratingStyle: "unknown",
            statusLine: "Cache locked — open System Insights and enter your password",
            metricsLine: "",
            networkLine: "",
            vpnLine: "",
            issueLine: "",
            activityLine: "",
            protocolNoticeLine: "",
            eventLine: ""
        )
    }

    public static func unavailable() -> PanelPresentation {
        PanelPresentation(
            indicatorLabel: "Speed --",
            ratingStyle: "unknown",
            statusLine: "Unable to read encrypted snapshot",
            metricsLine: "",
            networkLine: "",
            vpnLine: "",
            issueLine: "",
            activityLine: "",
            protocolNoticeLine: "",
            eventLine: ""
        )
    }

    private static func activityLine(for activity: NetworkActivityEvent?) -> String {
        guard let activity else {
            return "Socket: No visible connection activity"
        }
        let hint = activity.serviceHint.label
        let endpoint = activity.remoteEndpoint ?? activity.localEndpoint
        let process = processName(activity.processName)
        return "Socket: \(activity.action.rawValue) \(activity.transport.rawValue) \(hint) \(process) \(endpoint)"
    }

    private static func processName(_ path: String) -> String {
        let name = URL(fileURLWithPath: path).lastPathComponent
        return name.isEmpty ? path : name
    }

    private static func rate(_ bytesPerSecond: Double) -> String {
        let bytes = max(0, bytesPerSecond)
        if bytes >= 1_000_000 {
            return String(format: "%.1f MB/s", bytes / 1_000_000)
        }
        return "\(Int((bytes / 1000).rounded())) KB/s"
    }

    private static func shortRate(_ bytesPerSecond: Double) -> String {
        let bytes = max(0, bytesPerSecond)
        if bytes >= 1_000_000 {
            return String(format: "%.1fM", bytes / 1_000_000)
        }
        return "\(Int((bytes / 1000).rounded()))K"
    }

    private static func latency(_ milliseconds: Double?) -> String {
        guard let milliseconds, milliseconds.isFinite else { return "—" }
        return "\(Int(milliseconds.rounded())) ms"
    }

    private static func shortLatency(_ milliseconds: Double?) -> String {
        guard let milliseconds, milliseconds.isFinite else { return "--ms" }
        return "\(Int(milliseconds.rounded()))ms"
    }
}
