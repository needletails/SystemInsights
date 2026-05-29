import Adwaita
import Foundation
import SystemInsightCore

@main
@MainActor
struct SystemInsightsApp: @preconcurrency App {
    var app: AdwaitaApp

    init() {
        #if os(Linux)
        LinuxRuntimeEnvironment.configureBeforeAppLaunch()
        #endif
        app = AdwaitaApp(id: "com.needletails.systeminsights")
        SystemInsightsLogging.bootstrapIfNeeded()
        #if os(Linux)
        DashboardViewModel.shared.resetForProcessLaunch()
        DashboardCollectDiagnostics.log("app init")
        LinuxSandboxDiagnostics.logStartupReport()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.75) {
            DashboardCollectDiagnostics.log("app delayed bootstrap request")
            DashboardViewModel.shared.requestDelayedBootstrap()
        }
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
