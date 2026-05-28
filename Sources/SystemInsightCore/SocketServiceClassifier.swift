import Foundation

public enum SocketServiceClassifier {
    private static let tlsPorts: Set<Int> = [443, 8443]
    private static let airPlayListenPorts: Set<Int> = [5000, 7000]
    private static let ephemeralPortRange = 49_152...65_535

    private static let ircClientTokens: Set<String> = [
        "irc", "irssi", "weechat", "hexchat", "limechat", "textual", "colloquy", "mirc", "chatzilla",
        "konversation", "xchat", "nudge", "chatsen", "chatty", "irclient",
    ]

    public static func hint(
        transport: NetworkTransport,
        localEndpoint: String,
        remoteEndpoint: String?,
        processName: String? = nil
    ) -> SocketServiceHint {
        var candidates: [(port: Int, source: String)] = []
        if let remotePort = EndpointPortParser.port(from: remoteEndpoint) {
            candidates.append((remotePort, "peer port"))
        }
        if let localPort = EndpointPortParser.port(from: localEndpoint) {
            candidates.append((localPort, "local port"))
        }

        guard !candidates.isEmpty else {
            return SocketServiceHint(
                label: "UNCLASSIFIED",
                confidence: .unclassified,
                basis: "no numeric port"
            )
        }

        let ports = Set(candidates.map(\.port))

        if let identity = processIdentityHint(
            processName: processName,
            transport: transport,
            ports: ports
        ) {
            return identity
        }

        var best: SocketServiceHint?
        var bestRank = -1

        for candidate in candidates {
            let portMatch = SocketServiceCatalog.classification(
                for: transport,
                port: candidate.port,
                systemName: nil
            )
            if portMatch.confidence != .unclassified {
                let rank = rank(for: portMatch.confidence)
                if rank > bestRank {
                    bestRank = rank
                    best = SocketServiceHint(
                        label: portMatch.label,
                        confidence: portMatch.confidence,
                        basis: basisLabel(
                            source: candidate.source,
                            port: candidate.port,
                            systemName: nil
                        )
                    )
                }
                continue
            }

            let systemName = SocketServiceCatalog.systemServiceName(
                port: candidate.port,
                transport: transport
            )
            let match = SocketServiceCatalog.classification(
                for: transport,
                port: candidate.port,
                systemName: systemName
            )
            let rank = rank(for: match.confidence)
            if rank > bestRank {
                bestRank = rank
                best = SocketServiceHint(
                    label: match.label,
                    confidence: match.confidence,
                    basis: basisLabel(
                        source: candidate.source,
                        port: candidate.port,
                        systemName: systemName
                    )
                )
            }
        }

        if let best, best.confidence != .unclassified {
            return best
        }

        if let aligned = processAlignedHint(
            processName: processName,
            transport: transport,
            ports: ports
        ) {
            return aligned
        }

        if let ephemeral = ephemeralPortHint(ports: ports) {
            return ephemeral
        }

        if let linkHint = appleLinkLocalHint(
            transport: transport,
            localEndpoint: localEndpoint,
            remoteEndpoint: remoteEndpoint,
            ports: candidates.map(\.port)
        ) {
            return linkHint
        }

        if let best {
            return best
        }

        let fallback = candidates[0]
        return SocketServiceHint(
            label: "UNCLASSIFIED",
            confidence: .unclassified,
            basis: "\(fallback.source) \(fallback.port)"
        )
    }

    /// Backward-compatible entry point used in tests.
    public static func portNumber(from endpoint: String?) -> Int? {
        EndpointPortParser.port(from: endpoint)
    }

    public static func systemServiceName(forPort port: Int, transport: NetworkTransport = .tcp) -> String? {
        SocketServiceCatalog.systemServiceName(port: port, transport: transport)
    }

    private static func rank(for confidence: SocketServiceConfidence) -> Int {
        switch confidence {
        case .portMapped: return 2
        case .heuristic: return 1
        case .unclassified: return 0
        }
    }

    private static func basisLabel(source: String, port: Int, systemName: String?) -> String {
        if let systemName {
            return "\(source) \(port) (\(systemName))"
        }
        return "\(source) \(port)"
    }

    private static func heuristic(_ label: String, basis: String) -> SocketServiceHint {
        SocketServiceHint(label: label, confidence: .heuristic, basis: basis)
    }

    /// Process name and port pattern matched together (stronger than port or name alone).
    private static func identified(_ label: String, basis: String) -> SocketServiceHint {
        SocketServiceHint(label: label, confidence: .portMapped, basis: basis)
    }

    /// Process + port patterns that are more specific than the well-known port table alone.
    private static func processIdentityHint(
        processName: String?,
        transport: NetworkTransport,
        ports: Set<Int>
    ) -> SocketServiceHint? {
        guard transport == .tcp else { return nil }
        let token = normalizedProcessToken(processName)
        guard !token.isEmpty else { return nil }

        if isIRCClient(token), ports.contains(where: tlsPorts.contains) {
            return identified("IRC/TLS", basis: "process \(token) on TLS port")
        }
        if isIRCClient(token), ports.contains(where: isLikelyIRCPort) {
            return identified("IRC", basis: "process \(token)")
        }

        if tokenContains(token, "tor") || tokenContains(token, "torbrowser"),
           ports.contains(9050) || ports.contains(9150) {
            return identified("TOR/SOCKS", basis: "process \(token)")
        }
        if tokenContains(token, "tailscale") || tokenContains(token, "wireguard"), ports.contains(51820) {
            return identified("WIREGUARD", basis: "process \(token)")
        }
        if tokenContains(token, "coredeviceservice"), ports.contains(where: ephemeralPortRange.contains) {
            return identified("APPLE-DEVICE", basis: "process \(token) (device link)")
        }
        if tokenContains(token, "controlcenter"), ports.contains(where: airPlayListenPorts.contains) {
            return identified("AIRPLAY", basis: "process \(token)")
        }
        if tokenContains(token, "rapportd") {
            return identified("CONTINUITY", basis: "process \(token)")
        }
        if tokenContains(token, "remotepairingd") {
            return identified("REMOTE-PAIR", basis: "process \(token)")
        }
        if token == "adb" || (tokenContains(token, "adb") && ports.contains(5037)) {
            return identified("ADB", basis: "process \(token)")
        }
        if tokenContains(token, "sharingd") {
            return identified("AIRDROP", basis: "process \(token)")
        }
        if tokenContains(token, "identityservicesd") {
            return identified("IMESSAGE", basis: "process \(token)")
        }
        if tokenContains(token, "xcode"), ports.contains(where: ephemeralPortRange.contains) {
            return identified("XCODE-DEV", basis: "process \(token)")
        }
        if tokenContains(token, "java"), ports.contains(where: ephemeralPortRange.contains) {
            return identified("JAVA/JDWP", basis: "process \(token)")
        }
        if tokenContains(token, "replicatord") {
            return identified("ICLOUD-SYNC", basis: "process \(token)")
        }

        return nil
    }

    /// Database and tooling hints when the port table did not classify the socket.
    private static func processAlignedHint(
        processName: String?,
        transport: NetworkTransport,
        ports: Set<Int>
    ) -> SocketServiceHint? {
        let token = normalizedProcessToken(processName)
        guard !token.isEmpty else { return nil }

        if tokenContains(token, "postgres"), ports.contains(5432) {
            return heuristic("POSTGRES", basis: "process \(token)")
        }
        if tokenContains(token, "redis"), ports.contains(6379) {
            return heuristic("REDIS", basis: "process \(token)")
        }
        if tokenContains(token, "mongod"), ports.contains(27017) {
            return heuristic("MONGODB", basis: "process \(token)")
        }
        if transport == .udp, tokenContains(token, "mdns") {
            return heuristic("mDNS", basis: "process \(token)")
        }
        if tokenContains(token, "ssh"), ports.contains(22) {
            return heuristic("SSH", basis: "process \(token)")
        }
        return nil
    }

    private static func normalizedProcessToken(_ processName: String?) -> String {
        guard let processName else { return "" }
        return normalizeApplicationToken(processName)
    }

    /// Last path component of lsof COMMAND or bundle executable (e.g. `…/Nudge.app/…/Nudge` → `nudge`).
    private static func normalizeApplicationToken(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        var token = URL(fileURLWithPath: trimmed).lastPathComponent.lowercased()
        if token.hasSuffix(".app") {
            token = String(token.dropLast(4))
        }
        return token
    }

    private static func tokenContains(_ token: String, _ substring: String) -> Bool {
        token.contains(substring)
    }

    private static func isIRCClient(_ token: String) -> Bool {
        ircClientTokens.contains(token)
    }

    private static func isLikelyIRCPort(_ port: Int) -> Bool {
        port == 194 || port == 6697 || (6_660...6_669).contains(port)
    }

    private static func ephemeralPortHint(ports: Set<Int>) -> SocketServiceHint? {
        guard !ports.isEmpty, ports.allSatisfy(ephemeralPortRange.contains) else { return nil }
        let portList = ports.sorted().map(String.init).joined(separator: ",")
        return heuristic("EPHEMERAL", basis: "ephemeral ports \(portList)")
    }

    private static func appleLinkLocalHint(
        transport: NetworkTransport,
        localEndpoint: String,
        remoteEndpoint: String?,
        ports: [Int]
    ) -> SocketServiceHint? {
        guard transport == .tcp, !ports.isEmpty else { return nil }
        let endpoints = [localEndpoint, remoteEndpoint].compactMap { $0?.lowercased() }
        guard endpoints.contains(where: { $0.contains("fe80:") }) else { return nil }
        guard ports.allSatisfy({ (1_024...1_027).contains($0) }) else { return nil }
        return identified(
            "APPLE-LINK",
            basis: "link-local \(ports.map(String.init).joined(separator: ","))"
        )
    }
}
