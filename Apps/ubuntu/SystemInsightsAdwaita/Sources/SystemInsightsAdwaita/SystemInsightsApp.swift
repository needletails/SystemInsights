import Adwaita
import Foundation
import SystemInsightCore

@main
@MainActor
struct SystemInsightsApp: @preconcurrency App {
    var app = AdwaitaApp(id: "com.needletails.systeminsights")

    init() {
        SystemInsightsLogging.bootstrapIfNeeded()
        #if os(Linux)
        DashboardCollectDiagnostics.log("app init")
        LinuxSandboxDiagnostics.logStartupReport()
        #endif
    }

    var scene: Scene {
        Window(id: "main") { _ in
            DashboardView()
        }
        .title("System Insights")
        .defaultSize(
            width: DashboardWindowLayout.defaultWidth,
            height: DashboardWindowLayout.defaultHeight
        )
        .minSize(
            width: DashboardWindowLayout.minWidth,
            height: DashboardWindowLayout.minHeight
        )
        .resizable(true)
        // GTK on macOS cannot parse "<Ctrl>…" accelerators (logs win.<Ctrl>w / app.<Ctrl>q
        // and can destabilize the UI when the window re-registers shortcuts after unlock).
        .onClose {
            CacheSecurityCoordinator.lock()
            return .close
        }
    }
}
