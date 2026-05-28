import Adwaita
import Foundation
import SystemInsightCore

struct DashboardOperationsPage: View {
    let snapshot: InsightSnapshot
    let network: NetworkMetrics
    let speedSamples: [NetworkMetrics]
    let visibleSockets: [VisibleSocket]
    let socketSearchIndex: [SocketConsoleFilter.IndexEntry]
    let recentActivity: [NetworkActivityEvent]
    let lastSocketSampleAt: Date?
    let isCollecting: Bool
    let onScan: () -> Void
    let onSelectSocket: (VisibleSocket) -> Void
    let onSelectEvent: (NetworkActivityEvent) -> Void

    var view: Body {
        VStack {
            DashboardOperationsHeader(
                snapshot: snapshot,
                lastPollAt: lastSocketSampleAt,
                isCollecting: isCollecting,
                onScan: onScan
            )
            .style("operations-section-gap")

            DashboardMetricsStrip(snapshot: snapshot, socketCount: visibleSockets.count)

            HStack(spacing: 16) {
                VStack(spacing: 16) {
                    LiveTrafficPanel(network: network, speedSamples: speedSamples)
                        .style("operations-traffic-panel")
                    connectivityPanel
                    insightPanel
                }
                .style("operations-sidebar-column")
                .frame(minWidth: DashboardWindowLayout.sidebarWidth)
                .frame(maxWidth: DashboardWindowLayout.sidebarWidth)
                .halign(.fill)

                SocketConsolePanel(
                    searchIndex: socketSearchIndex,
                    events: recentActivity,
                    lastPollAt: lastSocketSampleAt,
                    network: network,
                    interfaceName: network.interfaceName,
                    onSelectSocket: onSelectSocket,
                    onSelectEvent: onSelectEvent
                )
                .hexpand()
                .frame(minHeight: DashboardWindowLayout.consoleHeight)
            }
            .style("operations-main-row")

            HStack(spacing: 16) {
                ExposureWatchPanel(sockets: visibleSockets, recentActivity: recentActivity)
                    .hexpand()
                NetworkActorsPanel(sockets: visibleSockets)
                    .hexpand()
            }
            .style("operations-bottom-row")

            if !snapshot.metrics.topProcesses.isEmpty {
                topProcessesPanel
                    .padding(16)
                    .style("operations-section-gap")
            }
        }
        .style("operations-page")
    }

    @ViewBuilder
    private var connectivityPanel: Body {
        DashboardSurface(title: "CONNECTIVITY", icon: .default(icon: .networkWireless)) {
            DashboardDetailRow(label: "Interface", value: network.interfaceName ?? "Unavailable")
            DashboardDetailRow(label: "Active TCP", value: "\(network.activeTCPConnections)")
            DashboardDetailRow(
                label: "Latency",
                value: DashboardFormatting.latency(network.latencyMilliseconds),
                accent: true
            )
            DashboardDetailRow(label: "VPN", value: network.vpn.state.rawValue)
        }
        .style("operations-sidebar-panel")
    }

    @ViewBuilder
    private var insightPanel: Body {
        DashboardSurface(title: "LATEST OBSERVATION", icon: .default(icon: .dialogInformation)) {
            ScrollView {
                VStack {
                    if let issue = snapshot.topIssue {
                        Text("\(issue.title) — \(issue.detail)")
                            .ellipsize()
                            .caption()
                            .monospace()
                            .halign(.start)
                        if let recommendation = issue.recommendation {
                            Text(recommendation)
                                .ellipsize()
                                .caption()
                                .dimLabel()
                                .halign(.start)
                                .padding(6)
                        }
                    } else {
                        Text("No scored issues are reducing the health score right now.")
                            .caption()
                            .dimLabel()
                            .style("operations-insight-copy")
                            .halign(.start)
                    }
                }
            }
            .frame(maxHeight: 120)
        }
        .style("operations-sidebar-panel")
    }

    @ViewBuilder
    private var topProcessesPanel: Body {
        DashboardSurface(title: "TOP CPU USAGE", icon: .default(icon: .applicationsSystem)) {
            ScrollView {
                VStack {
                    ForEach(Array(snapshot.metrics.topProcesses.prefix(6))) { process in
                        DashboardDetailRow(
                            label: DashboardFormatting.processName(process.name),
                            value: "\(DashboardFormatting.percent(process.cpuPercent)) CPU"
                        )
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding(16)
        .style("operations-section-gap")
    }
}
