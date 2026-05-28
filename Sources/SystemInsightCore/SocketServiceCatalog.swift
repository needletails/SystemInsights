import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

enum SocketServiceCatalog {
    private final class SystemNameCache: @unchecked Sendable {
        let lock = NSLock()
        var values: [String: String] = [:]
    }

    private static let systemNameCache = SystemNameCache()

    static func namedPort(_ token: String) -> Int? {
        namedPorts[token.lowercased()]
    }

    static func systemServiceName(port: Int, transport: NetworkTransport) -> String? {
        let cacheKey = "\(transport.rawValue):\(port)"
        let cache = systemNameCache
        cache.lock.lock()
        defer { cache.lock.unlock() }
        if let cached = cache.values[cacheKey] {
            return cached.isEmpty ? nil : cached
        }
        let resolved = resolveSystemServiceName(port: port, transport: transport)
        cache.values[cacheKey] = resolved ?? ""
        return resolved
    }

    private static func resolveSystemServiceName(port: Int, transport: NetworkTransport) -> String? {
        #if canImport(Darwin) || canImport(Glibc)
        let proto = transport == .tcp ? "tcp" : "udp"
        let networkPort = Int32(UInt16(port).bigEndian)
        return proto.withCString { protoPointer in
            guard let entry = getservbyport(networkPort, protoPointer) else {
                return nil
            }
            return String(cString: entry.pointee.s_name)
        }
        #else
        return nil
        #endif
    }

    static func classification(
        for transport: NetworkTransport,
        port: Int,
        systemName: String? = nil
    ) -> (label: String, confidence: SocketServiceConfidence) {
        if let mapped = portClassification(for: transport, port: port) {
            return mapped
        }
        if let systemName, let mapped = nameClassification(for: transport, name: systemName) {
            return mapped
        }
        return ("UNCLASSIFIED", .unclassified)
    }

    private static func portClassification(
        for transport: NetworkTransport,
        port: Int
    ) -> (label: String, confidence: SocketServiceConfidence)? {
        switch (transport, port) {
        case (_, 53): return ("DNS", .portMapped)
        case (.udp, 67), (.udp, 68): return ("DHCP", .portMapped)
        case (.udp, 123): return ("NTP", .portMapped)
        case (.udp, 137), (.udp, 138): return ("NETBIOS", .portMapped)
        case (.udp, 5353), (.udp, 5355): return ("mDNS", .portMapped)
        case (.tcp, 22): return ("SSH", .portMapped)
        case (.tcp, 25), (.tcp, 465), (.tcp, 587): return ("SMTP", .portMapped)
        case (.tcp, 80), (.tcp, 8080), (.tcp, 8008), (.tcp, 8888): return ("HTTP", .portMapped)
        case (.tcp, 110), (.tcp, 995): return ("POP", .portMapped)
        case (.tcp, 143), (.tcp, 993): return ("IMAP", .portMapped)
        case (.tcp, 443), (.tcp, 8443): return ("HTTPS/TLS", .portMapped)
        case (.tcp, 3306): return ("MYSQL", .portMapped)
        case (.tcp, 5432): return ("POSTGRES", .portMapped)
        case (.tcp, 6379): return ("REDIS", .portMapped)
        case (.tcp, 27017): return ("MONGODB", .portMapped)
        case (.udp, 443): return ("QUIC/HTTP3", .portMapped)
        case (.tcp, 554), (.udp, 554): return ("RTSP", .portMapped)
        case (.tcp, 194), (.tcp, 6660...6669), (.tcp, 6697): return ("IRC", .portMapped)
        case (.udp, 3478), (.udp, 5349): return ("STUN/TURN", .portMapped)
        case (.udp, 5004), (.udp, 5005): return ("RTP/RTCP", .portMapped)
        case (.udp, 5060), (.udp, 5061), (.tcp, 5060), (.tcp, 5061): return ("SIP", .portMapped)
        case (.udp, 51820): return ("WIREGUARD", .portMapped)
        case (.udp, 1900): return ("SSDP", .portMapped)
        case (.tcp, 1194), (.udp, 1194): return ("OPENVPN", .portMapped)
        case (.tcp, 1024...1027): return ("APPLE-LINK", .portMapped)
        case (.tcp, 5223), (.tcp, 5228): return ("PUSH/PLAY", .portMapped)
        case (.tcp, 8883): return ("MQTT", .portMapped)
        case (.tcp, 5900): return ("VNC", .portMapped)
        case (.tcp, 3389): return ("RDP", .portMapped)
        case (.tcp, 5000): return ("AIRPLAY/UPNP", .portMapped)
        case (.tcp, 5037): return ("ADB", .portMapped)
        case (.tcp, 7000): return ("AIRPLAY", .portMapped)
        default: return nil
        }
    }

    private static func nameClassification(
        for transport: NetworkTransport,
        name: String
    ) -> (label: String, confidence: SocketServiceConfidence)? {
        switch (transport, name.lowercased()) {
        case (_, "domain"): return ("DNS", .portMapped)
        case (.tcp, "http"), (.tcp, "www"), (.tcp, "www-http"): return ("HTTP", .portMapped)
        case (.tcp, "https"): return ("HTTPS/TLS", .portMapped)
        case (.tcp, "ssh"): return ("SSH", .portMapped)
        case (.tcp, "smtp"), (.tcp, "submission"): return ("SMTP", .portMapped)
        case (.tcp, "imap"), (.tcp, "imaps"): return ("IMAP", .portMapped)
        case (.tcp, "pop3"): return ("POP", .portMapped)
        case (.udp, "ntp"): return ("NTP", .portMapped)
        case (.udp, "mdns"), (.udp, "zeroconf"): return ("mDNS", .portMapped)
        case (.tcp, "irc"), (.tcp, "ircs"): return ("IRC", .portMapped)
        case (.tcp, "commplex-main"), (.tcp, "commplex-link"): return ("AIRPLAY/UPNP", .portMapped)
        case (.tcp, "afs3-fileserver"): return ("AIRPLAY", .portMapped)
        case (.tcp, "android-debug"): return ("ADB", .portMapped)
        case (.udp, "rtp"), (.udp, "rtsp"): return ("RTP/RTCP", .portMapped)
        case (.udp, "sip"): return ("SIP", .portMapped)
        case (.udp, "snmp"): return ("SNMP", .portMapped)
        default: return nil
        }
    }

    private static let namedPorts: [String: Int] = [
        "domain": 53,
        "http": 80,
        "https": 443,
        "www": 80,
        "www-http": 80,
        "irc": 6667,
        "ircs": 6697,
        "imaps": 993,
        "imap": 143,
        "ldap": 389,
        "mdns": 5353,
        "zeroconf": 5353,
        "ntp": 123,
        "pop3": 110,
        "rtsp": 554,
        "rtp": 5004,
        "sip": 5060,
        "smtp": 25,
        "submission": 587,
        "ssh": 22,
        "mysql": 3306,
        "postgresql": 5432,
        "redis": 6379,
        "mongodb": 27017
    ]
}
