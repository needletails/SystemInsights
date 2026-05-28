import Foundation

public protocol SecurityChecking: Sendable {
    func check(metrics: PerformanceMetrics) async -> [SecurityFinding]
    func recentEvents() async -> [SecurityEvent]
}

public extension SecurityChecking {
    func recentEvents() async -> [SecurityEvent] {
        []
    }
}

public struct SystemSecurityChecker: SecurityChecking {
    public init() {}

    public func check(metrics: PerformanceMetrics) async -> [SecurityFinding] {
        #if os(macOS)
        return macOSFindings(metrics: metrics)
        #elseif os(Linux)
        return linuxFindings(metrics: metrics)
        #else
        return []
        #endif
    }

    public func recentEvents() async -> [SecurityEvent] {
        #if os(macOS)
        return macOSSecurityEvents()
        #elseif os(Linux)
        return linuxSecurityEvents()
        #else
        return []
        #endif
    }

    #if os(macOS)
    private func macOSFindings(metrics: PerformanceMetrics) -> [SecurityFinding] {
        var findings: [SecurityFinding] = []

        if let output = CommandRunner.run(
            "/usr/libexec/ApplicationFirewall/socketfilterfw",
            arguments: ["--getglobalstate"]
        ), output.exitCode == 0,
           output.combinedText.lowercased().contains("disabled") {
            findings.append(SecurityFinding(
                id: "firewall.disabled",
                title: "macOS Application Firewall is off",
                detail: "The built-in macOS Application Firewall is off. VPN and third-party network filtering are separate and are not assessed by this check.",
                severity: .informational,
                recommendation: "Enable the built-in firewall in System Settings if you want macOS Application Firewall protection."
            ))
        }

        if let output = CommandRunner.run("/usr/bin/fdesetup", arguments: ["status"]),
           output.combinedText.lowercased().contains("off") {
            findings.append(SecurityFinding(
                id: "filevault.disabled",
                title: "FileVault is disabled",
                detail: "Your startup disk is not protected by FileVault encryption.",
                severity: .warning,
                recommendation: "Enable FileVault disk encryption."
            ))
        }

        if let output = CommandRunner.run("/usr/sbin/spctl", arguments: ["--status"]),
           output.combinedText.lowercased().contains("disabled") {
            findings.append(SecurityFinding(
                id: "gatekeeper.disabled",
                title: "Gatekeeper is disabled",
                detail: "Downloaded app verification has been disabled.",
                severity: .critical,
                recommendation: "Enable Gatekeeper app assessment."
            ))
        }

        if let output = CommandRunner.run("/usr/bin/csrutil", arguments: ["status"]),
           output.combinedText.lowercased().contains("disabled") {
            findings.append(SecurityFinding(
                id: "sip.disabled",
                title: "System Integrity Protection is disabled",
                detail: "macOS reports that System Integrity Protection is disabled.",
                severity: .critical,
                recommendation: "Re-enable System Integrity Protection unless it is intentionally disabled."
            ))
        }

        if let output = CommandRunner.run("/usr/sbin/softwareupdate", arguments: ["--list"], timeout: 8),
           !output.combinedText.lowercased().contains("no new software available"),
           output.combinedText.contains("*") {
            findings.append(SecurityFinding(
                id: "updates.pending",
                title: "Software updates are available",
                detail: "macOS reports one or more pending software updates.",
                severity: .warning,
                recommendation: "Install pending system updates."
            ))
        }

        for process in metrics.topProcesses where process.cpuPercent >= 50 {
            guard
                let executablePath = ExecutablePathResolver.path(forPID: process.pid),
                ExecutablePathResolver.isWritableLocation(executablePath)
            else {
                continue
            }
            let verification = CommandRunner.run(
                "/usr/bin/codesign",
                arguments: ["--verify", "--strict", executablePath]
            )
            if let verification, verification.exitCode != 0 {
                findings.append(SecurityFinding(
                    id: "unsigned-process.\(process.pid)",
                    title: "Review an unverified busy process",
                    detail: "\(process.name) (\(executablePath)) is executing from a writable location, using \(Int(process.cpuPercent))% CPU, and did not pass code-sign verification.",
                    severity: .warning,
                    recommendation: "Verify this executable is expected before allowing it to continue."
                ))
            }
        }

        return findings
    }

    private func macOSSecurityEvents() -> [SecurityEvent] {
        let predicate = """
        ((process == "authd" OR process == "sudo") AND (eventMessage CONTAINS[c] "deny" OR eventMessage CONTAINS[c] "fail" OR eventMessage CONTAINS[c] "authentication")) OR (process == "syspolicyd" AND (eventMessage CONTAINS[c] "assessment denied" OR eventMessage CONTAINS[c] "rejected"))
        """
        guard let output = CommandRunner.run(
            "/usr/bin/log",
            arguments: ["show", "--style", "compact", "--last", "1h", "--predicate", predicate, "--info"],
            timeout: 5
        ) else {
            return [securityLogStatus(message: "Recent security activity could not be read during this scan.")]
        }

        var messages = Set<String>()
        let lines = output.stdout.split(whereSeparator: \.isNewline)
            .dropFirst()
            .reversed()
            .compactMap { line -> SecurityEvent? in
                guard line.range(of: #"^\d{4}-\d{2}-\d{2}"#, options: .regularExpression) != nil else {
                    return nil
                }
                let message = macOSLogMessage(from: String(line))
                let lowered = message.lowercased()
                let significant = ["deny", "denied", "blocked", "failed", "authentication"].contains {
                    lowered.contains($0)
                }
                let displayMessage = shortenedSecurityMessage(message)
                guard significant, messages.insert(displayMessage).inserted else { return nil }
                let severity: InsightSeverity = lowered.contains("deny")
                    || lowered.contains("denied")
                    || lowered.contains("blocked")
                    || lowered.contains("authentication fail") ? .warning : .informational
                return SecurityEvent(
                    id: "macos-log-\(messages.count)",
                    timestamp: String(line.prefix(23)),
                    source: "macOS Security Log",
                    message: displayMessage,
                    severity: severity
                )
            }

        let recent = Array(lines.prefix(6))
        return recent.isEmpty
            ? [securityLogStatus(message: "No recent denied authentication or policy events were visible.")]
            : recent
    }

    private func macOSLogMessage(from line: String) -> String {
        guard let bracket = line.firstIndex(of: "]") else { return line }
        return line[line.index(after: bracket)...].trimmingCharacters(in: .whitespaces)
    }

    private func shortenedSecurityMessage(_ message: String) -> String {
        guard message.count > 180 else { return message }
        return "\(message.prefix(95))... \(message.suffix(80))"
    }

    #endif

    #if os(Linux)
    private func linuxFindings(metrics: PerformanceMetrics) -> [SecurityFinding] {
        var findings: [SecurityFinding] = []

        if let output = CommandRunner.run("/usr/sbin/ufw", arguments: ["status"]),
           output.combinedText.lowercased().contains("inactive") {
            findings.append(SecurityFinding(
                id: "firewall.disabled",
                title: "UFW firewall is inactive",
                detail: "Ubuntu's uncomplicated firewall reports an inactive state.",
                severity: .critical,
                recommendation: "Enable UFW when appropriate for this machine."
            ))
        }

        if let output = CommandRunner.run("/usr/lib/update-notifier/apt-check", arguments: ["--human-readable"]),
           containsPendingSecurityUpdates(output.combinedText) {
            findings.append(SecurityFinding(
                id: "updates.security-pending",
                title: "Security updates are pending",
                detail: "Ubuntu reports packages with security updates available.",
                severity: .critical,
                recommendation: "Install pending Ubuntu security updates."
            ))
        }

        if let output = CommandRunner.run("/usr/bin/lastb", arguments: ["-n", "5"]),
           output.exitCode == 0,
           output.stdout.split(whereSeparator: \.isNewline).contains(where: { !$0.contains("btmp begins") }) {
            findings.append(SecurityFinding(
                id: "login.failed",
                title: "Recent failed login attempts",
                detail: "Failed login records are visible in the recent login audit history.",
                severity: .warning,
                recommendation: "Review failed login sources and secure exposed accounts."
            ))
        }

        let sensitivePaths = ["/etc/passwd", "/etc/shadow", "/etc/sudoers"]
        for path in sensitivePaths where isWorldWritable(path: path) {
            findings.append(SecurityFinding(
                id: "permissions.\(path)",
                title: "Sensitive path is world-writable",
                detail: "\(path) permits writes by any local user.",
                severity: .critical,
                recommendation: "Correct permissions for \(path)."
            ))
        }

        if let process = metrics.topProcesses.first(where: { $0.cpuPercent >= 90 }) {
            let executablePath = ExecutablePathResolver.path(forPID: process.pid)
            let pathDetail = executablePath.map { " at \($0)" } ?? ""
            findings.append(SecurityFinding(
                id: "process.high-cpu.\(process.pid)",
                title: "Review unusually busy process",
                detail: "\(process.name)\(pathDetail) is currently using \(Int(process.cpuPercent))% CPU.",
                severity: .warning,
                recommendation: "Confirm that the high-CPU process is expected."
            ))
        }

        for process in metrics.topProcesses where process.cpuPercent >= 50 {
            guard
                let executablePath = ExecutablePathResolver.path(forPID: process.pid),
                ExecutablePathResolver.isWritableLocation(executablePath)
            else {
                continue
            }
            findings.append(SecurityFinding(
                id: "writable-executable.\(process.pid)",
                title: "Review process running from a writable location",
                detail: "\(process.name) (\(executablePath)) is using \(Int(process.cpuPercent))% CPU from a writable location.",
                severity: .warning,
                recommendation: "Confirm this executable is expected and was not dropped into a temporary or downloads folder."
            ))
        }

        return findings
    }

    private func linuxSecurityEvents() -> [SecurityEvent] {
        guard let output = CommandRunner.run(
            "/usr/bin/journalctl",
            arguments: ["--since", "1 hour ago", "--no-pager", "-n", "40", "-p", "warning"],
            timeout: 5
        ) else {
            return [securityLogStatus(message: "Recent journal security activity could not be read during this scan.")]
        }

        let keywords = ["authentication", "failed password", "sudo", "apparmor", "denied", "ufw"]
        var seen = Set<String>()
        let events = output.stdout.split(whereSeparator: \.isNewline).reversed().compactMap { line -> SecurityEvent? in
            let message = String(line)
            let lowered = message.lowercased()
            guard keywords.contains(where: lowered.contains), seen.insert(message).inserted else { return nil }
            return SecurityEvent(
                id: "journal-\(seen.count)",
                source: "systemd journal",
                message: String(message.prefix(180)),
                severity: lowered.contains("denied") || lowered.contains("failed") ? .warning : .informational
            )
        }
        let recent = Array(events.prefix(6))
        return recent.isEmpty
            ? [securityLogStatus(message: "No recent security-related warning events were visible in the journal.")]
            : recent
    }

    private func containsPendingSecurityUpdates(_ text: String) -> Bool {
        let lowered = text.lowercased()
        guard lowered.contains("security") else { return false }
        return !lowered.contains("0 updates are security updates")
            && !lowered.contains("0 security updates")
    }

    private func isWorldWritable(path: String) -> Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path),
              let permissions = (attributes[.posixPermissions] as? NSNumber)?.intValue else {
            return false
        }
        return permissions & 0o002 != 0
    }
    #endif

    private func securityLogStatus(message: String) -> SecurityEvent {
        SecurityEvent(
            id: "security-log.status",
            source: "Security Activity",
            message: message,
            severity: .informational
        )
    }
}

public struct MockSecurityChecker: SecurityChecking {
    private let findings: [SecurityFinding]
    private let events: [SecurityEvent]

    public init(findings: [SecurityFinding] = [
        SecurityFinding(
            id: "firewall.disabled",
            title: "Firewall is disabled",
            detail: "Mock security scan reports the firewall as disabled.",
            severity: .critical,
            recommendation: "Enable the firewall."
        )
    ], events: [SecurityEvent] = [
        SecurityEvent(
            id: "mock-auth-event",
            timestamp: "2026-05-26 12:00:00",
            source: "macOS Security Log",
            message: "Blocked authorization attempt from an unexpected helper.",
            severity: .warning
        )
    ]) {
        self.findings = findings
        self.events = events
    }

    public func check(metrics: PerformanceMetrics) async -> [SecurityFinding] {
        findings
    }

    public func recentEvents() async -> [SecurityEvent] {
        events
    }
}
