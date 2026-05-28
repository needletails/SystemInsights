import AppKit
import SwiftUI
import SystemInsightCore

struct SystemInsightsDashboardView: View {
    let model: InsightViewModel

    @State private var socketScope: SocketScope = .all
    @State private var socketQuery = ""
    @State private var selectedNetworkRecord: NetworkRecordSelection?

    private var latestNetwork: NetworkMetrics? {
        model.liveNetworkSamples.last?.metrics ?? model.snapshot?.metrics.network
    }

    var body: some View {
        ZStack {
            WindowMaterialBackground()
                .ignoresSafeArea()
            DashboardPalette.canvas
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    metricsStrip

                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 16) {
                            LiveTrafficPanel(
                                samples: model.liveNetworkSamples,
                                network: latestNetwork
                            )
                            .frame(height: 292)

                            connectivityPanel
                            insightPanel
                        }
                        .frame(width: 330)

                        SocketConsolePanel(
                            connections: model.visibleSockets,
                            events: model.socketActivityLog,
                            lastPollAt: model.lastSocketSampleAt,
                            network: latestNetwork,
                            interfaceName: latestNetwork?.interfaceName,
                            scope: $socketScope,
                            query: $socketQuery,
                            onSelectSocket: { selectedNetworkRecord = .socket($0) },
                            onSelectEvent: { selectedNetworkRecord = .event($0) }
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 632)
                    }

                    liveSecuritySignals
                    topCpuUsagePanel
                }
                .padding(.horizontal, 22)
                .padding(.top, 42)
                .padding(.bottom, 24)
            }
        }
        .frame(minWidth: 1_060, minHeight: 720)
        .preferredColorScheme(.dark)
        .onAppear {
            model.startLiveNetworkMonitoring()
        }
        .onDisappear {
            model.stopLiveNetworkMonitoring()
        }
        .sheet(item: $selectedNetworkRecord) { record in
            NetworkRecordDetailSheet(
                record: record,
                context: SocketInspectorContext(
                    observedAt: model.lastSocketSampleAt,
                    network: latestNetwork
                )
            )
        }
    }

    private var header: some View {
        HStack(spacing: 17) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [ratingColor.opacity(0.38), ratingColor.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Image(systemName: model.menuBarSymbol)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(ratingColor)
                }
                .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 4) {
                Text("SYSTEM INSIGHTS")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(1.1)
                    .foregroundStyle(DashboardPalette.muted)
                Text("Network Operations")
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                    .foregroundStyle(DashboardPalette.text)
                if let snapshot = model.snapshot {
                    Text("Health and socket visibility sampled \(snapshot.generatedAt.formatted(date: .abbreviated, time: .standard))")
                        .font(.caption)
                        .foregroundStyle(DashboardPalette.muted)
                }
            }

            Spacer(minLength: 20)

            PollStatusPill(lastPollAt: model.lastSocketSampleAt)

            if let snapshot = model.snapshot {
                HStack(spacing: 12) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(snapshot.rating.rawValue.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(ratingColor)
                        Text("HEALTH SCORE")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(DashboardPalette.subtle)
                    }
                    Text("\(snapshot.score)")
                        .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(DashboardPalette.text)
                    Text("/100")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(DashboardPalette.muted)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(DashboardPalette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(DashboardPalette.stroke, lineWidth: 1)
                }
            }

            Button {
                model.refresh()
            } label: {
                Label("Scan Now", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
            }
            .buttonStyle(.plain)
            .foregroundStyle(DashboardPalette.text)
            .background(DashboardPalette.elevated, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(DashboardPalette.stroke, lineWidth: 1)
            }
            .disabled(model.isRefreshing)
        }
    }

    @ViewBuilder
    private var metricsStrip: some View {
        if let snapshot = model.snapshot {
            HStack(spacing: 12) {
                TelemetryTile(
                    title: "CPU LOAD",
                    value: "\(Int(snapshot.metrics.cpuLoadPercent))%",
                    systemImage: "cpu",
                    tint: .cyan,
                    meter: snapshot.metrics.cpuLoadPercent
                )
                TelemetryTile(
                    title: "MEMORY PRESSURE",
                    value: "\(Int(snapshot.metrics.memoryPressurePercent))%",
                    systemImage: "memorychip",
                    tint: .purple,
                    meter: snapshot.metrics.memoryPressurePercent
                )
                TelemetryTile(
                    title: "DISK UTILIZED",
                    value: "\(Int(snapshot.metrics.diskUsagePercent))%",
                    systemImage: "internaldrive",
                    tint: .orange,
                    meter: snapshot.metrics.diskUsagePercent
                )
                TelemetryTile(
                    title: "VISIBLE SOCKETS",
                    value: "\(model.visibleSockets.count)",
                    systemImage: "point.3.connected.trianglepath.dotted",
                    tint: .green,
                    detail: "TCP + UDP observed"
                )
            }
        }
    }

    private var connectivityPanel: some View {
        DashboardSurface(title: "CONNECTIVITY", systemImage: "network") {
            if let network = latestNetwork {
                DashboardDetailRow(label: "Interface", value: network.interfaceName ?? "Unavailable")
                DashboardDetailRow(label: "Active TCP", value: "\(network.activeTCPConnections)")
                DashboardDetailRow(label: "Latency", value: formattedLatency(network.latencyMilliseconds), tint: .green)
                DashboardDetailRow(label: "VPN", value: network.vpn.state.rawValue, tint: vpnTint(for: network.vpn.state))

                Divider()
                    .overlay(DashboardPalette.stroke)
                Text(network.vpn.detail)
                    .font(.caption)
                    .foregroundStyle(DashboardPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Collecting network telemetry...")
                    .font(.caption)
                    .foregroundStyle(DashboardPalette.muted)
            }
        }
    }

    @ViewBuilder
    private var insightPanel: some View {
        if let snapshot = model.snapshot {
            DashboardSurface(title: "LATEST OBSERVATION", systemImage: "checkmark.shield") {
                Text(snapshot.topIssue?.title ?? "No scored issues detected")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DashboardPalette.text)
                Text(snapshot.topIssue?.detail ?? "No warning or critical conditions are present in the latest collection.")
                    .font(.caption)
                    .foregroundStyle(DashboardPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var liveSecuritySignals: some View {
        HStack(alignment: .top, spacing: 16) {
            DashboardSurface(title: "EXPOSURE WATCH", systemImage: "dot.radiowaves.left.and.right") {
                HStack(spacing: 18) {
                    SignalCount(label: "PUBLIC TCP", count: publicListeners.count, tint: .orange)
                    SignalCount(label: "BOUND UDP", count: exposedUDPSockets.count, tint: .yellow)
                    SignalCount(label: "1 MIN EVENTS", count: recentTransitionCount, tint: .cyan)
                }

                if exposedSockets.isEmpty {
                    Text("No wildcard-bound TCP listeners or UDP sockets visible in this poll.")
                        .font(.caption)
                        .foregroundStyle(DashboardPalette.muted)
                } else {
                    ForEach(Array(exposedSockets.prefix(3))) { socket in
                        HStack(spacing: 8) {
                            Text(socket.transport.rawValue)
                                .foregroundStyle(socket.transport == .tcp ? .cyan : .orange)
                            Text(socket.processName)
                                .foregroundStyle(DashboardPalette.text)
                            Spacer()
                            Text(socket.localEndpoint)
                                .foregroundStyle(DashboardPalette.muted)
                        }
                        .font(.caption.monospaced())
                    }
                    Text("Wildcard bindings can be expected system services; investigate unfamiliar owners.")
                        .font(.caption2)
                        .foregroundStyle(DashboardPalette.subtle)
                }
            }
            .frame(width: 430)

            DashboardSurface(title: "NETWORK ACTORS", systemImage: "person.2.wave.2") {
                if networkActors.isEmpty {
                    Text("No peer-addressed sockets are visible in this poll.")
                        .font(.caption)
                        .foregroundStyle(DashboardPalette.muted)
                } else {
                    ForEach(networkActors.prefix(5)) { actor in
                        HStack(spacing: 12) {
                            Text(actor.processName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(DashboardPalette.text)
                                .frame(width: 128, alignment: .leading)
                            Text("pid \(actor.pid)")
                                .font(.caption.monospaced())
                                .foregroundStyle(DashboardPalette.subtle)
                            Text("\(actor.tcpCount) TCP")
                                .foregroundStyle(.cyan)
                            Text("\(actor.udpCount) UDP")
                                .foregroundStyle(.orange)
                            Spacer()
                            Text("\(actor.peerCount) peers")
                                .foregroundStyle(DashboardPalette.muted)
                        }
                        .font(.caption.monospacedDigit())
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var topCpuUsagePanel: some View {
        if let snapshot = model.snapshot, !snapshot.metrics.topProcesses.isEmpty {
            DashboardSurface(title: "TOP CPU USAGE", systemImage: "cpu") {
                ForEach(Array(snapshot.metrics.topProcesses.prefix(6))) { process in
                    DashboardDetailRow(
                        label: processDisplayName(process.name),
                        value: "\(Int(process.cpuPercent.rounded()))% CPU",
                        tint: process.cpuPercent >= 50 ? .orange : DashboardPalette.text
                    )
                }
            }
        }
    }

    private func processDisplayName(_ path: String) -> String {
        let name = URL(fileURLWithPath: path).lastPathComponent
        return name.isEmpty ? path : name
    }

    private var publicListeners: [VisibleSocket] {
        model.visibleSockets.filter { $0.state == .listening && isWildcardEndpoint($0.localEndpoint) }
    }

    private var exposedUDPSockets: [VisibleSocket] {
        model.visibleSockets.filter { $0.transport == .udp && isWildcardEndpoint($0.localEndpoint) }
    }

    private var exposedSockets: [VisibleSocket] {
        publicListeners + exposedUDPSockets
    }

    private var recentTransitionCount: Int {
        let cutoff = Date().addingTimeInterval(-60)
        return model.socketActivityLog.filter { $0.timestamp >= cutoff }.count
    }

    private var networkActors: [NetworkActor] {
        let peerSockets = model.visibleSockets.filter { $0.remoteEndpoint != nil }
        let grouped = Dictionary(grouping: peerSockets) { "\($0.pid)|\($0.processName)" }
        return grouped.map { _, sockets in
            NetworkActor(
                processName: sockets[0].processName,
                pid: sockets[0].pid,
                tcpCount: sockets.filter { $0.transport == .tcp }.count,
                udpCount: sockets.filter { $0.transport == .udp }.count,
                peerCount: Set(sockets.compactMap(\.remoteEndpoint)).count
            )
        }
        .sorted { left, right in
            if left.peerCount != right.peerCount { return left.peerCount > right.peerCount }
            return left.processName < right.processName
        }
    }

    private func isWildcardEndpoint(_ endpoint: String) -> Bool {
        endpoint.hasPrefix("*:")
            || endpoint.hasPrefix("0.0.0.0:")
            || endpoint.hasPrefix("[::]:")
            || endpoint.hasPrefix("[*]:")
    }

    private var ratingColor: Color {
        guard let rating = model.snapshot?.rating else { return DashboardPalette.muted }
        switch rating {
        case .good: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }

    private func vpnTint(for state: VPNConnectionState) -> Color {
        switch state {
        case .connected, .tunnelDetected: return .green
        case .notDetected: return DashboardPalette.muted
        case .unavailable: return .orange
        }
    }
}

private enum SocketScope: String, CaseIterable, Identifiable {
    case all = "All"
    case tcp = "TCP"
    case udp = "UDP"
    case listening = "Listen"

    var id: Self { self }

    func includes(_ connection: VisibleSocket) -> Bool {
        switch self {
        case .all: return true
        case .tcp: return connection.transport == .tcp
        case .udp: return connection.transport == .udp
        case .listening: return connection.state == .listening
        }
    }
}

private enum DashboardPalette {
    static let canvas = Color(red: 0.035, green: 0.044, blue: 0.064).opacity(0.76)
    static let surface = Color(red: 0.069, green: 0.083, blue: 0.108).opacity(0.82)
    static let elevated = Color(red: 0.093, green: 0.107, blue: 0.137).opacity(0.88)
    static let console = Color(red: 0.025, green: 0.033, blue: 0.047).opacity(0.92)
    static let consoleElevated = Color(red: 0.048, green: 0.059, blue: 0.078).opacity(0.9)
    static let text = Color.white.opacity(0.94)
    static let muted = Color.white.opacity(0.58)
    static let subtle = Color.white.opacity(0.38)
    static let stroke = Color.white.opacity(0.075)
}

private struct NetworkActor: Identifiable {
    let processName: String
    let pid: Int
    let tcpCount: Int
    let udpCount: Int
    let peerCount: Int

    var id: String { "\(pid)|\(processName)" }
}

private enum NetworkRecordSelection: Identifiable {
    case socket(VisibleSocket)
    case event(NetworkActivityEvent)

    var id: String {
        switch self {
        case .socket(let socket): return "socket|\(socket.id)"
        case .event(let event): return "event|\(event.id)"
        }
    }
}

private struct SignalCount: View {
    let label: String
    let count: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(DashboardPalette.muted)
            Text("\(count)")
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundStyle(count == 0 ? DashboardPalette.text : tint)
        }
    }
}

private struct WindowMaterialBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.state = .active
    }
}

private struct TelemetryTile: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
    var meter: Double?
    var detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(0.55)
                    .foregroundStyle(DashboardPalette.muted)
                Spacer(minLength: 6)
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
            }

            Text(value)
                .font(.system(size: 25, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(DashboardPalette.text)

            if let meter {
                ProgressView(value: min(max(meter, 0), 100), total: 100)
                    .tint(tint)
                    .scaleEffect(y: 0.68, anchor: .center)
            } else {
                Text(detail ?? " ")
                    .font(.caption)
                    .foregroundStyle(DashboardPalette.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DashboardPalette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DashboardPalette.stroke, lineWidth: 1)
        }
    }
}

private struct DashboardSurface<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(0.5)
                .foregroundStyle(DashboardPalette.muted)
            content
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(DashboardPalette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DashboardPalette.stroke, lineWidth: 1)
        }
    }
}

private struct DashboardDetailRow: View {
    let label: String
    let value: String
    var tint: Color = DashboardPalette.text

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(DashboardPalette.muted)
            Spacer(minLength: 10)
            Text(value)
                .foregroundStyle(tint)
                .lineLimit(1)
        }
        .font(.subheadline.monospacedDigit())
    }
}

private struct PollStatusPill: View {
    let lastPollAt: Date?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let status = pollStatus(at: context.date)
            HStack(spacing: 7) {
                Circle()
                    .fill(status.color)
                    .frame(width: 7, height: 7)
                Text(status.label)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(status.color)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(status.color.opacity(0.1), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(status.color.opacity(0.23), lineWidth: 1)
            }
        }
    }

    private func pollStatus(at now: Date) -> (label: String, color: Color) {
        guard let lastPollAt else { return ("INITIALIZING", .orange) }
        let age = max(0, Int(now.timeIntervalSince(lastPollAt)))
        if age < 5 {
            return ("SOCKETS LIVE  \(age)s", .green)
        }
        return ("STALE  \(age)s", .orange)
    }
}

private struct LiveTrafficPanel: View {
    let samples: [NetworkTerminalSample]
    let network: NetworkMetrics?

    private var averageReceived: Double {
        guard !samples.isEmpty else { return 0 }
        return samples.map(\.metrics.receivedBytesPerSecond).reduce(0, +) / Double(samples.count)
    }

    private var averageSent: Double {
        guard !samples.isEmpty else { return 0 }
        return samples.map(\.metrics.sentBytesPerSecond).reduce(0, +) / Double(samples.count)
    }

    private var peakReceived: Double {
        samples.map(\.metrics.receivedBytesPerSecond).max() ?? 0
    }

    private var peakSent: Double {
        samples.map(\.metrics.sentBytesPerSecond).max() ?? 0
    }

    var body: some View {
        DashboardSurface(title: "LIVE NETWORK SPEED", systemImage: "waveform.path.ecg") {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                TrafficReading(
                    label: "DOWN",
                    value: formattedRate(network?.receivedBytesPerSecond ?? 0),
                    color: .green
                )
                TrafficReading(
                    label: "UP",
                    value: formattedRate(network?.sentBytesPerSecond ?? 0),
                    color: .cyan
                )
                TrafficReading(
                    label: "LATENCY",
                    value: formattedLatency(network?.latencyMilliseconds),
                    color: .orange
                )
            }

            OperationsThroughputPlot(samples: samples)
                .frame(height: 98)

            HStack(spacing: 15) {
                PlotLegend(label: "RX", color: .green)
                PlotLegend(label: "TX", color: .cyan)
                Spacer()
                Text("sample ~0.75 s")
                    .font(.caption2.monospaced())
                    .foregroundStyle(DashboardPalette.subtle)
            }

            HStack(spacing: 10) {
                TrafficStatistic(label: "AVG RX", value: formattedRate(averageReceived), color: .green)
                TrafficStatistic(label: "AVG TX", value: formattedRate(averageSent), color: .cyan)
            }
            HStack(spacing: 10) {
                TrafficStatistic(label: "PEAK RX", value: formattedRate(peakReceived), color: .green)
                TrafficStatistic(label: "PEAK TX", value: formattedRate(peakSent), color: .cyan)
            }

            Text("Latency: HTTPS response probe to cp.cloudflare.com, refreshed at most every 5 seconds.")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(DashboardPalette.subtle)
        }
    }
}

private struct TrafficStatistic: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Text(label)
                .foregroundStyle(color.opacity(0.78))
            Text(value)
                .foregroundStyle(DashboardPalette.muted)
        }
        .font(.system(size: 9, design: .monospaced))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TrafficReading: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(color.opacity(0.85))
            Text(value)
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .foregroundStyle(DashboardPalette.text)
        }
    }
}

private struct PlotLegend: View {
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Capsule()
                .fill(color)
                .frame(width: 14, height: 2)
            Text(label)
        }
        .font(.caption2.monospaced())
        .foregroundStyle(DashboardPalette.muted)
    }
}

private struct OperationsThroughputPlot: View {
    let samples: [NetworkTerminalSample]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(DashboardPalette.console)

                VStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { _ in
                        Divider().overlay(DashboardPalette.stroke)
                        Spacer()
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)

                trace(
                    samples.map { $0.metrics.receivedBytesPerSecond },
                    color: .green,
                    size: geometry.size
                )
                trace(
                    samples.map { $0.metrics.sentBytesPerSecond },
                    color: .cyan,
                    size: geometry.size
                )
            }
        }
    }

    private func trace(_ values: [Double], color: Color, size: CGSize) -> some View {
        let maximum = max(
            samples.flatMap { [$0.metrics.receivedBytesPerSecond, $0.metrics.sentBytesPerSecond] }.max() ?? 0,
            1
        )
        return Path { path in
            for (index, value) in values.enumerated() {
                let x = values.count < 2
                    ? size.width - 10
                    : 10 + (size.width - 20) * CGFloat(index) / CGFloat(values.count - 1)
                let y = size.height - 10 - ((size.height - 20) * CGFloat(value / maximum))
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(color, style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
    }
}

private struct SocketConsolePanel: View {
    let connections: [VisibleSocket]
    let events: [NetworkActivityEvent]
    let lastPollAt: Date?
    let network: NetworkMetrics?
    let interfaceName: String?
    @Binding var scope: SocketScope
    @Binding var query: String
    let onSelectSocket: (VisibleSocket) -> Void
    let onSelectEvent: (NetworkActivityEvent) -> Void

    private var establishedCount: Int {
        connections.filter { $0.state == .established }.count
    }

    private var listenerCount: Int {
        connections.filter { $0.state == .listening }.count
    }

    private var udpCount: Int {
        connections.filter { $0.transport == .udp }.count
    }

    private var filteredConnections: [VisibleSocket] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return connections.filter { connection in
            guard scope.includes(connection) else { return false }
            guard !trimmed.isEmpty else { return true }
            return connection.processName.localizedCaseInsensitiveContains(trimmed)
                || String(connection.pid).contains(trimmed)
                || connection.localEndpoint.localizedCaseInsensitiveContains(trimmed)
                || (connection.remoteEndpoint?.localizedCaseInsensitiveContains(trimmed) ?? false)
                || connection.serviceHint.label.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            consoleHeader
            sourceStrip
            controls

            HStack(spacing: 0) {
                SocketTable(connections: filteredConnections, onSelect: onSelectSocket)
                Rectangle()
                    .fill(DashboardPalette.stroke)
                    .frame(width: 1)
                SocketActivityStream(events: events, onSelect: onSelectEvent)
                    .frame(width: 306)
            }
            .frame(maxHeight: .infinity)

            HStack {
                Text("PORT MAP uses well-known ports; HEURISTIC uses process + port. No packet inspection. Direction is not inferred.")
                Spacer()
                Text("\(events.count) events buffered  |  \(filteredConnections.count) sockets displayed")
            }
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(DashboardPalette.subtle)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(DashboardPalette.consoleElevated.opacity(0.55))
        }
        .background(DashboardPalette.console, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(DashboardPalette.stroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private var consoleHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CONNECTION CONSOLE")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .tracking(0.5)
                    .foregroundStyle(DashboardPalette.text)
                Text("Visible TCP/UDP sockets with explicitly inferred service labels")
                    .font(.caption)
                    .foregroundStyle(DashboardPalette.muted)
            }
            Spacer()

            ConsoleCounter(label: "ESTABLISHED", value: establishedCount, tint: .green)
            ConsoleCounter(label: "LISTEN", value: listenerCount, tint: .cyan)
            ConsoleCounter(label: "UDP", value: udpCount, tint: .orange)
            PollStatusPill(lastPollAt: lastPollAt)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(DashboardPalette.consoleElevated)
    }

    private var sourceStrip: some View {
        HStack(spacing: 10) {
            Text("$")
                .foregroundStyle(.green)
            Text("/usr/sbin/lsof  TCP:ESTABLISHED,LISTEN + UDP endpoints")
                .foregroundStyle(DashboardPalette.text.opacity(0.85))
            Spacer(minLength: 10)
            Text("RX \(formattedRate(network?.receivedBytesPerSecond ?? 0))")
                .foregroundStyle(.green)
            Text("TX \(formattedRate(network?.sentBytesPerSecond ?? 0))")
                .foregroundStyle(.cyan)
            Text("LAT \(formattedLatency(network?.latencyMilliseconds))")
                .foregroundStyle(.orange)
            Text("|")
            Text("poll <1 s")
            Text("|")
            Text("if \(interfaceName ?? "--")")
        }
        .font(.system(size: 11, weight: .regular, design: .monospaced))
        .foregroundStyle(DashboardPalette.muted)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.18))
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Picker("State", selection: $scope) {
                ForEach(SocketScope.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 266)

            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DashboardPalette.subtle)
                TextField("Filter process, PID or endpoint", text: $query)
                    .textFieldStyle(.plain)
                    .foregroundStyle(DashboardPalette.text)
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .frame(height: 29)
            .background(DashboardPalette.consoleElevated, in: RoundedRectangle(cornerRadius: 7, style: .continuous))

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DashboardPalette.stroke)
                .frame(height: 1)
        }
    }
}

private struct ConsoleCounter: View {
    let label: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(DashboardPalette.muted)
            Text("\(value)")
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

private struct SocketTable: View {
    let connections: [VisibleSocket]
    let onSelect: (VisibleSocket) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ConsoleColumnTitle("PROTO", width: 48)
                ConsoleColumnTitle("STATE", width: 76)
                ConsoleColumnTitle("PID", width: 54)
                ConsoleColumnTitle("PROCESS", width: 88)
                ConsoleColumnTitle("SERVICE", width: 108)
                ConsoleColumnTitle("LOCAL ENDPOINT")
                ConsoleColumnTitle("PEER ENDPOINT")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(DashboardPalette.consoleElevated.opacity(0.5))

            if connections.isEmpty {
                VStack(spacing: 9) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title3)
                        .foregroundStyle(DashboardPalette.subtle)
                    Text("No sockets match the current filter")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(DashboardPalette.muted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(connections) { connection in
                            Button {
                                onSelect(connection)
                            } label: {
                                SocketTableRow(connection: connection)
                            }
                            .buttonStyle(.plain)
                            Rectangle()
                                .fill(DashboardPalette.stroke.opacity(0.65))
                                .frame(height: 1)
                        }
                    }
                }
            }
        }
    }
}

private struct ConsoleColumnTitle: View {
    let title: String
    var width: CGFloat?

    init(_ title: String, width: CGFloat? = nil) {
        self.title = title
        self.width = width
    }

    var body: some View {
        Text(title)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .tracking(0.25)
            .foregroundStyle(DashboardPalette.subtle)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}

private struct SocketTableRow: View {
    let connection: VisibleSocket

    var body: some View {
        HStack(spacing: 10) {
            Text(connection.transport.rawValue)
                .foregroundStyle(connection.transport == .tcp ? .cyan : .orange)
                .frame(width: 48, alignment: .leading)
            Text(connection.state.rawValue)
                .foregroundStyle(stateColor)
                .frame(width: 76, alignment: .leading)
            Text("\(connection.pid)")
                .foregroundStyle(DashboardPalette.muted)
                .frame(width: 54, alignment: .leading)
            Text(connection.processName)
                .foregroundStyle(DashboardPalette.text)
                .frame(width: 88, alignment: .leading)
                .lineLimit(1)
            Text(connection.serviceHint.label)
                .foregroundStyle(serviceColor)
                .frame(width: 108, alignment: .leading)
                .lineLimit(1)
            Text(connection.localEndpoint)
                .foregroundStyle(DashboardPalette.text.opacity(0.82))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.middle)
            Text(connection.remoteEndpoint ?? "-")
                .foregroundStyle(connection.remoteEndpoint == nil ? DashboardPalette.subtle : DashboardPalette.text.opacity(0.82))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.system(size: 11, weight: .regular, design: .monospaced))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var stateColor: Color {
        switch connection.state {
        case .established: return .green
        case .listening: return .cyan
        case .datagram: return .orange
        }
    }

    private var serviceColor: Color {
        switch connection.serviceHint.confidence {
        case .portMapped: return .mint
        case .heuristic: return .yellow
        case .unclassified: return DashboardPalette.subtle
        }
    }
}

private struct SocketActivityStream: View {
    let events: [NetworkActivityEvent]
    let onSelect: (NetworkActivityEvent) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("EVENT STREAM")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(0.25)
                    .foregroundStyle(DashboardPalette.subtle)
                Spacer()
                Text("newest first")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(DashboardPalette.subtle)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .background(DashboardPalette.consoleElevated.opacity(0.5))

            if events.isEmpty {
                Text("Awaiting socket transitions...")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(DashboardPalette.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(events) { event in
                            Button {
                                onSelect(event)
                            } label: {
                                SocketEventRow(event: event)
                            }
                            .buttonStyle(.plain)
                            Rectangle()
                                .fill(DashboardPalette.stroke.opacity(0.65))
                                .frame(height: 1)
                        }
                    }
                }
            }
        }
        .background(DashboardPalette.console.opacity(0.6))
    }
}

private struct SocketEventRow: View {
    let event: NetworkActivityEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(event.timestamp.formatted(date: .omitted, time: .standard))
                    .foregroundStyle(DashboardPalette.subtle)
                Text(event.action.rawValue)
                    .fontWeight(.semibold)
                    .foregroundStyle(actionColor)
                Text(event.transport.rawValue)
                    .foregroundStyle(event.transport == .tcp ? .cyan : .orange)
                Spacer()
                Text("pid \(event.pid)")
                    .foregroundStyle(DashboardPalette.subtle)
            }
            HStack {
                Text(event.processName)
                    .foregroundStyle(DashboardPalette.text)
                Spacer()
                Text(event.serviceHint.label)
                    .foregroundStyle(serviceColor)
                Text(event.serviceHint.confidence.rawValue)
                    .foregroundStyle(DashboardPalette.subtle)
            }
            Text(endpointDescription)
                .foregroundStyle(DashboardPalette.muted)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.system(size: 10, weight: .regular, design: .monospaced))
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
    }

    private var endpointDescription: String {
        guard let remote = event.remoteEndpoint else { return event.localEndpoint }
        return "\(event.localEndpoint) -> \(remote)"
    }

    private var actionColor: Color {
        switch event.action {
        case .observed: return .green
        case .opened: return .cyan
        case .closed: return .yellow
        case .listening: return .mint
        case .stoppedListening: return .orange
        }
    }

    private var serviceColor: Color {
        switch event.serviceHint.confidence {
        case .portMapped: return .mint
        case .heuristic: return .yellow
        case .unclassified: return DashboardPalette.subtle
        }
    }
}

private struct NetworkRecordDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let record: NetworkRecordSelection
    let context: SocketInspectorContext

    private var headerEyebrow: String {
        switch record {
        case .socket: "SOCKET INSPECTOR"
        case .event: "ACTIVITY INSPECTOR"
        }
    }

    private var headerTitle: String {
        switch record {
        case .socket(let socket):
            URL(fileURLWithPath: socket.processName).lastPathComponent
        case .event(let event):
            URL(fileURLWithPath: event.processName).lastPathComponent
        }
    }

    private var headerSubtitle: String {
        switch record {
        case .socket(let socket):
            "pid \(socket.pid) · \(socket.transport.rawValue) · \(socket.state.rawValue)"
        case .event(let event):
            "\(event.action.rawValue) · \(event.timestamp.formatted(date: .omitted, time: .standard))"
        }
    }

    private var serviceHint: SocketServiceHint {
        switch record {
        case .socket(let socket): return socket.serviceHint
        case .event(let event): return event.serviceHint
        }
    }

    private var presentationRows: [SocketInspectorRow] {
        switch record {
        case .socket(let socket):
            SocketInspectorPresentation.rows(for: socket, context: context)
        case .event(let event):
            SocketInspectorPresentation.rows(for: event, context: context)
        }
    }

    private var summaryBadges: [SocketInspectorSummaryBadge] {
        switch record {
        case .socket(let socket):
            SocketInspectorPresentation.summaryBadges(for: socket)
        case .event(let event):
            SocketInspectorPresentation.summaryBadges(for: event)
        }
    }

    private var flowKind: SocketHostFlowKind {
        switch record {
        case .socket(let socket):
            SocketInspectorPresentation.flowPerspective(for: socket).kind
        case .event(let event):
            SocketInspectorPresentation.flowPerspective(for: event).kind
        }
    }

    var body: some View {
        ZStack {
            WindowMaterialBackground()
                .ignoresSafeArea()
            DashboardPalette.canvas
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(headerEyebrow)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .tracking(0.8)
                            .foregroundStyle(DashboardPalette.muted)
                        Text(headerTitle)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(DashboardPalette.text)
                        Text(headerSubtitle)
                            .font(.caption.monospaced())
                            .foregroundStyle(DashboardPalette.subtle)
                    }
                    Spacer()
                    Text(serviceHint.label == "UNCLASSIFIED" ? "No mapping" : serviceHint.label)
                        .font(.headline.monospaced())
                        .foregroundStyle(serviceColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(serviceColor.opacity(0.12), in: Capsule())
                }

                inspectorSummaryStrip

                ScrollView {
                    DashboardSurface(title: "OBSERVABLE FLOW METADATA", systemImage: "tablecells") {
                        ForEach(presentationRows) { row in
                            detailRow(row.title, row.value, highlighted: row.isHighlighted)
                        }
                    }

                    DashboardSurface(title: "PACKET INSPECTION BOUNDARY", systemImage: "lock.shield") {
                        ForEach(SocketInspectorPresentation.boundaryNotes) { note in
                            detailRow(note.title, note.value)
                        }
                        Text(SocketInspectorPresentation.boundaryFooter)
                            .font(.caption)
                            .foregroundStyle(DashboardPalette.muted)
                    }
                }

                HStack {
                    Text("Select another socket or activity row to compare records.")
                        .font(.caption)
                        .foregroundStyle(DashboardPalette.subtle)
                    Spacer()
                    Button("Done") { dismiss() }
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(22)
        }
        .frame(width: 660, height: 620)
        .preferredColorScheme(.dark)
    }

    private var inspectorSummaryStrip: some View {
        HStack(spacing: 8) {
            ForEach(summaryBadges) { badge in
                VStack(spacing: 4) {
                    Text(badge.label)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(DashboardPalette.muted)
                    Text(badge.value)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(summaryBadgeColor(label: badge.label))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 6)
                .background(DashboardPalette.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private func summaryBadgeColor(label: String) -> Color {
        switch label {
        case "FLOW":
            switch flowKind {
            case .inbound, .inboundReady: return .mint
            case .outbound: return .cyan
            case .bidirectional: return .yellow
            case .undetermined: return DashboardPalette.subtle
            }
        case "STATE":
            return .mint
        case "SERVICE":
            return serviceColor
        default:
            return DashboardPalette.text
        }
    }

    private func detailRow(_ label: String, _ value: String, highlighted: Bool = false) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(DashboardPalette.muted)
                .frame(width: 148, alignment: .leading)
            Text(value)
                .foregroundStyle(highlighted ? serviceColor : DashboardPalette.text)
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
        .font(.subheadline.monospaced())
    }

    private var serviceColor: Color {
        switch serviceHint.confidence {
        case .portMapped: return .mint
        case .heuristic: return .yellow
        case .unclassified: return DashboardPalette.muted
        }
    }
}

private func formattedRate(_ bytesPerSecond: Double) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB]
    formatter.countStyle = .decimal
    formatter.includesUnit = true
    return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
}

private func formattedLatency(_ milliseconds: Double?) -> String {
    guard let milliseconds else { return "-- ms" }
    return "\(Int(milliseconds.rounded())) ms"
}
