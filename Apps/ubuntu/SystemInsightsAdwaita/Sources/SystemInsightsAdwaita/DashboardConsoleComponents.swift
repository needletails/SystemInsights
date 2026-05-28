import Adwaita
import Foundation
import SystemInsightCore

struct DashboardOperationsHeader: View {
    let snapshot: InsightSnapshot
    let lastPollAt: Date?
    let isCollecting: Bool
    let onScan: () -> Void

    var view: Body {
        HStack(spacing: 12) {
            HStack(spacing: 14) {
                Box {
                    Text(OperationsGlyphs.symbolForHealthRating(snapshot.rating))
                        .style("operations-rating-glyph")
                        .success(snapshot.rating == .good)
                        .warning(snapshot.rating == .warning)
                        .error(snapshot.rating == .critical)
                        .halign(.center)
                        .valign(.center)
                }
                .frame(minWidth: 44, minHeight: 44)
                .style("operations-header-icon-slot")

                VStack {
                    Text("SYSTEM INSIGHTS")
                        .caption()
                        .monospace()
                        .style("operations-eyebrow")
                        .dimLabel()
                    Text("Network Operations")
                        .title2()
                        .halign(.start)
                    Text("Sampled \(DashboardFormatting.relativeTime(since: snapshot.generatedAt))")
                        .caption()
                        .dimLabel()
                        .halign(.start)
                }
                .halign(.start)
            }
            .style("operations-header-cluster")

            Box { }
                .hexpand()

            HStack(spacing: 10) {
                PollStatusPill(lastPollAt: lastPollAt)
                HealthScoreCard(snapshot: snapshot)
                Button(isCollecting ? "Scanning…" : "Scan Now") {
                    UIViewDeferral.run { onScan() }
                }
                .pill()
                .suggested()
            }
            .style("operations-header-trailing")
        }
        .valign(.center)
        .style("operations-header-bar")
        .style("operations-surface")
    }
}

struct HealthScoreCard: View {
    let snapshot: InsightSnapshot

    var view: Body {
        VStack {
            Text(DashboardFormatting.ratingLabel(snapshot.rating).uppercased())
                .caption()
                .monospace()
                .success(snapshot.rating == .good)
                .warning(snapshot.rating == .warning)
                .error(snapshot.rating == .critical)
                .halign(.center)
            HStack(spacing: 8) {
                Text("\(snapshot.score)")
                    .title1()
                    .numeric()
                    .style("operations-score-primary")
                Text("/ 100")
                    .caption()
                    .dimLabel()
                    .style("operations-score-suffix")
            }
            .valign(.center)
            .style("operations-score-value-row")
        }
        .style("operations-score-card")
        .style("operations-surface")
    }
}

struct PollStatusPill: View {
    let lastPollAt: Date?

    var view: Body {
        let status = pollStatus
        HStack(spacing: 12) {
            Text("●")
                .success(status.live)
                .warning(!status.live)
            Text(status.label)
                .caption()
                .monospace()
                .success(status.live)
                .warning(!status.live)
        }
        .style("operations-poll-pill")
        .style("operations-surface")
    }

    private var pollStatus: (label: String, live: Bool) {
        guard let lastPollAt else {
            return ("INITIALIZING", false)
        }
        let age = max(0, Int(Date().timeIntervalSince(lastPollAt)))
        if age < 5 {
            return ("SOCKETS LIVE  \(age)s", true)
        }
        return ("STALE  \(age)s", false)
    }
}

struct DashboardMetricsStrip: View {
    let snapshot: InsightSnapshot
    let socketCount: Int

    var view: Body {
        HStack(spacing: 12) {
            TelemetryTile(
                title: "CPU LOAD",
                value: DashboardFormatting.percent(snapshot.metrics.cpuLoadPercent),
                icon: .default(icon: .applicationsSystem),
                accentClass: "metric-accent-cpu",
                meter: snapshot.metrics.cpuLoadPercent
            )
            TelemetryTile(
                title: "MEMORY PRESSURE",
                value: DashboardFormatting.percent(snapshot.metrics.memoryPressurePercent),
                icon: .default(icon: .applicationsUtilities),
                accentClass: "metric-accent-memory",
                meter: snapshot.metrics.memoryPressurePercent
            )
            TelemetryTile(
                title: "DISK UTILIZED",
                value: DashboardFormatting.percent(snapshot.metrics.diskUsagePercent),
                icon: .default(icon: .driveHarddisk),
                accentClass: "metric-accent-disk",
                meter: snapshot.metrics.diskUsagePercent
            )
            TelemetryTile(
                title: "VISIBLE SOCKETS",
                value: "\(socketCount)",
                icon: .default(icon: .networkTransmitReceive),
                accentClass: "metric-accent-sockets",
                meter: nil,
                detail: "TCP + UDP observed"
            )
        }
        .style("operations-metrics-strip")
        .style("operations-section-gap")
    }
}

struct TelemetryTile: View {
    let title: String
    let value: String
    let icon: Icon
    let accentClass: String
    var meter: Double?
    var detail: String?

    var view: Body {
        VStack {
            HStack {
                Text(title)
                    .caption()
                    .monospace()
                    .dimLabel()
                Box { }
                    .hexpand()
                OperationsIcon(icon: icon, size: 20)
            }
            .hexpand()
            .halign(.fill)
            Text(value)
                .ellipsize()
                .title1()
                .numeric()
                .halign(.start)
                .style("operations-metric-value")
            if let meter {
                LevelBar()
                    .value(meter)
                    .minValue(0)
                    .maxValue(100)
                    .style("operations-metric-meter")
            } else if let detail {
                Text(detail)
                    .ellipsize()
                    .caption()
                    .dimLabel()
                    .halign(.start)
            }
        }
        .halign(.fill)
        .hexpand()
        .frame(maxHeight: 96)
        .style("operations-metric-tile-inner")
        .style("operations-surface")
        .style("operations-metric-tile")
        .style(accentClass)
    }
}

struct DashboardSurfaceHeader: View {
    let title: String
    let icon: Icon

    var view: Body {
        HStack(spacing: 10) {
            Box {
                OperationsIcon(icon: icon, size: 16)
            }
            .frame(minWidth: 22, minHeight: 22)
            .style("operations-surface-header-icon")
            Text(title)
                .caption()
                .monospace()
                .style("operations-eyebrow")
                .dimLabel()
                .valign(.center)
        }
        .valign(.center)
        .halign(.start)
        .style("operations-surface-header")
    }
}

struct DashboardSurface: View {
    let title: String
    let icon: Icon
    @ViewBuilder let content: () -> Body

    var view: Body {
        VStack {
            DashboardSurfaceHeader(title: title, icon: icon)
            Box {
                content()
            }
            .style("operations-surface-body")
        }
        .style("operations-surface")
    }
}

struct DashboardDetailRow: View {
    let label: String
    let value: String
    var accent: Bool = false

    var view: Body {
        HStack {
            Text(label)
                .caption()
                .dimLabel()
                .frame(minWidth: DashboardLayout.detailLabelWidth)
            Text(value)
                .ellipsize()
                .caption()
                .monospace()
                .numeric()
                .accent(accent)
                .hexpand()
                .halign(.end)
        }
        .style("operations-detail-row")
    }
}

enum DashboardLayout {
    static let detailLabelWidth = 108
}

struct LiveTrafficPanel: View {
    let network: NetworkMetrics
    let speedSamples: [NetworkMetrics]

    var view: Body {
        DashboardSurface(title: "LIVE NETWORK SPEED", icon: .default(icon: .networkTransmitReceive)) {
            HStack {
                TrafficReading(
                    label: "DOWN",
                    value: DashboardFormatting.rate(network.receivedBytesPerSecond),
                    accentClass: "traffic-down"
                )
                TrafficReading(
                    label: "UP",
                    value: DashboardFormatting.rate(network.sentBytesPerSecond),
                    accentClass: "traffic-up"
                )
                TrafficReading(
                    label: "LATENCY",
                    value: DashboardFormatting.latency(network.latencyMilliseconds),
                    accentClass: "traffic-latency"
                )
            }
            .style("operations-traffic-readings")

            ThroughputSparkline(samples: speedSamples)

            HStack {
                PlotLegend(label: "RX", accentClass: "traffic-down")
                PlotLegend(label: "TX", accentClass: "traffic-up")
                Box { }
                    .hexpand()
                VStack {
                    Text("avg RX \(DashboardFormatting.rate(DashboardFormatting.averageReceived(speedSamples)))")
                        .caption()
                        .monospace()
                        .dimLabel()
                    Text("peak RX \(DashboardFormatting.rate(DashboardFormatting.peakReceived(speedSamples)))")
                        .caption()
                        .monospace()
                        .dimLabel()
                }
                .halign(.end)
            }
            .style("operations-sparkline-legend")
        }
    }
}

struct TrafficReading: View {
    let label: String
    let value: String
    let accentClass: String

    var view: Body {
        VStack {
            Text(label)
                .caption()
                .monospace()
                .dimLabel()
            Text(value)
                .title3()
                .numeric()
                .halign(.start)
        }
        .hexpand()
        .style("operations-traffic-reading")
        .style(accentClass)
    }
}

struct PlotLegend: View {
    let label: String
    let accentClass: String

    var view: Body {
        HStack {
            Text("■")
                .caption()
            Text(label)
                .caption()
                .monospace()
        }
        .style(accentClass)
        .padding(6)
    }
}

struct ThroughputSparkline: View {
    let samples: [NetworkMetrics]

    var view: Body {
        VStack {
            Text(rxSparkline)
                .monospace()
                .caption()
                .success()
            Text(txSparkline)
                .monospace()
                .caption()
                .accent()
        }
        .halign(.start)
        .hexpand()
        .style("operations-sparkline")
    }

    private var rxSparkline: String {
        sparkline(samples.map(\.receivedBytesPerSecond), prefix: "RX ")
    }

    private var txSparkline: String {
        sparkline(samples.map(\.sentBytesPerSecond), prefix: "TX ")
    }

    private func sparkline(_ values: [Double], prefix: String) -> String {
        guard !values.isEmpty else { return "\(prefix)▁▁▁▁▁▁▁▁ waiting…" }
        let maximum = max(values.max() ?? 0, 1)
        let blocks = "▁▂▃▄▅▆▇█"
        let rendered = values.suffix(24).map { value -> Character in
            let index = min(blocks.count - 1, Int((value / maximum) * Double(blocks.count - 1)))
            return blocks[blocks.index(blocks.startIndex, offsetBy: index)]
        }
        return prefix + String(rendered)
    }
}

struct SocketConsolePanel: View {
    let searchIndex: [SocketConsoleFilter.IndexEntry]
    let events: [NetworkActivityEvent]
    let lastPollAt: Date?
    let network: NetworkMetrics?
    let interfaceName: String?
    let onSelectSocket: (VisibleSocket) -> Void
    let onSelectEvent: (NetworkActivityEvent) -> Void

    /// Local filter state so typing does not rebuild the full dashboard tree.
    @State private var filterScope = SocketScope.all
    @State private var filterQuery = ""

    private var allConnections: [VisibleSocket] {
        searchIndex.map(\.socket)
    }

    private var filteredEntries: [SocketConsoleFilter.IndexEntry] {
        SocketConsoleFilter.apply(index: searchIndex, scope: filterScope, query: filterQuery)
    }

    private var footerStatus: String {
        "\(events.count) events buffered  ·  \(filteredEntries.count) sockets displayed  ·  \(DashboardFormatting.pollText(lastPollAt))"
    }

    var view: Body {
        VStack {
            HStack {
                VStack {
                    Text("CONNECTION CONSOLE")
                        .heading()
                        .monospace()
                    Text("Live TCP/UDP ownership with inferred service labels. Select a row to inspect.")
                        .caption()
                        .dimLabel()
                }
                .halign(.start)
                Box { }
                    .hexpand()
                HStack {
                    ConsoleCounter(
                        label: "ESTABLISHED",
                        value: DashboardFormatting.establishedCount(allConnections),
                        live: true
                    )
                    ConsoleCounter(
                        label: "LISTEN",
                        value: DashboardFormatting.listenerCount(allConnections),
                        live: false
                    )
                    ConsoleCounter(
                        label: "UDP",
                        value: DashboardFormatting.udpCount(allConnections),
                        live: false
                    )
                }
                .style("operations-console-counters")
            }
            .style("operations-console-header")

            HStack(spacing: 10) {
                Text("$ /usr/sbin/lsof  TCP:ESTABLISHED,LISTEN + UDP")
                    .caption()
                    .monospace()
                    .success()
                Box { }
                    .hexpand()
                Text("RX \(DashboardFormatting.rate(network?.receivedBytesPerSecond ?? 0))")
                    .caption()
                    .monospace()
                    .success()
                Text("TX \(DashboardFormatting.rate(network?.sentBytesPerSecond ?? 0))")
                    .caption()
                    .monospace()
                    .accent()
                Text("LAT \(DashboardFormatting.latency(network?.latencyMilliseconds))")
                    .caption()
                    .monospace()
                    .warning()
                Text("if \(interfaceName ?? "--")")
                    .caption()
                    .monospace()
                    .dimLabel()
            }
            .style("operations-console-strip")

            HStack(spacing: 12) {
                ToggleGroup(
                    selection: Binding(
                        get: { filterScope.id },
                        set: { newID in
                            guard let scope = SocketScope(rawValue: newID), scope != filterScope else {
                                return
                            }
                            UIViewDeferral.run {
                                filterScope = scope
                            }
                        }
                    ),
                    values: SocketScope.allCases
                )
                .hexpand(false)
                .frame(maxWidth: 266)
                ConsoleSearchField(query: $filterQuery)
                    .style("operations-console-search-slot")
                    .hexpand()
            }
            .style("operations-console-controls")

            HStack {
                VStack {
                    Text("SOCKETS")
                        .caption()
                        .monospace()
                        .style("operations-table-panel-title")
                    SocketTableHeader()
                    ScrollView {
                        VStack {
                            if filteredEntries.isEmpty {
                                Text("No sockets match the current filter.")
                                    .caption()
                                    .dimLabel()
                                    .padding(16)
                            } else {
                                ForEach(Array(filteredEntries.prefix(NetworkSamplingLimits.maxConsoleSocketRows))) { entry in
                                    SocketTableRow(socket: entry.socket, serviceLabel: entry.serviceLabel) {
                                        onSelectSocket(entry.socket)
                                    }
                                }
                            }
                        }
                    }
                    .vexpand()
                }
                .style("operations-table-panel")
                .style("operations-table-panel-sockets")
                .hexpand()

                Box { }
                    .frame(minWidth: 1)
                    .style("operations-table-divider")

                VStack {
                    Text("EVENT STREAM")
                        .caption()
                        .monospace()
                        .style("operations-table-panel-title")
                    ActivityTableHeader()
                    ScrollView {
                        VStack {
                            if events.isEmpty {
                                Text("Waiting for socket transitions…")
                                    .caption()
                                    .dimLabel()
                                    .padding(16)
                            } else {
                                ForEach(Array(events.prefix(NetworkSamplingLimits.maxConsoleActivityRows))) { event in
                                    ActivityTableRow(event: event) {
                                        onSelectEvent(event)
                                    }
                                }
                            }
                        }
                    }
                    .vexpand()
                }
                .style("operations-table-panel")
                .style("operations-table-panel-activity")
                .frame(minWidth: ConsoleTableLayout.activityPanelWidth)
                .frame(maxWidth: ConsoleTableLayout.activityPanelWidth)
            }
            .style("operations-console-table-area")

            Text(footerStatus)
                .caption()
                .monospace()
                .dimLabel()
                .halign(.center)
                .style("operations-console-footer")
        }
        .hexpand()
        .style("operations-console")
    }
}

struct ConsoleCounter: View {
    let label: String
    let value: Int
    let live: Bool

    var view: Body {
        VStack {
            Text(label)
                .caption()
                .monospace()
                .dimLabel()
            Text("\(value)")
                .title3()
                .numeric()
                .success(live && value > 0)
                .accent(!live && value > 0)
        }
        .style("operations-console-counter")
        .halign(.center)
    }
}

struct ExposureWatchPanel: View {
    let sockets: [VisibleSocket]
    let recentActivity: [NetworkActivityEvent]

    var view: Body {
        DashboardSurface(title: "EXPOSURE WATCH", icon: .default(icon: .securityHigh)) {
            VStack {
                HStack {
                    SignalCount(label: "PUBLIC TCP", count: publicTCP, warning: true)
                    SignalCount(label: "BOUND UDP", count: boundUDP, warning: true)
                    SignalCount(label: "1 MIN EVENTS", count: recentTransitions, warning: false)
                }
                .padding()
                ScrollView {
                    VStack {
                        exposureRows
                    }
                }
                .frame(maxHeight: 160)
            }
        }
        .hexpand()
    }

    private var publicTCP: Int {
        sockets.filter { $0.transport == .tcp && DashboardFormatting.isExposedEndpoint($0.localEndpoint) }.count
    }

    private var boundUDP: Int {
        sockets.filter { $0.transport == .udp && DashboardFormatting.isExposedEndpoint($0.localEndpoint) }.count
    }

    private var recentTransitions: Int {
        let cutoff = Date().addingTimeInterval(-60)
        return recentActivity.filter { $0.timestamp >= cutoff }.count
    }

    private var exposedSockets: [VisibleSocket] {
        sockets.filter { DashboardFormatting.isExposedEndpoint($0.localEndpoint) }
    }

    @ViewBuilder
    private var exposureRows: Body {
        if exposedSockets.isEmpty {
            Text("No wildcard-bound endpoints in the current sample.")
                .caption()
                .dimLabel()
                .padding()
        } else {
            ForEach(Array(exposedSockets.prefix(6))) { socket in
                DashboardDetailRow(
                    label: socket.processName,
                    value: "\(socket.transport.rawValue) \(socket.localEndpoint)"
                )
            }
        }
    }
}

struct NetworkActorsPanel: View {
    let sockets: [VisibleSocket]

    var view: Body {
        DashboardSurface(title: "NETWORK ACTORS", icon: .default(icon: .systemUsers)) {
            ScrollView {
                VStack {
                    networkActorsContent
                }
            }
            .frame(maxHeight: 220)
        }
        .hexpand()
    }

    private var actors: [NetworkActorSummary] {
        Array(DashboardFormatting.networkActors(sockets).prefix(8))
    }

    @ViewBuilder
    private var networkActorsContent: Body {
        if actors.isEmpty {
            Text("No peer-addressed sockets in the current sample.")
                .caption()
                .dimLabel()
                .padding()
        } else {
            ForEach(actors) { actor in
                DashboardDetailRow(
                    label: actor.processName,
                    value: "pid \(actor.pid) · \(actor.peerCount) peers · \(actor.tcpCount) TCP"
                )
            }
        }
    }
}

struct SignalCount: View {
    let label: String
    let count: Int
    let warning: Bool

    var view: Body {
        VStack {
            Text(label)
                .caption()
                .monospace()
                .dimLabel()
            Text("\(count)")
                .title3()
                .numeric()
                .warning(warning && count > 0)
                .success(!warning && count > 0)
        }
        .hexpand()
    }
}
