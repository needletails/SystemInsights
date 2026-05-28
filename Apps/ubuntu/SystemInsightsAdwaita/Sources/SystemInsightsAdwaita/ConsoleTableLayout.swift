import Adwaita
import Foundation
import SystemInsightCore

/// Shared column widths so socket table headers and rows stay aligned (matches macOS console).
enum ConsoleTableLayout {
    static let proto = 48
    static let state = 76
    static let pid = 54
    static let process = 88
    static let service = 108
    static let activityTime = 58
    static let activityAction = 56
    /// Fixed event-stream width (macOS uses 306pt).
    static let activityPanelWidth = 306
}

struct ConsoleTableHeaderCell: View {
    let title: String
    let width: Int?

    var view: Body {
        let label = Text(title)
            .caption()
            .monospace()
            .dimLabel()
            .style("operations-table-header-cell")
        if let width {
            label
                .frame(minWidth: width)
                .frame(maxWidth: width)
        } else {
            label.hexpand()
        }
    }
}

struct SocketTableHeader: View {
    var view: Body {
        HStack {
            ConsoleTableHeaderCell(title: "PROTO", width: ConsoleTableLayout.proto)
            ConsoleTableHeaderCell(title: "STATE", width: ConsoleTableLayout.state)
            ConsoleTableHeaderCell(title: "PID", width: ConsoleTableLayout.pid)
            ConsoleTableHeaderCell(title: "PROCESS", width: ConsoleTableLayout.process)
            ConsoleTableHeaderCell(title: "SERVICE", width: ConsoleTableLayout.service)
            ConsoleTableHeaderCell(title: "LOCAL ENDPOINT", width: nil)
            ConsoleTableHeaderCell(title: "PEER ENDPOINT", width: nil)
        }
        .style("operations-table-header")
    }
}

struct ActivityTableHeader: View {
    var view: Body {
        HStack {
            ConsoleTableHeaderCell(title: "TIME", width: ConsoleTableLayout.activityTime)
            ConsoleTableHeaderCell(title: "ACTION", width: ConsoleTableLayout.activityAction)
            ConsoleTableHeaderCell(title: "FLOW DETAIL", width: nil)
        }
        .style("operations-table-header")
    }
}

struct SocketTableRow: View {
    let socket: VisibleSocket
    let serviceLabel: String
    let onSelect: () -> Void

    var view: Body {
        Button("") {
            UIViewDeferral.run { onSelect() }
        }
        .child {
            HStack {
                tableCell(socket.transport.rawValue, width: ConsoleTableLayout.proto)
                tableCell(socket.state.rawValue, width: ConsoleTableLayout.state)
                tableCell("\(socket.pid)", width: ConsoleTableLayout.pid, numeric: true)
                tableCell(DashboardFormatting.processName(socket.processName), width: ConsoleTableLayout.process)
                tableCell(serviceLabel, width: ConsoleTableLayout.service)
                tableCell(socket.localEndpoint, width: nil)
                tableCell(socket.remoteEndpoint ?? "—", width: nil)
            }
        }
        .flat()
        .style("operations-table-row")
    }

    private func tableCell(_ value: String, width: Int?, numeric: Bool = false) -> AnyView {
        var text = Text(value)
            .ellipsize()
            .caption()
            .monospace()
            .halign(.start)
            .style("operations-table-cell")
        if numeric {
            text = text.numeric()
        }
        if let width {
            return text
                .frame(minWidth: width)
                .frame(maxWidth: width)
        }
        return text.hexpand()
    }
}

struct ActivityTableRow: View {
    let event: NetworkActivityEvent
    let onSelect: () -> Void

    var view: Body {
        Button("") {
            UIViewDeferral.run { onSelect() }
        }
        .child {
            HStack(spacing: 8) {
                Text(DashboardFormatting.shortTime(event.timestamp))
                    .caption()
                    .monospace()
                    .numeric()
                    .dimLabel()
                    .frame(minWidth: ConsoleTableLayout.activityTime)
                Text(event.action.rawValue)
                    .caption()
                    .monospace()
                    .success(event.action == .opened || event.action == .observed || event.action == .listening)
                    .warning(event.action == .closed || event.action == .stoppedListening)
                    .frame(minWidth: ConsoleTableLayout.activityAction)
                VStack {
                    HStack(spacing: 10) {
                        Text("\(DashboardFormatting.processName(event.processName))  pid \(event.pid)")
                            .ellipsize()
                            .caption()
                            .monospace()
                            .hexpand()
                            .halign(.start)
                        Text("\(event.transport.rawValue)  \(event.serviceHint.label)")
                            .caption()
                            .monospace()
                            .accent()
                            .style("operations-activity-tag")
                    }
                    .hexpand()
                    Text(DashboardFormatting.endpoint(event))
                        .ellipsize()
                        .caption()
                        .monospace()
                        .dimLabel()
                        .hexpand()
                        .halign(.start)
                }
                .hexpand()
                .style("operations-activity-flow")
            }
        }
        .flat()
        .style("operations-table-row")
        .style("operations-activity-row")
    }
}
