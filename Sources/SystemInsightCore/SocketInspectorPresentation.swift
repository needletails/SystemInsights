import Foundation

public struct SocketInspectorContext: Sendable {
    public let observedAt: Date?
    public let networkInterface: String?
    public let vpnSummary: String?

    public init(observedAt: Date? = nil, network: NetworkMetrics? = nil) {
        self.observedAt = observedAt
        networkInterface = network?.interfaceName
        if let network {
            vpnSummary = Self.vpnSummary(network.vpn)
        } else {
            vpnSummary = nil
        }
    }

    private static func vpnSummary(_ vpn: VPNConnectivity) -> String {
        switch vpn.state {
        case .connected:
            if let name = vpn.serviceName, !name.isEmpty {
                return "Connected (\(name))"
            }
            return "Connected"
        case .tunnelDetected:
            let interfaces = vpn.activeInterfaces.joined(separator: ", ")
            return interfaces.isEmpty ? "Tunnel active" : "Tunnel via \(interfaces)"
        case .notDetected:
            return "No active VPN"
        case .unavailable:
            return "VPN state unavailable"
        }
    }
}

/// Host-centric flow label for a socket or activity record.
public enum SocketHostFlowKind: String, Sendable {
    case inbound = "INBOUND"
    case outbound = "OUTBOUND"
    case inboundReady = "INBOUND-READY"
    case bidirectional = "BIDIRECTIONAL"
    case undetermined = "UNDETERMINED"
}

public struct SocketFlowPerspective: Sendable, Equatable {
    public let kind: SocketHostFlowKind
    public let summary: String
    public let detail: String
    public let initiation: String

    public init(kind: SocketHostFlowKind, summary: String, detail: String, initiation: String) {
        self.kind = kind
        self.summary = summary
        self.detail = detail
        self.initiation = initiation
    }
}

public struct SocketInspectorSummaryBadge: Sendable, Identifiable {
    public let id: String
    public let label: String
    public let value: String

    public init(label: String, value: String) {
        id = label
        self.label = label
        self.value = value
    }
}

public struct SocketInspectorBoundaryNote: Sendable, Identifiable {
    public let id: String
    public let title: String
    public let value: String

    public init(id: String, title: String, value: String) {
        self.id = id
        self.title = title
        self.value = value
    }
}

public struct SocketInspectorRow: Sendable, Identifiable {
    public let id: String
    public let title: String
    public let value: String
    public let isHighlighted: Bool

    public init(id: String, title: String, value: String, isHighlighted: Bool = false) {
        self.id = id
        self.title = title
        self.value = value
        self.isHighlighted = isHighlighted
    }
}

public enum SocketInspectorPresentation {
    public static func flowPerspective(for socket: VisibleSocket) -> SocketFlowPerspective {
        flowPerspective(
            transport: socket.transport,
            state: socket.state,
            localEndpoint: socket.localEndpoint,
            remoteEndpoint: socket.remoteEndpoint
        )
    }

    public static func flowPerspective(for event: NetworkActivityEvent) -> SocketFlowPerspective {
        let state: VisibleSocketState = switch event.action {
        case .listening, .stoppedListening: .listening
        case .opened, .observed, .closed: event.remoteEndpoint == nil ? .datagram : .established
        }
        return flowPerspective(
            transport: event.transport,
            state: state,
            localEndpoint: event.localEndpoint,
            remoteEndpoint: event.remoteEndpoint,
            activityAction: event.action
        )
    }

    public static func summaryBadges(for socket: VisibleSocket) -> [SocketInspectorSummaryBadge] {
        let flow = flowPerspective(for: socket)
        return [
            .init(label: "FLOW", value: flow.summary),
            .init(label: "TRANSPORT", value: socket.transport.rawValue),
            .init(label: "STATE", value: socket.state.rawValue),
            .init(label: "SERVICE", value: displayServiceLabel(socket.serviceHint.label))
        ]
    }

    public static func summaryBadges(for event: NetworkActivityEvent) -> [SocketInspectorSummaryBadge] {
        let flow = flowPerspective(for: event)
        return [
            .init(label: "FLOW", value: flow.summary),
            .init(label: "ACTION", value: event.action.rawValue),
            .init(label: "TRANSPORT", value: event.transport.rawValue),
            .init(label: "SERVICE", value: displayServiceLabel(event.serviceHint.label))
        ]
    }

    public static let boundaryNotes: [SocketInspectorBoundaryNote] = [
        .init(
            id: "capture-scope",
            title: "Capture scope",
            value: "Metadata only — endpoint ownership and port-derived hints."
        ),
        .init(
            id: "classification",
            title: "Classification",
            value: "Well-known port mapping, process+port heuristic, or no mapping."
        ),
        .init(
            id: "flow-legend",
            title: "Inbound / outbound",
            value: "INBOUND = remote initiated toward this host; OUTBOUND = local process initiated toward remote; INBOUND-READY = listener; BIDIRECTIONAL = established traffic in both directions."
        )
    ]

    public static let boundaryFooter =
        "This record comes from socket metadata, not payload capture. Confirming protocol details or message payloads requires an explicit capture mode with user consent."

    public static func rows(
        for socket: VisibleSocket,
        context: SocketInspectorContext = SocketInspectorContext()
    ) -> [SocketInspectorRow] {
        let hint = socket.serviceHint
        let flow = flowPerspective(for: socket)
        var rows: [SocketInspectorRow] = [
            .init(id: "flow", title: "Inbound / outbound", value: flow.summary, isHighlighted: true),
            .init(id: "flow-detail", title: "Flow explanation", value: flow.detail),
            .init(id: "initiation", title: "Who initiated", value: flow.initiation),
            .init(id: "role", title: "Connection role", value: connectionRole(socket)),
            .init(id: "process-display", title: "Process", value: processDisplayName(socket.processName)),
            .init(id: "process-path", title: "Process path", value: socket.processName),
            .init(id: "pid", title: "PID", value: String(socket.pid)),
            .init(id: "transport", title: "Transport", value: socket.transport.rawValue),
            .init(id: "state", title: "Socket state", value: socket.state.rawValue),
            .init(id: "service", title: "Service label", value: displayServiceLabel(hint.label), isHighlighted: true),
            .init(id: "confidence", title: "Classification", value: hint.confidence.displayName),
            .init(id: "evidence", title: "Match evidence", value: hint.basis),
            .init(id: "local-host", title: "Local host", value: hostDescription(socket.localEndpoint)),
            .init(id: "local-port", title: "Local port", value: portDescription(socket.localEndpoint)),
            .init(id: "peer-host", title: "Peer host", value: peerHostDescription(socket.remoteEndpoint)),
            .init(id: "peer-port", title: "Peer port", value: peerPortDescription(socket.remoteEndpoint)),
            .init(id: "local-full", title: "Local endpoint", value: socket.localEndpoint),
            .init(
                id: "peer-full",
                title: "Peer endpoint",
                value: socket.remoteEndpoint ?? peerEndpointPlaceholder(socket)
            ),
            .init(id: "binding", title: "Binding exposure", value: bindingExposure(socket.localEndpoint))
        ]
        if let observed = context.observedAt {
            rows.append(.init(id: "observed", title: "Last observed", value: formatTimestamp(observed)))
        }
        if let interface = context.networkInterface {
            rows.append(.init(id: "interface", title: "Active interface", value: interface))
        }
        if let vpn = context.vpnSummary {
            rows.append(.init(id: "vpn", title: "VPN context", value: vpn))
        }
        rows.append(.init(id: "record-id", title: "Record ID", value: socket.id))
        return rows
    }

    public static func rows(
        for event: NetworkActivityEvent,
        context: SocketInspectorContext = SocketInspectorContext()
    ) -> [SocketInspectorRow] {
        let hint = event.serviceHint
        let flow = flowPerspective(for: event)
        var rows: [SocketInspectorRow] = [
            .init(id: "flow", title: "Inbound / outbound", value: flow.summary, isHighlighted: true),
            .init(id: "flow-detail", title: "Flow explanation", value: flow.detail),
            .init(id: "initiation", title: "Who initiated", value: flow.initiation),
            .init(id: "action", title: "Activity", value: event.action.rawValue, isHighlighted: true),
            .init(id: "time", title: "Event time", value: formatTimestamp(event.timestamp)),
            .init(id: "process-display", title: "Process", value: processDisplayName(event.processName)),
            .init(id: "process-path", title: "Process path", value: event.processName),
            .init(id: "pid", title: "PID", value: String(event.pid)),
            .init(id: "transport", title: "Transport", value: event.transport.rawValue),
            .init(id: "service", title: "Service label", value: displayServiceLabel(hint.label), isHighlighted: true),
            .init(id: "confidence", title: "Classification", value: hint.confidence.displayName),
            .init(id: "evidence", title: "Match evidence", value: hint.basis),
            .init(id: "local-host", title: "Local host", value: hostDescription(event.localEndpoint)),
            .init(id: "local-port", title: "Local port", value: portDescription(event.localEndpoint)),
            .init(id: "peer-host", title: "Peer host", value: peerHostDescription(event.remoteEndpoint)),
            .init(id: "peer-port", title: "Peer port", value: peerPortDescription(event.remoteEndpoint)),
            .init(id: "local-full", title: "Local endpoint", value: event.localEndpoint),
            .init(
                id: "peer-full",
                title: "Peer endpoint",
                value: event.remoteEndpoint ?? "No peer endpoint in this event"
            ),
            .init(id: "binding", title: "Binding exposure", value: bindingExposure(event.localEndpoint))
        ]
        if let observed = context.observedAt {
            rows.append(.init(id: "poll", title: "Socket table refreshed", value: formatTimestamp(observed)))
        }
        if let interface = context.networkInterface {
            rows.append(.init(id: "interface", title: "Active interface", value: interface))
        }
        if let vpn = context.vpnSummary {
            rows.append(.init(id: "vpn", title: "VPN context", value: vpn))
        }
        rows.append(.init(id: "record-id", title: "Record ID", value: event.id))
        return rows
    }

    private static func flowPerspective(
        transport: NetworkTransport,
        state: VisibleSocketState,
        localEndpoint: String,
        remoteEndpoint: String?,
        activityAction: NetworkActivityAction? = nil
    ) -> SocketFlowPerspective {
        switch state {
        case .listening:
            let port = SocketServiceClassifier.portNumber(from: localEndpoint)
            let portText = port.map { " \($0)" } ?? ""
            return SocketFlowPerspective(
                kind: .inboundReady,
                summary: SocketHostFlowKind.inboundReady.rawValue,
                detail: "Local socket is listening\(portText) and accepts connections initiated by remote peers.",
                initiation: "Remote host connects inbound to this machine (your process accepted the listener)."
            )
        case .datagram:
            return datagramFlow(
                transport: transport,
                localEndpoint: localEndpoint,
                remoteEndpoint: remoteEndpoint
            )
        case .established:
            return establishedFlow(
                transport: transport,
                localEndpoint: localEndpoint,
                remoteEndpoint: remoteEndpoint,
                activityAction: activityAction
            )
        }
    }

    private static func establishedFlow(
        transport: NetworkTransport,
        localEndpoint: String,
        remoteEndpoint: String?,
        activityAction: NetworkActivityAction?
    ) -> SocketFlowPerspective {
        guard let remoteEndpoint, !remoteEndpoint.isEmpty else {
            return SocketFlowPerspective(
                kind: .undetermined,
                summary: SocketHostFlowKind.undetermined.rawValue,
                detail: "An established \(transport.rawValue) socket is shown without a visible remote endpoint in this sample.",
                initiation: "Initiator cannot be determined without a peer address."
            )
        }

        let localPort = SocketServiceClassifier.portNumber(from: localEndpoint)
        let remotePort = SocketServiceClassifier.portNumber(from: remoteEndpoint)

        if let localPort, let remotePort {
            if isEphemeral(localPort), isWellKnown(remotePort) || !isEphemeral(remotePort) {
                return SocketFlowPerspective(
                    kind: .outbound,
                    summary: SocketHostFlowKind.outbound.rawValue,
                    detail: "Local ephemeral port \(localPort) is connected to remote port \(remotePort) (\(hostDescription(remoteEndpoint))).",
                    initiation: "This machine initiated the connection (outbound from the local process)."
                )
            }
            if isWellKnown(localPort) || !isEphemeral(localPort), isEphemeral(remotePort) {
                return SocketFlowPerspective(
                    kind: .inbound,
                    summary: SocketHostFlowKind.inbound.rawValue,
                    detail: "Remote peer on port \(remotePort) connected to local port \(localPort) (\(hostDescription(localEndpoint))).",
                    initiation: "Remote host initiated the connection (inbound to the local process)."
                )
            }
            if isEphemeral(localPort), isEphemeral(remotePort) {
                return SocketFlowPerspective(
                    kind: .undetermined,
                    summary: SocketHostFlowKind.undetermined.rawValue,
                    detail: "Both local port \(localPort) and remote port \(remotePort) look ephemeral; metadata does not show which side dialed first.",
                    initiation: "Treat as an established peer session; direction of first packet is not inferred."
                )
            }
        }

        if activityAction == .opened {
            return SocketFlowPerspective(
                kind: .outbound,
                summary: SocketHostFlowKind.outbound.rawValue,
                detail: "Activity log shows this flow was opened toward \(remoteEndpoint).",
                initiation: "Local process likely initiated the outbound connection."
            )
        }

        return SocketFlowPerspective(
            kind: .bidirectional,
            summary: SocketHostFlowKind.bidirectional.rawValue,
            detail: "Established \(transport.rawValue) session between \(localEndpoint) and \(remoteEndpoint). Payloads flow in both directions once connected.",
            initiation: "Session is active; inbound and outbound packets are both possible after establishment."
        )
    }

    private static func datagramFlow(
        transport: NetworkTransport,
        localEndpoint: String,
        remoteEndpoint: String?
    ) -> SocketFlowPerspective {
        guard let remoteEndpoint, !remoteEndpoint.isEmpty else {
            return SocketFlowPerspective(
                kind: .inboundReady,
                summary: SocketHostFlowKind.inboundReady.rawValue,
                detail: "Local \(transport.rawValue) socket is bound without a pinned remote peer in this row.",
                initiation: "May receive inbound datagrams; outbound sends are not tied to one peer in metadata."
            )
        }

        let localPort = SocketServiceClassifier.portNumber(from: localEndpoint)
        let remotePort = SocketServiceClassifier.portNumber(from: remoteEndpoint)
        if let localPort, let remotePort, isEphemeral(localPort), isWellKnown(remotePort) || !isEphemeral(remotePort) {
            return SocketFlowPerspective(
                kind: .outbound,
                summary: SocketHostFlowKind.outbound.rawValue,
                detail: "Local port \(localPort) is associated with remote \(remoteEndpoint) in this UDP sample.",
                initiation: "Typical outbound client datagram flow toward a remote service."
            )
        }
        if let localPort, let remotePort, isWellKnown(localPort) || !isEphemeral(localPort), isEphemeral(remotePort) {
            return SocketFlowPerspective(
                kind: .inbound,
                summary: SocketHostFlowKind.inbound.rawValue,
                detail: "Remote \(remoteEndpoint) is associated with local listener port \(localPort).",
                initiation: "Typical inbound datagram toward a local UDP service."
            )
        }

        return SocketFlowPerspective(
            kind: .undetermined,
            summary: SocketHostFlowKind.undetermined.rawValue,
            detail: "\(transport.rawValue) flow between \(localEndpoint) and \(remoteEndpoint); direction is not classified from ports alone.",
            initiation: "UDP direction is inferred only when port roles are clear (service vs ephemeral)."
        )
    }

    private static func isEphemeral(_ port: Int) -> Bool {
        (49_152...65_535).contains(port)
    }

    private static func isWellKnown(_ port: Int) -> Bool {
        port <= 1_024 || SocketServiceClassifier.systemServiceName(forPort: port) != nil
    }

    private static func connectionRole(_ socket: VisibleSocket) -> String {
        switch (socket.transport, socket.state) {
        case (.tcp, .listening):
            return "TCP listener awaiting inbound connections"
        case (.tcp, .established):
            return "Active TCP session with a remote peer"
        case (.udp, .listening), (.udp, .datagram), (.udp, .established):
            return "UDP endpoint (datagrams; no persistent session)"
        case (.tcp, .datagram):
            return "TCP socket in an unusual state for this view"
        }
    }

    private static func processDisplayName(_ path: String) -> String {
        let name = URL(fileURLWithPath: path).lastPathComponent
        return name.isEmpty ? path : name
    }

    private static func displayServiceLabel(_ label: String) -> String {
        label == "UNCLASSIFIED" ? "No service mapping" : label
    }

    private static func hostDescription(_ endpoint: String) -> String {
        let host = EndpointPortParser.host(from: endpoint)
        if host == "*" { return "All interfaces (wildcard)" }
        if host.isEmpty { return endpoint }
        if host == "localhost" || host == "127.0.0.1" || host == "::1" {
            return "\(host) (loopback)"
        }
        if host.hasPrefix("fe80:") { return "\(host) (link-local)" }
        return host
    }

    private static func portDescription(_ endpoint: String) -> String {
        guard let port = SocketServiceClassifier.portNumber(from: endpoint) else {
            return "Not parsed"
        }
        if let service = SocketServiceClassifier.systemServiceName(forPort: port) {
            return "\(port) (\(service))"
        }
        return String(port)
    }

    private static func peerHostDescription(_ endpoint: String?) -> String {
        guard let endpoint else { return "—" }
        return hostDescription(endpoint)
    }

    private static func peerPortDescription(_ endpoint: String?) -> String {
        guard let endpoint else { return "—" }
        return portDescription(endpoint)
    }

    private static func peerEndpointPlaceholder(_ socket: VisibleSocket) -> String {
        switch socket.state {
        case .listening:
            return "No remote peer (listening socket)"
        case .datagram:
            return "No remote peer pinned in metadata (UDP)"
        case .established:
            return "Peer address not visible in this sample"
        }
    }

    private static func bindingExposure(_ localEndpoint: String) -> String {
        if isPublicBind(localEndpoint) {
            return "Listening on all interfaces (wildcard bind)"
        }
        return "Bound to a specific local address"
    }

    private static func isPublicBind(_ endpoint: String) -> Bool {
        endpoint.hasPrefix("*:")
            || endpoint.hasPrefix("0.0.0.0:")
            || endpoint.hasPrefix("[::]:")
            || endpoint.hasPrefix("[*]:")
    }

    private static func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

public extension SocketServiceConfidence {
    var displayName: String {
        switch self {
        case .portMapped: "Well-known port mapping"
        case .heuristic: "Process and port heuristic"
        case .unclassified: "No confident mapping"
        }
    }
}
