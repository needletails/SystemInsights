import Foundation

public enum CollectionPreferences: Sendable {
    /// When `SYSTEM_INSIGHTS_DISABLE_LATENCY_PROBE` is `1` or `true`, skip outbound latency probes.
    public static var isInternetLatencyProbeEnabled: Bool {
        let value = ProcessInfo.processInfo.environment["SYSTEM_INSIGHTS_DISABLE_LATENCY_PROBE"] ?? ""
        switch value.lowercased() {
        case "1", "true", "yes":
            return false
        default:
            return true
        }
    }
}
