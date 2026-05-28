import Foundation

public enum SnapshotValidationError: Error, Equatable, Sendable {
    case payloadTooLarge(maxBytes: Int)
    case unsupportedSchemaVersion(Int)
    case tooManyNetworkActivityEvents(max: Int)
    case tooManySecurityFindings(max: Int)
    case tooManySecurityEvents(max: Int)
    case tooManyIssues(max: Int)
    case tooManyRecommendations(max: Int)
    case tooManyProcesses(max: Int)
    case stringTooLong(field: String, maxLength: Int)
    case valueOutOfRange(field: String)
}

public enum SnapshotValidationLimits: Sendable {
    public static let maxEncodedBytes = 512 * 1024
    public static let maxNetworkActivityEvents = 32
    public static let maxSecurityFindings = 64
    public static let maxSecurityEvents = 24
    public static let maxIssues = 64
    public static let maxTopProcesses = 8
    public static let maxRecommendations = 32
    public static let maxFieldLength = 2_048
    public static let maxShortFieldLength = 512
    public static let supportedSchemaVersions = 1...InsightSnapshot.currentSchemaVersion
}

public enum SnapshotValidator: Sendable {
    public static func validateEncodedData(_ data: Data) throws {
        guard data.count <= SnapshotValidationLimits.maxEncodedBytes else {
            throw SnapshotValidationError.payloadTooLarge(maxBytes: SnapshotValidationLimits.maxEncodedBytes)
        }
    }

    public static func validate(_ snapshot: InsightSnapshot) throws {
        guard SnapshotValidationLimits.supportedSchemaVersions.contains(snapshot.schemaVersion) else {
            throw SnapshotValidationError.unsupportedSchemaVersion(snapshot.schemaVersion)
        }

        try validateHost(snapshot.host)
        try validateMetrics(snapshot.metrics)

        guard snapshot.networkActivity.count <= SnapshotValidationLimits.maxNetworkActivityEvents else {
            throw SnapshotValidationError.tooManyNetworkActivityEvents(
                max: SnapshotValidationLimits.maxNetworkActivityEvents
            )
        }
        for event in snapshot.networkActivity {
            try validateNetworkActivity(event)
        }

        guard snapshot.securityFindings.count <= SnapshotValidationLimits.maxSecurityFindings else {
            throw SnapshotValidationError.tooManySecurityFindings(
                max: SnapshotValidationLimits.maxSecurityFindings
            )
        }
        for finding in snapshot.securityFindings {
            try validateSecurityFinding(finding)
        }

        guard snapshot.securityEvents.count <= SnapshotValidationLimits.maxSecurityEvents else {
            throw SnapshotValidationError.tooManySecurityEvents(
                max: SnapshotValidationLimits.maxSecurityEvents
            )
        }
        for event in snapshot.securityEvents {
            try validateSecurityEvent(event)
        }

        guard snapshot.issues.count <= SnapshotValidationLimits.maxIssues else {
            throw SnapshotValidationError.tooManyIssues(max: SnapshotValidationLimits.maxIssues)
        }
        for issue in snapshot.issues {
            try validateIssue(issue)
        }

        guard snapshot.recommendations.count <= SnapshotValidationLimits.maxRecommendations else {
            throw SnapshotValidationError.tooManyRecommendations(
                max: SnapshotValidationLimits.maxRecommendations
            )
        }
        for recommendation in snapshot.recommendations {
            try validateLength(recommendation, field: "recommendation", max: SnapshotValidationLimits.maxFieldLength)
        }

        if let topIssue = snapshot.topIssue {
            try validateIssue(topIssue)
        }

        guard (0...100).contains(snapshot.score) else {
            throw SnapshotValidationError.valueOutOfRange(field: "score")
        }
    }

    private static func validateHost(_ host: HostIdentity) throws {
        try validateLength(host.hostName, field: "hostName", max: SnapshotValidationLimits.maxShortFieldLength)
        try validateLength(host.platform, field: "platform", max: SnapshotValidationLimits.maxShortFieldLength)
        try validateLength(host.operatingSystem, field: "operatingSystem", max: SnapshotValidationLimits.maxFieldLength)
    }

    private static func validateMetrics(_ metrics: PerformanceMetrics) throws {
        guard metrics.topProcesses.count <= SnapshotValidationLimits.maxTopProcesses else {
            throw SnapshotValidationError.tooManyProcesses(max: SnapshotValidationLimits.maxTopProcesses)
        }
        for process in metrics.topProcesses {
            try validateLength(process.name, field: "processName", max: SnapshotValidationLimits.maxShortFieldLength)
        }
        try validateLength(
            metrics.network.vpn.detail,
            field: "vpn.detail",
            max: SnapshotValidationLimits.maxFieldLength
        )
        if let serviceName = metrics.network.vpn.serviceName {
            try validateLength(serviceName, field: "vpn.serviceName", max: SnapshotValidationLimits.maxShortFieldLength)
        }
    }

    private static func validateNetworkActivity(_ event: NetworkActivityEvent) throws {
        try validateLength(event.processName, field: "networkActivity.processName", max: SnapshotValidationLimits.maxShortFieldLength)
        try validateLength(event.localEndpoint, field: "networkActivity.localEndpoint", max: SnapshotValidationLimits.maxShortFieldLength)
        if let remoteEndpoint = event.remoteEndpoint {
            try validateLength(remoteEndpoint, field: "networkActivity.remoteEndpoint", max: SnapshotValidationLimits.maxShortFieldLength)
        }
    }

    private static func validateSecurityFinding(_ finding: SecurityFinding) throws {
        try validateLength(finding.id, field: "securityFinding.id", max: SnapshotValidationLimits.maxShortFieldLength)
        try validateLength(finding.title, field: "securityFinding.title", max: SnapshotValidationLimits.maxFieldLength)
        try validateLength(finding.detail, field: "securityFinding.detail", max: SnapshotValidationLimits.maxFieldLength)
        if let recommendation = finding.recommendation {
            try validateLength(recommendation, field: "securityFinding.recommendation", max: SnapshotValidationLimits.maxFieldLength)
        }
    }

    private static func validateSecurityEvent(_ event: SecurityEvent) throws {
        try validateLength(event.id, field: "securityEvent.id", max: SnapshotValidationLimits.maxShortFieldLength)
        try validateLength(event.source, field: "securityEvent.source", max: SnapshotValidationLimits.maxShortFieldLength)
        try validateLength(event.message, field: "securityEvent.message", max: SnapshotValidationLimits.maxFieldLength)
        if let timestamp = event.timestamp {
            try validateLength(timestamp, field: "securityEvent.timestamp", max: SnapshotValidationLimits.maxShortFieldLength)
        }
    }

    private static func validateIssue(_ issue: InsightIssue) throws {
        try validateLength(issue.id, field: "issue.id", max: SnapshotValidationLimits.maxShortFieldLength)
        try validateLength(issue.title, field: "issue.title", max: SnapshotValidationLimits.maxFieldLength)
        try validateLength(issue.detail, field: "issue.detail", max: SnapshotValidationLimits.maxFieldLength)
        if let recommendation = issue.recommendation {
            try validateLength(recommendation, field: "issue.recommendation", max: SnapshotValidationLimits.maxFieldLength)
        }
    }

    private static func validateLength(_ value: String, field: String, max: Int) throws {
        guard value.count <= max else {
            throw SnapshotValidationError.stringTooLong(field: field, maxLength: max)
        }
    }
}

extension SnapshotValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .payloadTooLarge(let maxBytes):
            "Snapshot payload exceeds \(maxBytes) bytes."
        case .unsupportedSchemaVersion(let version):
            "Unsupported snapshot schema version \(version)."
        case .tooManyNetworkActivityEvents(let max):
            "Too many network activity events (max \(max))."
        case .tooManySecurityFindings(let max):
            "Too many security findings (max \(max))."
        case .tooManySecurityEvents(let max):
            "Too many security events (max \(max))."
        case .tooManyIssues(let max):
            "Too many issues (max \(max))."
        case .tooManyRecommendations(let max):
            "Too many recommendations (max \(max))."
        case .tooManyProcesses(let max):
            "Too many top processes (max \(max))."
        case .stringTooLong(let field, let maxLength):
            "Field \(field) exceeds \(maxLength) characters."
        case .valueOutOfRange(let field):
            "Field \(field) is out of range."
        }
    }
}

extension InsightSnapshot {
    /// Trims list fields to cache/schema limits before validation and encryption.
    public func clampedForPersistence() -> InsightSnapshot {
        InsightSnapshot(
            schemaVersion: schemaVersion,
            generatedAt: generatedAt,
            host: host,
            metrics: PerformanceMetrics(
                cpuLoadPercent: metrics.cpuLoadPercent,
                memoryPressurePercent: metrics.memoryPressurePercent,
                diskUsagePercent: metrics.diskUsagePercent,
                network: metrics.network,
                topProcesses: Array(metrics.topProcesses.prefix(SnapshotValidationLimits.maxTopProcesses))
            ),
            networkActivity: Array(
                networkActivity.prefix(SnapshotValidationLimits.maxNetworkActivityEvents)
            ),
            securityFindings: Array(
                securityFindings.prefix(SnapshotValidationLimits.maxSecurityFindings)
            ),
            securityEvents: Array(
                securityEvents.prefix(SnapshotValidationLimits.maxSecurityEvents)
            ),
            issues: Array(issues.prefix(SnapshotValidationLimits.maxIssues)),
            score: score,
            rating: rating,
            recommendations: Array(
                recommendations.prefix(SnapshotValidationLimits.maxRecommendations)
            ),
            topIssue: topIssue
        )
    }
}
