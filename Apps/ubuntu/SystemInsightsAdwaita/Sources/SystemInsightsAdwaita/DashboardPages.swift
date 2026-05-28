import Adwaita
import Foundation
import SystemInsightCore

struct DashboardOverviewPage: View {
    let snapshot: InsightSnapshot

    var view: Body {
        VStack {
            HealthHeroCard(snapshot: snapshot)
            ResourceMetricsRow(snapshot: snapshot)
            if let issue = snapshot.topIssue {
                InsightHighlightCard(
                    title: "Top observation",
                    detail: "\(issue.title) — \(issue.detail)",
                    recommendation: issue.recommendation
                )
            } else {
                InsightHighlightCard(
                    title: "Observations",
                    detail: "No scored issues are reducing the health score right now.",
                    recommendation: nil
                )
            }
            if !snapshot.recommendations.isEmpty {
                DashboardFormSection(
                    title: "Recommendations",
                    rows: snapshot.recommendations.prefix(4).map {
                        DashboardRow(title: $0, subtitle: "Suggested follow-up")
                    }
                )
            }
        }
    }
}

struct DashboardNetworkPage: View {
    let snapshot: InsightSnapshot
    let network: NetworkMetrics
    let speedSamples: [NetworkMetrics]
    let visibleSockets: [VisibleSocket]
    let recentActivity: [NetworkActivityEvent]
    let lastSocketSampleAt: Date?

    var view: Body {
        VStack {
            DashboardFormSection(
                title: "Live throughput",
                rows: [
                    DashboardRow(
                        title: "Download \(DashboardFormatting.rate(network.receivedBytesPerSecond))",
                        subtitle: "Upload \(DashboardFormatting.rate(network.sentBytesPerSecond)) · Latency \(DashboardFormatting.latency(network.latencyMilliseconds))"
                    ),
                    DashboardRow(
                        title: "Rolling average",
                        subtitle: "RX \(DashboardFormatting.rate(DashboardFormatting.averageReceived(speedSamples))) · TX \(DashboardFormatting.rate(DashboardFormatting.averageSent(speedSamples)))"
                    ),
                    DashboardRow(
                        title: "Peak window",
                        subtitle: "RX \(DashboardFormatting.rate(DashboardFormatting.peakReceived(speedSamples))) · TX \(DashboardFormatting.rate(DashboardFormatting.peakSent(speedSamples)))"
                    )
                ]
            )

            DashboardFormSection(
                title: "Connectivity",
                rows: [
                    DashboardRow(
                        title: network.interfaceName ?? "No active interface",
                        subtitle: "\(network.activeTCPConnections) active TCP connections"
                    ),
                    DashboardRow(
                        title: "VPN · \(network.vpn.state.rawValue)",
                        subtitle: network.vpn.detail
                    )
                ]
            )

            DashboardFormSection(
                title: "Socket inventory",
                rows: socketSummaryRows + socketDetailRows
            )

            if !recentActivity.isEmpty {
                DashboardFormSection(
                    title: "Recent transitions",
                    rows: recentActivity.prefix(10).map { event in
                        DashboardRow(
                            title: "\(event.action.rawValue) · \(event.processName)",
                            subtitle: "\(DashboardFormatting.shortTime(event.timestamp)) · \(DashboardFormatting.endpoint(event))"
                        )
                    }
                )
            }

            DashboardFormSection(
                title: "Network actors",
                rows: actorRows
            )
        }
    }

    private var socketSummaryRows: [DashboardRow] {
        [
            DashboardRow(title: "Sampler", subtitle: DashboardFormatting.pollText(lastSocketSampleAt)),
            DashboardRow(
                title: "Inventory",
                subtitle: "\(DashboardFormatting.establishedCount(visibleSockets)) established · \(DashboardFormatting.listenerCount(visibleSockets)) listening · \(DashboardFormatting.udpCount(visibleSockets)) UDP"
            ),
            DashboardRow(
                title: "Exposure",
                subtitle: "\(DashboardFormatting.exposedCount(visibleSockets)) wildcard-bound endpoints"
            )
        ]
    }

    private var socketDetailRows: [DashboardRow] {
        let sockets = visibleSockets.prefix(12)
        if sockets.isEmpty {
            return [DashboardRow(title: "No sockets visible yet", subtitle: "Waiting for the next live sample.")]
        }
        return sockets.map { socket in
            DashboardRow(
                title: "\(socket.processName) · \(socket.serviceHint.label)",
                subtitle: "\(socket.transport.rawValue) \(socket.state.rawValue) · pid \(socket.pid) · \(DashboardFormatting.endpoint(socket))"
            )
        }
    }

    private var actorRows: [DashboardRow] {
        let actors = DashboardFormatting.networkActors(visibleSockets).prefix(8)
        if actors.isEmpty {
            return [DashboardRow(title: "No peer-addressed sockets", subtitle: "Processes with remote peers appear here.")]
        }
        return actors.map { actor in
            DashboardRow(
                title: actor.processName,
                subtitle: "pid \(actor.pid) · \(actor.peerCount) peers · \(actor.tcpCount) TCP · \(actor.udpCount) UDP"
            )
        }
    }
}

struct DashboardProcessesPage: View {
    let snapshot: InsightSnapshot

    var view: Body {
        VStack {
            DashboardFormSection(
                title: "Top CPU usage",
                rows: snapshot.metrics.topProcesses.prefix(8).map { process in
                    DashboardRow(
                        title: DashboardFormatting.processName(process.name),
                        subtitle: "\(DashboardFormatting.percent(process.cpuPercent)) CPU · \(DashboardFormatting.percent(process.memoryPercent)) memory"
                    )
                }
            )
        }
    }
}

struct DashboardSecurityPage: View {
    let snapshot: InsightSnapshot

    var view: Body {
        VStack {
            DashboardFormSection(
                title: "Policy scan",
                rows: [
                    DashboardRow(
                        title: "\(snapshot.securityFindings.count) findings in last full scan",
                        subtitle: snapshot.topIssue?.title ?? "No critical policy issues scored."
                    )
                ]
            )

            DashboardFormSection(
                title: "Recent security events",
                rows: securityEventRows
            )

            DashboardFormSection(
                title: "Inspection mode",
                rows: [
                    DashboardRow(
                        title: "Socket metadata only",
                        subtitle: "Endpoint ownership and port-derived hints — no packet capture."
                    ),
                    DashboardRow(
                        title: "Heuristic service labels",
                        subtitle: "PORT MAP and HEURISTIC labels are metadata-only; packet capture is not performed."
                    )
                ]
            )
        }
    }

    private var securityEventRows: [DashboardRow] {
        if snapshot.securityEvents.isEmpty {
            return [DashboardRow(title: "No events collected", subtitle: "Run a full snapshot to refresh security log excerpts.")]
        }
        return snapshot.securityEvents.prefix(10).map { event in
            DashboardRow(title: event.source, subtitle: event.message)
        }
    }
}
