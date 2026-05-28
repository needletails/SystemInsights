import Foundation

/// Cheap change detection for live socket polling.
public enum VisibleSocketSampling {
    public static func fingerprint(_ connections: [VisibleSocket]) -> UInt64 {
        var hasher = Hasher()
        hasher.combine(connections.count)
        for socket in connections {
            hasher.combine(socket.id)
        }
        return UInt64(bitPattern: Int64(hasher.finalize()))
    }
}
