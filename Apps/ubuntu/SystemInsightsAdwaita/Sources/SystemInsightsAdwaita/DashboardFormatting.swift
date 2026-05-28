import Foundation
import SystemInsightCore

enum DashboardFormatting {
    static func relativeTime(since date: Date, now: Date = Date()) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60) min ago" }
        if seconds < 86_400 { return "\(seconds / 3600) hr ago" }
        return ISO8601DateFormatter().string(from: date)
    }

    static func shortTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    static func rate(_ bytesPerSecond: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .decimal
        return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
    }

    static func latency(_ milliseconds: Double?) -> String {
        guard let milliseconds else { return "—" }
        return "\(Int(milliseconds.rounded())) ms"
    }

    static func percent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    static func processName(_ path: String) -> String {
        let name = URL(fileURLWithPath: path).lastPathComponent
        return name.isEmpty ? path : name
    }

    static func ratingLabel(_ rating: HealthRating) -> String {
        switch rating {
        case .good: "Good"
        case .warning: "Needs attention"
        case .critical: "Critical"
        }
    }

    static func endpoint(_ event: NetworkActivityEvent) -> String {
        if let remote = event.remoteEndpoint {
            return "\(event.localEndpoint) → \(remote)"
        }
        return event.localEndpoint
    }

    static func endpoint(_ socket: VisibleSocket) -> String {
        if let remote = socket.remoteEndpoint {
            return "\(socket.localEndpoint) → \(remote)"
        }
        return socket.localEndpoint
    }

    static func establishedCount(_ sockets: [VisibleSocket]) -> Int {
        sockets.filter { $0.state == .established }.count
    }

    static func listenerCount(_ sockets: [VisibleSocket]) -> Int {
        sockets.filter { $0.state == .listening }.count
    }

    static func udpCount(_ sockets: [VisibleSocket]) -> Int {
        sockets.filter { $0.transport == .udp }.count
    }

    static func isExposedEndpoint(_ endpoint: String) -> Bool {
        endpoint.hasPrefix("*:")
            || endpoint.hasPrefix("0.0.0.0:")
            || endpoint.hasPrefix("[::]:")
            || endpoint.hasPrefix("[*]:")
    }

    static func exposedCount(_ sockets: [VisibleSocket]) -> Int {
        sockets.filter { isExposedEndpoint($0.localEndpoint) }.count
    }

    static func networkActors(_ sockets: [VisibleSocket]) -> [NetworkActorSummary] {
        let grouped = Dictionary(grouping: sockets.filter { $0.remoteEndpoint != nil }) {
            "\($0.pid)|\($0.processName)"
        }
        return grouped.map { _, actorSockets in
            NetworkActorSummary(
                processName: actorSockets[0].processName,
                pid: actorSockets[0].pid,
                tcpCount: actorSockets.filter { $0.transport == .tcp }.count,
                udpCount: actorSockets.filter { $0.transport == .udp }.count,
                peerCount: Set(actorSockets.compactMap(\.remoteEndpoint)).count
            )
        }
        .sorted {
            if $0.peerCount != $1.peerCount { return $0.peerCount > $1.peerCount }
            return $0.processName < $1.processName
        }
    }

    static func pollText(_ timestamp: Date?) -> String {
        guard let timestamp else { return "Waiting for first sample…" }
        return "Last sample \(shortTime(timestamp))"
    }

    static func averageReceived(_ samples: [NetworkMetrics]) -> Double {
        guard !samples.isEmpty else { return 0 }
        return samples.map(\.receivedBytesPerSecond).reduce(0, +) / Double(samples.count)
    }

    static func averageSent(_ samples: [NetworkMetrics]) -> Double {
        guard !samples.isEmpty else { return 0 }
        return samples.map(\.sentBytesPerSecond).reduce(0, +) / Double(samples.count)
    }

    static func peakReceived(_ samples: [NetworkMetrics]) -> Double {
        samples.map(\.receivedBytesPerSecond).max() ?? 0
    }

    static func peakSent(_ samples: [NetworkMetrics]) -> Double {
        samples.map(\.sentBytesPerSecond).max() ?? 0
    }

    static func serviceLabel(_ hint: SocketServiceHint) -> String {
        hint.label
    }

    static func serviceDetail(_ hint: SocketServiceHint) -> String {
        "\(hint.label) · \(hint.confidence.rawValue) · \(hint.basis)"
    }
}

struct NetworkActorSummary: Identifiable, Sendable {
    let processName: String
    let pid: Int
    let tcpCount: Int
    let udpCount: Int
    let peerCount: Int

    var id: String { "\(pid)|\(processName)" }
}
