import Adwaita
import Foundation
import SystemInsightCore

/// Reliable icon rendering for the operations console (GTK icon themes vary on macOS).
struct OperationsIcon: View {
    let icon: Icon
    var size: Int = 18

    var view: Body {
        Text(OperationsGlyphs.symbol(for: icon))
            .style("operations-icon-glyph")
            .frame(minWidth: size, minHeight: size)
            .halign(.center)
            .valign(.center)
    }
}

struct ToolbarGlyphButton: View {
    let glyph: String
    let tooltip: String
    let action: () -> Void

    var view: Body {
        Button(glyph) {
            UIViewDeferral.run { action() }
        }
        .flat()
        .tooltip(tooltip)
        .style("operations-toolbar-glyph")
        .frame(minWidth: 34, minHeight: 34)
    }
}

/// Socket console filter entry. Commits trimmed text after GTK finishes updating `draft`
/// (`changed` for immediate edits including clear; `search-changed` for debounced typing).
struct ConsoleSearchField: View {
    @Binding var query: String
    @State private var draft: String

    init(query: Binding<String>) {
        _query = query
        _draft = State(wrappedValue: query.wrappedValue)
    }

    var view: Body {
        SearchEntry()
            .text($draft)
            .placeholderText("Filter process, PID or endpoint")
            .searchDelay(300)
            .changed { scheduleFilterCommit() }
            .searchChanged { scheduleFilterCommit() }
            .hexpand()
            .onAppear {
                if draft != query {
                    draft = query
                }
            }
    }

    private func scheduleFilterCommit() {
        UIViewDeferral.run { commitFilterQuery() }
    }

    private func commitFilterQuery() {
        let committed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        UIViewDeferral.setStringIfNeeded($query, to: committed)
    }
}

enum OperationsGlyphs {
    static func symbol(for icon: Icon) -> String {
        switch icon {
        case .default(let value):
            return symbol(for: value)
        case .custom(let name):
            return symbolForCustomName(name)
        }
    }

    static func symbol(for icon: Icon.DefaultIcon) -> String {
        switch icon {
        case .applicationsSystem: "⚡"
        case .applicationsUtilities: "▦"
        case .driveHarddisk: "▣"
        case .networkTransmitReceive, .networkTransmit: "⇄"
        case .networkWireless, .networkWirelessConnected: "⌁"
        case .dialogInformation: "ℹ"
        case .systemRun: "▶"
        case .securityHigh: "◆"
        case .systemUsers: "◎"
        case .dialogWarning: "!"
        case .dialogError: "✕"
        case .emblemDefault: "✓"
        case .viewRefresh: "↻"
        case .preferencesSystem: "⚙"
        case .systemLockScreen: "⛨"
        case .editFind: "⌕"
        default: "•"
        }
    }

    static func symbolForHealthRating(_ rating: HealthRating) -> String {
        switch rating {
        case .good: "✓"
        case .warning: "!"
        case .critical: "✕"
        }
    }

    static func symbolForCustomName(_ name: String) -> String {
        if name.contains("warning") { return "!" }
        if name.contains("error") { return "✕" }
        if name.contains("network") { return "⇄" }
        return "•"
    }
}

struct ToolbarActivitySlot: View {
    let active: Bool

    var view: Body {
        if active {
            Spinner()
                .frame(minWidth: 24, minHeight: 24)
        } else {
            Box { }
                .frame(minWidth: 24, minHeight: 24)
                .style("operations-toolbar-slot")
        }
    }
}
