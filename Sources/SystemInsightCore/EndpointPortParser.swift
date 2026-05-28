import Foundation

/// Parses host:port tokens from `lsof`, `ss`, and procfs-style endpoint strings.
enum EndpointPortParser {
    static func host(from endpoint: String?) -> String {
        guard let endpoint, !endpoint.isEmpty else { return "" }
        return hostPart(from: normalizeEndpoint(endpoint))
    }

    static func port(from endpoint: String?) -> Int? {
        guard let endpoint, !endpoint.isEmpty else { return nil }
        let normalized = normalizeEndpoint(endpoint)
        guard let portToken = portToken(from: normalized) else { return nil }
        return parsePortToken(portToken, host: hostPart(from: normalized))
    }

    private static func normalizeEndpoint(_ endpoint: String) -> String {
        var value = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        if let open = value.firstIndex(of: "(") {
            value = String(value[..<open]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return value
    }

    private static func hostPart(from endpoint: String) -> String {
        if endpoint.hasPrefix("[") {
            guard let bracketEnd = endpoint.firstIndex(of: "]") else { return endpoint }
            return String(endpoint[endpoint.index(after: endpoint.startIndex)..<bracketEnd])
        }
        if let colon = endpoint.lastIndex(of: ":") {
            return String(endpoint[..<colon])
        }
        return endpoint
    }

    private static func portToken(from endpoint: String) -> String? {
        if endpoint.hasPrefix("[") {
            guard let bracketEnd = endpoint.firstIndex(of: "]") else { return nil }
            let afterBracket = endpoint.index(after: bracketEnd)
            guard afterBracket < endpoint.endIndex, endpoint[afterBracket] == ":" else { return nil }
            return String(endpoint[endpoint.index(after: afterBracket)...])
        }
        if let zonePort = zoneScopedIPv6PortToken(endpoint) {
            return zonePort
        }
        guard let colon = endpoint.lastIndex(of: ":") else { return nil }
        return String(endpoint[endpoint.index(after: colon)...])
    }

    /// `fe80::1%en0:443` — zone id contains colons, so `lastIndex(of: ":")` is wrong.
    private static func zoneScopedIPv6PortToken(_ endpoint: String) -> String? {
        guard endpoint.contains("%"), endpoint.contains(":") else { return nil }
        guard let zoneMarker = endpoint.lastIndex(of: "%") else { return nil }
        let afterZone = endpoint.index(after: zoneMarker)
        guard afterZone < endpoint.endIndex else { return nil }
        let tail = endpoint[afterZone...]
        guard let portColon = tail.lastIndex(of: ":") else { return nil }
        let portToken = String(tail[tail.index(after: portColon)...])
        guard !portToken.isEmpty else { return nil }
        return portToken
    }

    private static func parsePortToken(_ token: String, host: String) -> Int? {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "*" else { return nil }

        if let decimal = Int(trimmed), (1...65_535).contains(decimal) {
            if shouldPreferHexPort(host: host, portToken: trimmed) {
                if let hex = Int(trimmed, radix: 16), (1...65_535).contains(hex) {
                    return hex
                }
            }
            return decimal
        }

        if trimmed.count == 4,
           trimmed.allSatisfy(\.isHexDigit),
           let hex = Int(trimmed, radix: 16),
           (1...65_535).contains(hex) {
            return hex
        }

        return SocketServiceCatalog.namedPort(trimmed)
    }

    private static func shouldPreferHexPort(host: String, portToken: String) -> Bool {
        guard portToken.count == 4, portToken.allSatisfy(\.isHexDigit) else { return false }
        let normalized = host.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        if normalized == "*" { return false }
        if normalized.count == 8, normalized.allSatisfy(\.isHexDigit) { return true }
        if normalized.count == 32, normalized.allSatisfy(\.isHexDigit) { return true }
        return false
    }
}
