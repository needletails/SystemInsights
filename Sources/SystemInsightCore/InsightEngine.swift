import Foundation

public struct InsightScorer: Sendable {
    public init() {}

    public func issues(for metrics: PerformanceMetrics, findings: [SecurityFinding]) -> [InsightIssue] {
        var issues: [InsightIssue] = []

        if metrics.cpuLoadPercent >= 90 {
            issues.append(performanceIssue(
                id: "cpu.critical",
                title: "CPU load is critical",
                detail: "CPU load is at \(Int(metrics.cpuLoadPercent))%.",
                severity: .critical,
                recommendation: recommendationForBusyProcess(metrics)
            ))
        } else if metrics.cpuLoadPercent >= 75 {
            issues.append(performanceIssue(
                id: "cpu.warning",
                title: "CPU load is elevated",
                detail: "CPU load is at \(Int(metrics.cpuLoadPercent))%.",
                severity: .warning,
                recommendation: recommendationForBusyProcess(metrics)
            ))
        }

        if metrics.memoryPressurePercent >= 90 {
            issues.append(performanceIssue(
                id: "memory.critical",
                title: "Memory pressure is critical",
                detail: "Memory pressure is at \(Int(metrics.memoryPressurePercent))%.",
                severity: .critical,
                recommendation: "Close memory-intensive applications."
            ))
        } else if metrics.memoryPressurePercent >= 75 {
            issues.append(performanceIssue(
                id: "memory.warning",
                title: "Memory pressure is elevated",
                detail: "Memory pressure is at \(Int(metrics.memoryPressurePercent))%.",
                severity: .warning,
                recommendation: "Close memory-intensive applications."
            ))
        }

        if metrics.diskUsagePercent >= 95 {
            issues.append(performanceIssue(
                id: "disk.critical",
                title: "Disk space is critically low",
                detail: "Disk usage is at \(Int(metrics.diskUsagePercent))%.",
                severity: .critical,
                recommendation: "Free disk space to avoid service disruption."
            ))
        } else if metrics.diskUsagePercent >= 85 {
            issues.append(performanceIssue(
                id: "disk.warning",
                title: "Disk space is low",
                detail: "Disk usage is at \(Int(metrics.diskUsagePercent))%.",
                severity: .warning,
                recommendation: "Remove unneeded files to free disk space."
            ))
        }

        issues.append(contentsOf: findings.map {
            InsightIssue(
                id: $0.id,
                category: .security,
                title: $0.title,
                detail: $0.detail,
                severity: $0.severity,
                recommendation: $0.recommendation
            )
        })
        return issues.sorted { left, right in
            if left.severity.priority == right.severity.priority {
                return left.title < right.title
            }
            return left.severity.priority > right.severity.priority
        }
    }

    public func score(for issues: [InsightIssue]) -> Int {
        let deductions = issues.reduce(0) { total, issue in
            switch issue.severity {
            case .critical: return total + 20
            case .warning: return total + 10
            case .informational: return total
            }
        }
        return max(0, 100 - deductions)
    }

    public func rating(for score: Int, issues: [InsightIssue] = []) -> HealthRating {
        if issues.contains(where: { $0.severity == .critical }) {
            return .critical
        }
        if issues.contains(where: { $0.severity == .warning }) {
            return .warning
        }

        switch score {
        case 80...100: return .good
        case 50..<80: return .warning
        default: return .critical
        }
    }

    private func performanceIssue(
        id: String,
        title: String,
        detail: String,
        severity: InsightSeverity,
        recommendation: String
    ) -> InsightIssue {
        InsightIssue(
            id: id,
            category: .performance,
            title: title,
            detail: detail,
            severity: severity,
            recommendation: recommendation
        )
    }

    private func recommendationForBusyProcess(_ metrics: PerformanceMetrics) -> String {
        if let process = metrics.topProcesses.first {
            return "Close \(process.name) if it is no longer needed."
        }
        return "Close unneeded applications."
    }
}

public struct InsightEngine: Sendable {
    private let metricCollector: any MetricCollecting
    private let securityChecker: any SecurityChecking
    private let scorer: InsightScorer

    public init(
        metricCollector: any MetricCollecting = SystemMetricCollector(),
        securityChecker: any SecurityChecking = SystemSecurityChecker(),
        scorer: InsightScorer = InsightScorer()
    ) {
        self.metricCollector = metricCollector
        self.securityChecker = securityChecker
        self.scorer = scorer
    }

    public func snapshot(at date: Date = Date(), host: HostIdentity? = nil) async throws -> InsightSnapshot {
        let resolvedHost = host ?? .current()
        let metrics = try await metricCollector.collect()
        async let findingsResult = securityChecker.check(metrics: metrics)
        async let eventsResult = securityChecker.recentEvents()
        let (findings, events) = await (findingsResult, eventsResult)
        let issues = scorer.issues(for: metrics, findings: findings)
        let score = scorer.score(for: issues)
        let recommendations = Array(NSOrderedSet(
            array: issues.compactMap(\.recommendation)
        )) as? [String] ?? []

        let snapshot = InsightSnapshot(
            generatedAt: date,
            host: resolvedHost,
            metrics: metrics,
            securityFindings: findings,
            securityEvents: events,
            issues: issues,
            score: score,
            rating: scorer.rating(for: score, issues: issues),
            recommendations: recommendations,
            topIssue: issues.first
        )
        try SnapshotValidator.validate(snapshot)
        return snapshot
    }

    public static func mock() -> InsightEngine {
        InsightEngine(metricCollector: MockMetricCollector(), securityChecker: MockSecurityChecker())
    }
}
