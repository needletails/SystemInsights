import Adwaita
import Foundation

enum DashboardTheme {
    static let css = """
    window {
      background-color: rgba(0, 0, 0, 0.45);
    }
    .operations-root {
      background-color: rgba(9, 11, 16, 0.92);
    }
    .operations-page {
      padding: 0;
    }
    .operations-page-content {
      padding: 16px 22px 24px 22px;
    }
    .operations-page {
      min-width: 1060px;
    }
    .operations-sidebar-column {
      min-width: 330px;
    }
    .operations-traffic-panel {
      min-height: 292px;
    }
    .operations-surface {
      background-color: rgba(18, 21, 28, 0.82);
      border: 1px solid rgba(255, 255, 255, 0.075);
      border-radius: 14px;
      padding: 0;
    }
    .operations-surface-header {
      padding: 12px 14px 8px 14px;
      min-height: 40px;
    }
    .operations-surface-header-icon {
      margin-right: 2px;
    }
    .operations-sidebar-panel {
      min-width: 0;
    }
    .operations-surface-body {
      padding: 2px 14px 12px 14px;
    }
    .operations-header-bar {
      padding: 12px 16px;
    }
    .operations-header-cluster {
      margin-right: 12px;
      min-width: 0;
    }
    .operations-header-icon-slot {
      margin-right: 4px;
      padding: 0 6px 0 0;
    }
    .operations-header-trailing {
      padding: 0;
    }
    .operations-console {
      background-color: rgba(6, 8, 12, 0.92);
      border: 1px solid rgba(255, 255, 255, 0.075);
      border-radius: 15px;
      padding: 0;
      min-height: 632px;
      min-width: 0;
    }
    .operations-console-header {
      background-color: rgba(12, 15, 20, 0.95);
      padding: 12px 14px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.06);
    }
    .operations-console-strip {
      background-color: rgba(0, 0, 0, 0.22);
      padding: 9px 14px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.05);
    }
    .operations-console-controls {
      padding: 10px 12px 11px 12px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.06);
    }
    .operations-console-controls-sockets {
      min-width: 0;
      margin-right: 6px;
    }
    .operations-console-search-slot {
      margin-left: 12px;
      min-width: 0;
    }
    .operations-console-table-area {
      padding: 8px 10px 6px 10px;
      min-height: 420px;
      min-width: 0;
    }
    .operations-console-footer {
      padding: 10px 14px 12px 14px;
      border-top: 1px solid rgba(255, 255, 255, 0.05);
      opacity: 0.78;
    }
    .operations-search-shell {
      background-color: rgba(12, 15, 20, 0.92);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 7px;
      padding: 6px 10px;
      min-height: 0;
    }
    .operations-search-icon {
      font-size: 13px;
      opacity: 0.55;
      min-width: 20px;
      margin-right: 6px;
    }
    .operations-table-panel {
      background-color: rgba(12, 15, 20, 0.55);
      border: 1px solid rgba(255, 255, 255, 0.06);
      border-radius: 10px;
      padding: 0;
      min-height: 360px;
      min-width: 0;
    }
    .operations-table-panel-sockets {
      min-width: 0;
    }
    .operations-table-panel-activity {
      min-width: 306px;
    }
    .operations-table-panel-title {
      font-weight: 700;
      letter-spacing: 0.08em;
      opacity: 0.72;
      padding: 10px 12px 6px 12px;
    }
    .operations-table-divider {
      background-color: rgba(255, 255, 255, 0.08);
      min-width: 1px;
      margin: 10px 3px;
    }
    .operations-sparkline {
      background-color: rgba(0, 0, 0, 0.26);
      border-radius: 8px;
      padding: 10px 12px;
      min-height: 64px;
      margin: 6px 0;
    }
    .operations-sparkline-legend {
      padding: 8px 2px 4px 2px;
    }
    .operations-traffic-readings {
      padding: 4px 0 8px 0;
    }
    .operations-traffic-reading {
      min-width: 0;
    }
    .operations-insight-copy {
      padding: 2px 0 6px 0;
      line-height: 1.45;
    }
    .operations-table-header {
      background-color: rgba(255, 255, 255, 0.04);
      padding: 9px 12px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.06);
    }
    .operations-table-header-cell {
      font-weight: 600;
      letter-spacing: 0.04em;
    }
    .operations-table-row {
      padding: 6px 10px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.04);
      min-height: 28px;
    }
    .operations-table-row:hover {
      background-color: rgba(255, 255, 255, 0.05);
    }
    .operations-table-cell {
      padding: 0 4px;
    }
    .operations-activity-row {
      min-height: 38px;
      padding-top: 5px;
      padding-bottom: 5px;
    }
    .operations-activity-flow {
      min-width: 0;
    }
    .operations-activity-tag {
      opacity: 0.8;
    }
    .operations-detail-row {
      padding: 8px 0;
    }
    .operations-eyebrow {
      font-weight: 600;
      letter-spacing: 0.06em;
      opacity: 0.58;
    }
    .operations-icon-glyph {
      font-size: 15px;
      font-weight: 700;
      opacity: 0.92;
    }
    .operations-rating-glyph {
      font-size: 20px;
      font-weight: 700;
      min-width: 0;
      min-height: 0;
    }
    .operations-toolbar-glyph {
      font-size: 15px;
      font-weight: 600;
      min-width: 28px;
      min-height: 28px;
      margin-left: 4px;
      margin-right: 4px;
    }
    .operations-toolbar-slot {
      min-width: 24px;
      min-height: 24px;
      opacity: 0;
    }
    .operations-empty-state {
      padding: 32px;
    }
    .operations-section-gap {
      margin-bottom: 16px;
    }
    .operations-metrics-strip {
      padding: 0;
      margin-bottom: 12px;
    }
    .operations-main-row {
      padding: 0;
      margin-bottom: 14px;
      min-width: 0;
    }
    .operations-bottom-row {
      padding: 0;
      margin-bottom: 4px;
    }
    .operations-metric-tile {
      min-width: 0;
    }
    .operations-metric-tile-inner {
      padding: 12px 14px 13px 14px;
      min-height: 84px;
    }
    .operations-metric-meter {
      margin-top: 10px;
      min-height: 6px;
    }
    .operations-metric-value {
      margin-top: 6px;
      margin-bottom: 0;
      font-weight: 600;
    }
    .operations-console-counters {
      padding: 0 4px;
    }
    .operations-console-counter {
      background-color: rgba(255, 255, 255, 0.04);
      border: 1px solid rgba(255, 255, 255, 0.06);
      border-radius: 8px;
      padding: 6px 10px;
      margin-left: 6px;
      min-width: 68px;
    }
    .operations-poll-pill {
      padding: 10px 14px;
      margin-right: 10px;
    }
    .operations-score-card {
      padding: 10px 16px;
      margin-right: 10px;
      min-width: 108px;
    }
    .operations-score-value-row {
      margin-top: 2px;
    }
    .operations-score-primary {
      margin-right: 4px;
      letter-spacing: 0.02em;
    }
    .operations-score-suffix {
      margin-left: 6px;
      padding-bottom: 3px;
      opacity: 0.72;
    }
    .operations-preferences-note {
      opacity: 0.62;
      padding: 8px 4px 12px 4px;
    }
    .operations-preferences-actions-wrap {
      padding: 14px 6px 6px 6px;
    }
    .operations-preferences-actions {
      padding: 0;
      margin: 0;
    }
    .operations-preferences-button {
      min-width: 148px;
      padding: 10px 18px;
    }
    .operations-security-cancel {
      padding: 6px 14px;
      margin-right: 6px;
    }
    .operations-security-card {
      padding: 4px;
    }
    .operations-security-copy {
      line-height: 1.45;
      padding: 4px 0 10px 0;
    }
    .operations-security-actions {
      padding: 12px 0 4px 0;
    }
    .operations-primary-action {
      background-color: @accent_bg_color;
      color: @accent_fg_color;
      padding: 10px 18px;
    }
    .operations-password-field {
      margin-bottom: 4px;
    }
    .operations-modal {
      background-color: rgba(12, 15, 20, 0.98);
    }
    .operations-modal-header {
      padding: 4px 4px 14px 4px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.08);
      margin-bottom: 14px;
    }
    .operations-modal-icon {
      font-size: 26px;
      font-weight: 700;
      min-width: 44px;
      min-height: 44px;
      margin-right: 12px;
      opacity: 0.9;
    }
    .operations-modal-strip {
      background-color: rgba(255, 255, 255, 0.04);
      border: 1px solid rgba(255, 255, 255, 0.07);
      border-radius: 10px;
      padding: 10px 8px;
      margin-bottom: 14px;
      min-width: 0;
    }
    .operations-modal-badge {
      padding: 4px 8px;
      min-width: 0;
    }
    .operations-inspector-scroll {
      min-height: 0;
      min-width: 0;
    }
    .operations-inspector-label {
      letter-spacing: 0.04em;
      opacity: 0.72;
    }
    .operations-inspector-value {
      line-height: 1.45;
      padding-top: 2px;
    }
    .operations-inspector-note {
      line-height: 1.45;
      padding: 8px 2px 2px 2px;
    }
    .operations-modal-section {
      background-color: rgba(18, 21, 28, 0.88);
      border: 1px solid rgba(255, 255, 255, 0.07);
      border-radius: 12px;
      padding: 12px 14px;
      margin-bottom: 12px;
    }
    .operations-modal-detail-row {
      padding: 10px 2px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.04);
      min-width: 0;
    }
    .operations-modal-detail-row:last-child {
      border-bottom: none;
    }
    .operations-modal-footer {
      padding-top: 12px;
      border-top: 1px solid rgba(255, 255, 255, 0.06);
    }
    .metric-accent-cpu label, .metric-accent-cpu {
      color: #5ac8fa;
    }
    .metric-accent-cpu .operations-icon-glyph {
      color: #5ac8fa;
    }
    .metric-accent-memory label, .metric-accent-memory {
      color: #bf5af2;
    }
    .metric-accent-memory .operations-icon-glyph {
      color: #bf5af2;
    }
    .metric-accent-disk label, .metric-accent-disk {
      color: #ff9f0a;
    }
    .metric-accent-disk .operations-icon-glyph {
      color: #ff9f0a;
    }
    .metric-accent-sockets label, .metric-accent-sockets {
      color: #30d158;
    }
    .metric-accent-sockets .operations-icon-glyph {
      color: #30d158;
    }
    .traffic-down label, .traffic-down {
      color: #30d158;
    }
    .traffic-down .operations-icon-glyph {
      color: #30d158;
    }
    .traffic-up label, .traffic-up {
      color: #64d2ff;
    }
    .traffic-up .operations-icon-glyph {
      color: #64d2ff;
    }
    .traffic-latency label, .traffic-latency {
      color: #ff9f0a;
    }
    .traffic-latency .operations-icon-glyph {
      color: #ff9f0a;
    }
    """

}

@MainActor
struct OperationsRoot: @preconcurrency View {
    /// GTK applies custom CSS at display scope; register once to avoid stacking providers on unlock → dashboard transitions.
    private static var installedApplicationCSS = false

    var onFirstAppear: (() -> Void)?
    @ViewBuilder let content: () -> Body

    var view: Body {
        let root = Box {
            content()
        }
        .style("operations-root")
        .hexpand()
        .vexpand()
        .onAppear {
            UIViewDeferral.run {
                onFirstAppear?()
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.35) {
                UIViewDeferral.run {
                    onFirstAppear?()
                }
            }
        }

        if Self.installedApplicationCSS {
            root
        } else {
            root
                .css(scheme: .dark) { DashboardTheme.css }
                .onAppear {
                    UIViewDeferral.run {
                        Self.installedApplicationCSS = true
                    }
                }
        }
    }
}
