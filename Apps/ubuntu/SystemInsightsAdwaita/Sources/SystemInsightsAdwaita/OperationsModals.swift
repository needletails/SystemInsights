import Adwaita
import Foundation
import SystemInsightCore

/// Connection / activity inspector presented as a styled `AdwDialog` (not `AdwAlertDialog`).
struct OperationsInspectorDialog: View {
    let selection: NetworkRecordSelection
    let context: SocketInspectorContext
    let onDismiss: () -> Void

    var view: Body {
        VStack {
            inspectorHeader
            summaryStrip
            ScrollView {
                VStack {
                    metadataSection
                    boundarySection
                }
            }
            .vexpand()
            .style("operations-inspector-scroll")

            HStack {
                Box { }
                    .hexpand()
                Button("Done") {
                    UIViewDeferral.run { onDismiss() }
                }
                .pill()
                .suggested()
            }
            .style("operations-modal-footer")
        }
        .style("operations-modal")
        .padding(20)
    }

    @ViewBuilder
    private var metadataSection: Body {
        Box {
            VStack {
                Text("OBSERVABLE FLOW METADATA")
                    .caption()
                    .monospace()
                    .style("operations-eyebrow")
                    .dimLabel()
                    .halign(.start)
                    .padding(4)
                ForEach(presentationRows) { row in
                    InspectorDetailRow(label: row.title, value: row.value, accent: row.isHighlighted)
                }
            }
        }
        .style("operations-modal-section")
    }

    @ViewBuilder
    private var boundarySection: Body {
        Box {
            VStack {
                Text("PACKET INSPECTION BOUNDARY")
                    .caption()
                    .monospace()
                    .style("operations-eyebrow")
                    .dimLabel()
                    .halign(.start)
                    .padding(4)
                ForEach(SocketInspectorPresentation.boundaryNotes) { note in
                    InspectorDetailRow(label: note.title, value: note.value)
                }
                Text(SocketInspectorPresentation.boundaryFooter)
                    .caption()
                    .dimLabel()
                    .halign(.start)
                    .style("operations-inspector-note")
                    .inspectorLabelWrap()
            }
        }
        .style("operations-modal-section")
    }

    @ViewBuilder
    private var inspectorHeader: Body {
        HStack {
            Text(headerGlyph)
                .style("operations-modal-icon")
            VStack {
                Text(headerEyebrow)
                    .caption()
                    .monospace()
                    .style("operations-eyebrow")
                    .dimLabel()
                Text(headerTitle)
                    .title2()
                    .halign(.start)
                    .inspectorLabelWrap()
                Text(headerSubtitle)
                    .caption()
                    .dimLabel()
                    .halign(.start)
                    .inspectorLabelWrap(selectable: false)
            }
            .hexpand()
            .halign(.start)
        }
        .style("operations-modal-header")
    }

    @ViewBuilder
    private var summaryStrip: Body {
        HStack(spacing: 8) {
            ForEach(summaryBadges, id: \.label) { badge in
                VStack {
                    Text(badge.label)
                        .caption()
                        .monospace()
                        .dimLabel()
                    Text(badge.value)
                        .caption()
                        .monospace()
                        .halign(.center)
                        .success(badge.tone == .good)
                        .warning(badge.tone == .warning)
                        .accent(badge.tone == .accent)
                        .inspectorLabelWrap(selectable: false)
                }
                .hexpand()
                .style("operations-modal-badge")
            }
        }
        .style("operations-modal-strip")
    }

    private var presentationRows: [SocketInspectorRow] {
        switch selection {
        case .socket(let socket):
            SocketInspectorPresentation.rows(for: socket, context: context)
        case .event(let event):
            SocketInspectorPresentation.rows(for: event, context: context)
        }
    }

    private var headerEyebrow: String {
        switch selection {
        case .socket: "SOCKET INSPECTOR"
        case .event: "ACTIVITY INSPECTOR"
        }
    }

    private var headerTitle: String {
        switch selection {
        case .socket(let socket):
            URL(fileURLWithPath: socket.processName).lastPathComponent
        case .event(let event):
            URL(fileURLWithPath: event.processName).lastPathComponent
        }
    }

    private var headerSubtitle: String {
        switch selection {
        case .socket(let socket):
            "pid \(socket.pid) · \(socket.transport.rawValue) · \(socket.state.rawValue)"
        case .event(let event):
            "\(event.action.rawValue) · \(DashboardFormatting.shortTime(event.timestamp))"
        }
    }

    private var headerGlyph: String {
        switch selection {
        case .socket: "⇄"
        case .event: "◉"
        }
    }

    private struct SummaryBadge {
        enum Tone {
            case neutral
            case good
            case warning
            case accent
        }

        let label: String
        let value: String
        let tone: Tone
    }

    private var summaryBadges: [SummaryBadge] {
        switch selection {
        case .socket(let socket):
            SocketInspectorPresentation.summaryBadges(for: socket).map {
                SummaryBadge(label: $0.label, value: $0.value, tone: badgeTone(label: $0.label, socket: socket))
            }
        case .event(let event):
            SocketInspectorPresentation.summaryBadges(for: event).map {
                SummaryBadge(label: $0.label, value: $0.value, tone: badgeTone(label: $0.label, event: event))
            }
        }
    }

    private func badgeTone(label: String, socket: VisibleSocket) -> SummaryBadge.Tone {
        switch label {
        case "FLOW":
            flowBadgeTone(SocketInspectorPresentation.flowPerspective(for: socket).kind)
        case "STATE":
            socket.state == .established ? .good : .neutral
        case "SERVICE":
            serviceBadgeTone(socket.serviceHint.confidence)
        default:
            .accent
        }
    }

    private func badgeTone(label: String, event: NetworkActivityEvent) -> SummaryBadge.Tone {
        switch label {
        case "FLOW":
            flowBadgeTone(SocketInspectorPresentation.flowPerspective(for: event).kind)
        case "SERVICE":
            serviceBadgeTone(event.serviceHint.confidence)
        default:
            .accent
        }
    }

    private func flowBadgeTone(_ kind: SocketHostFlowKind) -> SummaryBadge.Tone {
        switch kind {
        case .inbound, .inboundReady: .good
        case .outbound: .accent
        case .bidirectional: .warning
        case .undetermined: .neutral
        }
    }

    private func serviceBadgeTone(_ confidence: SocketServiceConfidence) -> SummaryBadge.Tone {
        switch confidence {
        case .portMapped: .good
        case .heuristic: .warning
        case .unclassified: .neutral
        }
    }
}

struct InspectorDetailRow: View {
    let label: String
    let value: String
    var accent: Bool = false

    var view: Body {
        VStack {
            Text(label)
                .caption()
                .monospace()
                .dimLabel()
                .halign(.start)
                .style("operations-inspector-label")
            Text(value)
                .caption()
                .monospace()
                .accent(accent)
                .halign(.start)
                .style("operations-inspector-value")
                .inspectorLabelWrap()
        }
        .halign(.fill)
        .style("operations-modal-detail-row")
    }
}

/// Privacy & cache settings content aligned with the operations visual language.
@MainActor
enum OperationsPreferencesContent {
    static func privacyPage(
        _ page: PreferencesDialog.PreferencesPage,
        security: DashboardSecurityState,
        onChangePassword: @escaping () -> Void,
        onEnablePassword: @escaping () -> Void,
        onLockNow: @escaping () -> Void
    ) -> PreferencesDialog.PreferencesPage {
        var configured = page.group("Encrypted cache") {
            ActionRow("Local snapshot storage")
                .subtitle("Performance and network snapshots are stored on this machine.")
            Text(
                "Password protection encrypts the cache at rest. Unlocking establishes a session key used for reads and live monitoring."
            )
            .caption()
            .dimLabel()
            .style("operations-preferences-note")
        }
        if security.isPasswordProtectionEnabled {
            configured = configured.group("Protection status") {
                ActionRow("Password protection is enabled")
                    .subtitle("Lock the cache when you step away from this machine.")
                VStack {
                    HStack(spacing: 12) {
                        Button("Change password") {
                            onChangePassword()
                        }
                        .pill()
                        .style("operations-preferences-button")
                        Button("Lock now") {
                            onLockNow()
                        }
                        .pill()
                        .style("operations-preferences-button")
                    }
                    .style("operations-preferences-actions")
                }
                .style("operations-preferences-actions-wrap")
            }
        } else {
            configured = configured.group("Optional protection") {
                ActionRow("No password configured")
                    .subtitle("Anyone with access to this user account can read cached snapshots.")
                Button("Enable password protection") {
                    onEnablePassword()
                }
                .pill()
                .style("operations-preferences-button")
                .style("operations-preferences-actions-wrap")
            }
        }
        return configured.group("Privacy boundary") {
            ActionRow("Metadata only")
                .subtitle("Socket tables show endpoint ownership and port-derived hints — no packet capture.")
            ActionRow("Classification")
                .subtitle("Well-known ports, process+port heuristics, or no mapping — none inspect packet payloads.")
        }
    }
}
