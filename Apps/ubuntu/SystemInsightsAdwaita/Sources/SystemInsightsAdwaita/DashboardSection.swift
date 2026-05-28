import Adwaita

enum DashboardSection: String, CaseIterable, Identifiable, Sendable {
    case overview
    case network
    case processes
    case security

    var id: String { rawValue }

    var label: String {
        switch self {
        case .overview: "Overview"
        case .network: "Network"
        case .processes: "Processes"
        case .security: "Security"
        }
    }

    var icon: Icon {
        switch self {
        case .overview:
            return .default(icon: .applicationsSystem)
        case .network:
            return .default(icon: .networkTransmitReceive)
        case .processes:
            return .default(icon: .systemRun)
        case .security:
            return .default(icon: .securityHigh)
        }
    }
}
