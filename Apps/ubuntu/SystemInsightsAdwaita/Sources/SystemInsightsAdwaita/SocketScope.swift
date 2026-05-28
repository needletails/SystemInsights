import Adwaita
import SystemInsightCore

enum SocketScope: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case tcp = "TCP"
    case udp = "UDP"
    case listening = "Listen"

    var id: String { rawValue }

    func includes(_ connection: VisibleSocket) -> Bool {
        switch self {
        case .all: true
        case .tcp: connection.transport == .tcp
        case .udp: connection.transport == .udp
        case .listening: connection.state == .listening
        }
    }
}

extension SocketScope: ToggleGroupItem {
    var icon: Icon? { nil }
    var showLabel: Bool { true }
}

enum NetworkRecordSelection: Identifiable, Sendable {
    case socket(VisibleSocket)
    case event(NetworkActivityEvent)

    var id: String {
        switch self {
        case .socket(let socket): "socket|\(socket.id)"
        case .event(let event): "event|\(event.id)"
        }
    }
}
