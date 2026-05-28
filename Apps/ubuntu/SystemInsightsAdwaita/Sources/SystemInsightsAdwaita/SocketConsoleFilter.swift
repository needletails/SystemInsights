import Foundation
import SystemInsightCore

/// Fast socket table filtering with service hints computed once per refresh.
enum SocketConsoleFilter {
    struct IndexEntry: Sendable, Identifiable {
        let socket: VisibleSocket
        let serviceLabel: String
        let haystack: String

        var id: String { socket.id }
    }

    static func buildIndex(connections: [VisibleSocket]) -> [IndexEntry] {
        connections.map { socket in
            let label = socket.serviceHint.label
            return IndexEntry(
                socket: socket,
                serviceLabel: label,
                haystack: normalizedHaystack(for: socket, serviceLabel: label)
            )
        }
    }

    static func apply(
        index: [IndexEntry],
        scope: SocketScope,
        query: String
    ) -> [IndexEntry] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return index.filter { entry in
            guard scope.includes(entry.socket) else { return false }
            guard needle.isEmpty || entry.haystack.contains(needle) else { return false }
            return true
        }
    }

    private static func normalizedHaystack(for socket: VisibleSocket, serviceLabel: String) -> String {
        let remote = socket.remoteEndpoint ?? ""
        return [
            socket.processName,
            String(socket.pid),
            socket.localEndpoint,
            remote,
            serviceLabel
        ]
        .joined(separator: " ")
        .lowercased()
    }
}
