import SwiftUI
import SystemInsightCore
import WidgetKit

struct SystemInsightsEntry: TimelineEntry {
    let date: Date
    let snapshot: InsightSnapshot?
    let diagnostic: String
}

struct SystemInsightsProvider: TimelineProvider {
    func placeholder(in context: Context) -> SystemInsightsEntry {
        SystemInsightsEntry(date: Date(), snapshot: Self.previewSnapshot, diagnostic: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (SystemInsightsEntry) -> Void) {
        guard !context.isPreview else {
            completion(placeholder(in: context))
            return
        }
        completion(entry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SystemInsightsEntry>) -> Void) {
        let now = Date()
        let entry = entry(date: now)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func entry(date: Date) -> SystemInsightsEntry {
        let result = SharedWidgetConfiguration.readSnapshotWithDiagnostics()
        return SystemInsightsEntry(date: date, snapshot: result.snapshot, diagnostic: result.diagnostic)
    }

    private static let previewSnapshot = InsightSnapshot(
        generatedAt: Date(),
        host: HostIdentity(hostName: "Mac", platform: "macOS", operatingSystem: "macOS"),
        metrics: PerformanceMetrics(
            cpuLoadPercent: 24,
            memoryPressurePercent: 38,
            diskUsagePercent: 52,
            network: NetworkMetrics(
                interfaceName: "en0",
                receivedBytesPerSecond: 820_000,
                sentBytesPerSecond: 92_000,
                latencyMilliseconds: 23,
                activeTCPConnections: 8,
                vpn: VPNConnectivity(
                    state: .connected,
                    detail: "A configured VPN connection is active."
                )
            ),
            topProcesses: []
        ),
        securityFindings: [],
        issues: [],
        score: 96,
        rating: .good,
        recommendations: ["No immediate action needed."],
        topIssue: nil
    )
}

struct SystemInsightsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SystemInsightsEntry

    var body: some View {
        Link(destination: SharedWidgetConfiguration.dashboardURL) {
            content
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
            .containerBackground(for: .widget) {
                LinearGradient(
                    colors: [
                        Color(.sRGB, red: 0.12, green: 0.16, blue: 0.22, opacity: 1),
                        Color(.sRGB, red: 0.05, green: 0.07, blue: 0.10, opacity: 1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = entry.snapshot {
            snapshotContent(snapshot)
        } else {
            emptyContent
        }
    }

    private func snapshotContent(_ snapshot: InsightSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label(snapshot.rating.rawValue, systemImage: symbol(for: snapshot.rating))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color(for: snapshot.rating))
                Spacer()
                Text("Health \(snapshot.score)/100")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.white)
            }

            ProgressView(value: Double(snapshot.score), total: 100)
                .tint(color(for: snapshot.rating))

            networkSpeedPanel(snapshot.metrics.network, compact: family == .systemSmall)

            if family != .systemSmall {
                metricRow(snapshot.metrics)
            }

            if family == .systemLarge {
                Text(snapshot.topIssue?.title ?? "No action needed")
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(secondaryText)
            } else {
                Text("Tap for live console")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.cyan.opacity(0.9))
            }

            Text("Host sample \(snapshot.generatedAt.formatted(date: .omitted, time: .standard))")
                .font(.caption2)
                .foregroundStyle(secondaryText)

            if !entry.diagnostic.isEmpty, entry.diagnostic != "Read OK" {
                Text(entry.diagnostic)
                    .font(.caption2)
                    .lineLimit(2)
                    .foregroundStyle(secondaryText)
            }

            if family == .systemLarge {
                networkActivityPanel(snapshot.networkActivity)
            }

            if family == .systemLarge, let event = snapshot.securityEvents.first {
                Divider()
                Text("Security Activity")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(secondaryText)
                Text(event.message)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(.white)
            }
        }
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No Live Snapshot", systemImage: "shield.slash")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Run the signed app with shared widget access enabled.")
                .font(.caption)
                .foregroundStyle(secondaryText)
            if !entry.diagnostic.isEmpty {
                Text(entry.diagnostic)
                    .font(.caption2)
                    .lineLimit(3)
                    .foregroundStyle(secondaryText)
            }
        }
    }

    private func metricRow(_ metrics: PerformanceMetrics) -> some View {
        HStack {
            metric("CPU", metrics.cpuLoadPercent)
            metric("Memory", metrics.memoryPressurePercent)
            metric("Disk", metrics.diskUsagePercent)
        }
    }

    private func networkSpeedPanel(_ network: NetworkMetrics, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("NETWORK SPEED")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(0.3)
                    .foregroundStyle(.white.opacity(0.64))
                Spacer()
                Text(network.interfaceName ?? "--")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.52))
            }

            HStack(spacing: compact ? 12 : 20) {
                speedReading("DOWN", rate(network.receivedBytesPerSecond), color: .green)
                speedReading("UP", rate(network.sentBytesPerSecond), color: .cyan)
                if !compact {
                    speedReading("LATENCY", latency(network.latencyMilliseconds), color: .orange)
                }
            }
            if compact {
                HStack {
                    speedReading("LATENCY", latency(network.latencyMilliseconds), color: .orange)
                    Spacer()
                    Text("VPN \(vpnAbbreviation(network.vpn.state))")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(secondaryText)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }

    private func speedReading(_ name: String, _ value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(color.opacity(0.86))
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
        }
    }

    private func networkActivityPanel(_ events: [NetworkActivityEvent]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("SOCKET ACTIVITY")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                Spacer()
                Text(events.isEmpty ? "WAITING" : "PORT HINTS")
                    .font(.system(size: 9, design: .monospaced))
            }
            .foregroundStyle(Color.green.opacity(0.85))

            if events.isEmpty {
                Text("$ waiting for visible socket activity")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.green.opacity(0.7))
            } else {
                ForEach(Array(events.prefix(3))) { event in
                    HStack(spacing: 6) {
                        Text(event.action.rawValue)
                            .frame(width: 40, alignment: .leading)
                            .foregroundStyle(activityColor(event.action))
                        Text(event.transport.rawValue)
                            .frame(width: 28, alignment: .leading)
                            .foregroundStyle(event.transport == .tcp ? .cyan : .orange)
                        Text(event.processName)
                            .frame(width: 45, alignment: .leading)
                        Text(event.serviceHint.label)
                            .frame(width: 72, alignment: .leading)
                            .foregroundStyle(serviceColor(event.serviceHint.confidence))
                        Text(event.remoteEndpoint ?? event.localEndpoint)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.green.opacity(0.82))
                }
            }

            if !events.isEmpty {
                Text("PORT MAP = well-known port; HEURISTIC = process + port match.")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.52), in: RoundedRectangle(cornerRadius: 7))
    }

    private func activityColor(_ action: NetworkActivityAction) -> Color {
        switch action {
        case .observed: return .green
        case .opened: return .cyan
        case .closed: return .yellow
        case .listening: return .mint
        case .stoppedListening: return .orange
        }
    }

    private func serviceColor(_ confidence: SocketServiceConfidence) -> Color {
        switch confidence {
        case .portMapped: return .mint
        case .heuristic: return .yellow
        case .unclassified: return Color.white.opacity(0.52)
        }
    }

    private func metric(_ label: String, _ value: Double) -> some View {
        VStack(alignment: .leading) {
            Text(label).font(.caption2).foregroundStyle(secondaryText)
            Text("\(Int(value))%").font(.caption.monospacedDigit()).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var secondaryText: Color {
        Color.white.opacity(0.72)
    }

    private func symbol(for rating: HealthRating) -> String {
        switch rating {
        case .good: return "checkmark.shield.fill"
        case .warning: return "exclamationmark.shield.fill"
        case .critical: return "xmark.shield.fill"
        }
    }

    private func color(for rating: HealthRating) -> Color {
        switch rating {
        case .good: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }

    private func rate(_ bytesPerSecond: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .decimal
        return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
    }

    private func latency(_ milliseconds: Double?) -> String {
        guard let milliseconds else { return "-- ms" }
        return "\(Int(milliseconds.rounded())) ms"
    }

    private func vpnAbbreviation(_ state: VPNConnectionState) -> String {
        switch state {
        case .connected: return "On"
        case .tunnelDetected: return "Tunnel"
        case .notDetected: return "Off"
        case .unavailable: return "--"
        }
    }
}

struct SystemInsightsWidget: Widget {
    let kind = SharedWidgetConfiguration.kind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SystemInsightsProvider()) { entry in
            SystemInsightsWidgetView(entry: entry)
        }
        .configurationDisplayName("System Insights")
        .description("Your latest performance and security health snapshot.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct SystemInsightsWidgetBundle: WidgetBundle {
    var body: some Widget {
        SystemInsightsWidget()
    }
}
