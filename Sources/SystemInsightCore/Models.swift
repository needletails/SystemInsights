import Foundation

public enum InsightSeverity: String, Codable, Sendable, CaseIterable {
    case informational
    case warning
    case critical

    var priority: Int {
        switch self {
        case .informational: return 0
        case .warning: return 1
        case .critical: return 2
        }
    }
}

public enum HealthRating: String, Codable, Sendable {
    case good = "Good"
    case warning = "Warning"
    case critical = "Critical"
}

public enum InsightCategory: String, Codable, Sendable {
    case performance
    case security
}

public struct ProcessMetric: Codable, Sendable, Equatable, Identifiable {
    public let pid: Int
    public let name: String
    public let cpuPercent: Double
    public let memoryPercent: Double

    public var id: Int { pid }

    public init(pid: Int, name: String, cpuPercent: Double, memoryPercent: Double) {
        self.pid = pid
        self.name = name
        self.cpuPercent = cpuPercent
        self.memoryPercent = memoryPercent
    }
}

public enum VPNConnectionState: String, Codable, Sendable {
    case connected = "Connected"
    case tunnelDetected = "Tunnel Detected"
    case notDetected = "Not Detected"
    case unavailable = "Unavailable"
}

public struct VPNConnectivity: Codable, Sendable, Equatable {
    public let state: VPNConnectionState
    public let serviceName: String?
    public let activeInterfaces: [String]
    public let detail: String

    public init(
        state: VPNConnectionState,
        serviceName: String? = nil,
        activeInterfaces: [String] = [],
        detail: String
    ) {
        self.state = state
        self.serviceName = serviceName
        self.activeInterfaces = activeInterfaces
        self.detail = detail
    }

    public static let unavailable = VPNConnectivity(
        state: .unavailable,
        detail: "VPN state was not available during this collection."
    )
}

public struct LiveNetworkSampleInputs: Sendable {
    public let preserving: NetworkMetrics
    public let establishedTCPCount: Int?
    public let refreshVPN: Bool

    public init(
        preserving: NetworkMetrics,
        establishedTCPCount: Int? = nil,
        refreshVPN: Bool = false
    ) {
        self.preserving = preserving
        self.establishedTCPCount = establishedTCPCount
        self.refreshVPN = refreshVPN
    }
}

public struct NetworkMetrics: Codable, Sendable, Equatable {
    public let interfaceName: String?
    public let receivedBytesPerSecond: Double
    public let sentBytesPerSecond: Double
    public let latencyMilliseconds: Double?
    public let activeTCPConnections: Int
    public let vpn: VPNConnectivity

    public init(
        interfaceName: String?,
        receivedBytesPerSecond: Double,
        sentBytesPerSecond: Double,
        latencyMilliseconds: Double? = nil,
        activeTCPConnections: Int,
        vpn: VPNConnectivity
    ) {
        self.interfaceName = interfaceName
        self.receivedBytesPerSecond = receivedBytesPerSecond
        self.sentBytesPerSecond = sentBytesPerSecond
        self.latencyMilliseconds = latencyMilliseconds
        self.activeTCPConnections = activeTCPConnections
        self.vpn = vpn
    }

    public static let unavailable = NetworkMetrics(
        interfaceName: nil,
        receivedBytesPerSecond: 0,
        sentBytesPerSecond: 0,
        latencyMilliseconds: nil,
        activeTCPConnections: 0,
        vpn: .unavailable
    )
}

public enum NetworkTransport: String, Codable, Sendable, Equatable {
    case tcp = "TCP"
    case udp = "UDP"
}

public enum VisibleSocketState: String, Sendable {
    case established = "ESTABLISHED"
    case listening = "LISTEN"
    case datagram = "DGRAM"
}

public struct VisibleSocket: Sendable, Equatable, Identifiable {
    public let transport: NetworkTransport
    public let processName: String
    public let pid: Int
    public let localEndpoint: String
    public let remoteEndpoint: String?
    public let state: VisibleSocketState

    public var id: String {
        "\(transport.rawValue)|\(pid)|\(state.rawValue)|\(localEndpoint)|\(remoteEndpoint ?? "")"
    }

    public init(
        transport: NetworkTransport = .tcp,
        processName: String,
        pid: Int,
        localEndpoint: String,
        remoteEndpoint: String? = nil,
        state: VisibleSocketState
    ) {
        self.transport = transport
        self.processName = processName
        self.pid = pid
        self.localEndpoint = localEndpoint
        self.remoteEndpoint = remoteEndpoint
        self.state = state
    }
}

public enum NetworkActivityAction: String, Codable, Sendable {
    case observed = "SEEN"
    case opened = "OPEN"
    case closed = "CLOSE"
    case listening = "LISTEN"
    case stoppedListening = "UNLIST"
}

public struct NetworkActivityEvent: Codable, Sendable, Equatable, Identifiable {
    public let timestamp: Date
    public let action: NetworkActivityAction
    public let transport: NetworkTransport
    public let processName: String
    public let pid: Int
    public let localEndpoint: String
    public let remoteEndpoint: String?

    public var id: String {
        "\(timestamp.timeIntervalSinceReferenceDate)|\(action.rawValue)|\(transport.rawValue)|\(pid)|\(localEndpoint)|\(remoteEndpoint ?? "")"
    }

    public init(timestamp: Date, action: NetworkActivityAction, connection: VisibleSocket) {
        self.timestamp = timestamp
        self.action = action
        transport = connection.transport
        processName = connection.processName
        pid = connection.pid
        localEndpoint = connection.localEndpoint
        remoteEndpoint = connection.remoteEndpoint
    }

    private enum CodingKeys: String, CodingKey {
        case timestamp
        case action
        case transport
        case processName
        case pid
        case localEndpoint
        case remoteEndpoint
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        action = try container.decode(NetworkActivityAction.self, forKey: .action)
        transport = try container.decodeIfPresent(NetworkTransport.self, forKey: .transport) ?? .tcp
        processName = try container.decode(String.self, forKey: .processName)
        pid = try container.decode(Int.self, forKey: .pid)
        localEndpoint = try container.decode(String.self, forKey: .localEndpoint)
        remoteEndpoint = try container.decodeIfPresent(String.self, forKey: .remoteEndpoint)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(action, forKey: .action)
        try container.encode(transport, forKey: .transport)
        try container.encode(processName, forKey: .processName)
        try container.encode(pid, forKey: .pid)
        try container.encode(localEndpoint, forKey: .localEndpoint)
        try container.encodeIfPresent(remoteEndpoint, forKey: .remoteEndpoint)
    }
}

public enum SocketServiceConfidence: String, Sendable, Equatable {
    case portMapped = "PORT MAP"
    case heuristic = "HEURISTIC"
    case unclassified = "UNCLASSIFIED"
}

public struct SocketServiceHint: Sendable, Equatable {
    public let label: String
    public let confidence: SocketServiceConfidence
    public let basis: String

    public init(label: String, confidence: SocketServiceConfidence, basis: String) {
        self.label = label
        self.confidence = confidence
        self.basis = basis
    }
}

public extension VisibleSocket {
    var serviceHint: SocketServiceHint {
        SocketServiceClassifier.hint(
            transport: transport,
            localEndpoint: localEndpoint,
            remoteEndpoint: remoteEndpoint,
            processName: processName
        )
    }
}

public extension NetworkActivityEvent {
    var serviceHint: SocketServiceHint {
        SocketServiceClassifier.hint(
            transport: transport,
            localEndpoint: localEndpoint,
            remoteEndpoint: remoteEndpoint,
            processName: processName
        )
    }
}

public struct PerformanceMetrics: Codable, Sendable, Equatable {
    public let cpuLoadPercent: Double
    public let memoryPressurePercent: Double
    public let diskUsagePercent: Double
    public let network: NetworkMetrics
    public let topProcesses: [ProcessMetric]

    public init(
        cpuLoadPercent: Double,
        memoryPressurePercent: Double,
        diskUsagePercent: Double,
        network: NetworkMetrics = .unavailable,
        topProcesses: [ProcessMetric]
    ) {
        self.cpuLoadPercent = cpuLoadPercent
        self.memoryPressurePercent = memoryPressurePercent
        self.diskUsagePercent = diskUsagePercent
        self.network = network
        self.topProcesses = topProcesses
    }

    private enum CodingKeys: String, CodingKey {
        case cpuLoadPercent
        case memoryPressurePercent
        case diskUsagePercent
        case network
        case topProcesses
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cpuLoadPercent = try container.decode(Double.self, forKey: .cpuLoadPercent)
        memoryPressurePercent = try container.decode(Double.self, forKey: .memoryPressurePercent)
        diskUsagePercent = try container.decode(Double.self, forKey: .diskUsagePercent)
        network = try container.decodeIfPresent(NetworkMetrics.self, forKey: .network) ?? .unavailable
        topProcesses = try container.decode([ProcessMetric].self, forKey: .topProcesses)
    }
}

public struct SecurityFinding: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let detail: String
    public let severity: InsightSeverity
    public let recommendation: String?

    public init(
        id: String,
        title: String,
        detail: String,
        severity: InsightSeverity,
        recommendation: String? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.severity = severity
        self.recommendation = recommendation
    }
}

public struct SecurityEvent: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let timestamp: String?
    public let source: String
    public let message: String
    public let severity: InsightSeverity

    public init(
        id: String,
        timestamp: String? = nil,
        source: String,
        message: String,
        severity: InsightSeverity
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.message = message
        self.severity = severity
    }
}

public struct InsightIssue: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let category: InsightCategory
    public let title: String
    public let detail: String
    public let severity: InsightSeverity
    public let recommendation: String?

    public init(
        id: String,
        category: InsightCategory,
        title: String,
        detail: String,
        severity: InsightSeverity,
        recommendation: String? = nil
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.detail = detail
        self.severity = severity
        self.recommendation = recommendation
    }
}

public struct HostIdentity: Codable, Sendable, Equatable {
    public let hostName: String
    public let platform: String
    public let operatingSystem: String

    public init(hostName: String, platform: String, operatingSystem: String) {
        self.hostName = hostName
        self.platform = platform
        self.operatingSystem = operatingSystem
    }

    public static func current() -> HostIdentity {
        #if os(macOS)
        let platform = "macOS"
        let machineName = CommandRunner.run("/usr/sbin/scutil", arguments: ["--get", "ComputerName"])?
            .stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        #elseif os(Linux)
        let platform = "Ubuntu/Linux"
        let machineName: String? = nil
        #else
        let platform = "Unknown"
        let machineName: String? = nil
        #endif

        let displayName = machineName.flatMap { $0.isEmpty ? nil : $0 } ?? ProcessInfo.processInfo.hostName
        return HostIdentity(
            hostName: displayName,
            platform: platform,
            operatingSystem: ProcessInfo.processInfo.operatingSystemVersionString
        )
    }
}

public struct InsightSnapshot: Codable, Sendable, Equatable {
    public static let currentSchemaVersion = 3

    public let schemaVersion: Int
    public let generatedAt: Date
    public let host: HostIdentity
    public let metrics: PerformanceMetrics
    public let networkActivity: [NetworkActivityEvent]
    public let securityFindings: [SecurityFinding]
    public let securityEvents: [SecurityEvent]
    public let issues: [InsightIssue]
    public let score: Int
    public let rating: HealthRating
    public let recommendations: [String]
    public let topIssue: InsightIssue?

    public init(
        schemaVersion: Int = InsightSnapshot.currentSchemaVersion,
        generatedAt: Date,
        host: HostIdentity,
        metrics: PerformanceMetrics,
        networkActivity: [NetworkActivityEvent] = [],
        securityFindings: [SecurityFinding],
        securityEvents: [SecurityEvent] = [],
        issues: [InsightIssue],
        score: Int,
        rating: HealthRating,
        recommendations: [String],
        topIssue: InsightIssue?
    ) {
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.host = host
        self.metrics = metrics
        self.networkActivity = networkActivity
        self.securityFindings = securityFindings
        self.securityEvents = securityEvents
        self.issues = issues
        self.score = score
        self.rating = rating
        self.recommendations = recommendations
        self.topIssue = topIssue
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case generatedAt
        case host
        case metrics
        case networkActivity
        case securityFindings
        case securityEvents
        case issues
        case score
        case rating
        case recommendations
        case topIssue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        generatedAt = try container.decode(Date.self, forKey: .generatedAt)
        host = try container.decode(HostIdentity.self, forKey: .host)
        metrics = try container.decode(PerformanceMetrics.self, forKey: .metrics)
        networkActivity = try container.decodeIfPresent([NetworkActivityEvent].self, forKey: .networkActivity) ?? []
        securityFindings = try container.decode([SecurityFinding].self, forKey: .securityFindings)
        securityEvents = try container.decodeIfPresent([SecurityEvent].self, forKey: .securityEvents) ?? []
        issues = try container.decode([InsightIssue].self, forKey: .issues)
        score = try container.decode(Int.self, forKey: .score)
        rating = try container.decode(HealthRating.self, forKey: .rating)
        recommendations = try container.decode([String].self, forKey: .recommendations)
        topIssue = try container.decodeIfPresent(InsightIssue.self, forKey: .topIssue)
    }

    public func withNetworkActivity(_ networkActivity: [NetworkActivityEvent]) -> InsightSnapshot {
        InsightSnapshot(
            schemaVersion: schemaVersion,
            generatedAt: generatedAt,
            host: host,
            metrics: metrics,
            networkActivity: networkActivity,
            securityFindings: securityFindings,
            securityEvents: securityEvents,
            issues: issues,
            score: score,
            rating: rating,
            recommendations: recommendations,
            topIssue: topIssue
        )
    }
}
