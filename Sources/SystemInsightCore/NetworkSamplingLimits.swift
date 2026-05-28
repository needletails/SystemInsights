import Foundation

/// Upper bounds for live monitoring buffers and subprocess parsing.
public enum NetworkSamplingLimits: Sendable {
    public static let maxVisibleSockets = 256
    /// Must match ``SnapshotValidationLimits/maxNetworkActivityEvents`` (snapshots reject >32).
    public static let maxActivityEvents = SnapshotValidationLimits.maxNetworkActivityEvents
    public static let maxLiveNetworkSamples = 24
    public static let maxConsoleSocketRows = 80
    public static let maxConsoleActivityRows = 40
}
