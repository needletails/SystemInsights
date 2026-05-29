import Foundation

#if os(Linux)
/// Testable helpers that document and verify Flatpak network counter behavior.
enum LinuxNetworkProof {
    /// Byte totals from ``/proc/net/dev`` — host interfaces accumulate gigabytes; sandbox namespaces stay tiny.
    static func counterScale(receivedByteTotal: Double) -> CounterScale {
        if receivedByteTotal >= 100_000_000 { return .host }
        if receivedByteTotal <= 10_000_000 { return .sandbox }
        return .ambiguous
    }

    static func projectedRate(previous: Double, current: Double, intervalSeconds: Double) -> Double {
        guard intervalSeconds > 0, current >= previous else { return 0 }
        return ((current - previous) / intervalSeconds).rounded()
    }

    enum CounterScale: String, Sendable {
        case host
        case sandbox
        case ambiguous
    }
}
#endif
