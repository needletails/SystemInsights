import AppKit
import SwiftUI
import SystemInsightCore

@MainActor
final class SystemInsightsAppDelegate: NSObject, NSApplicationDelegate {
    let model = InsightViewModel()
    let updater = UpdaterController()
    private var dashboardWindow: NSWindow?

    func application(_ application: NSApplication, open urls: [URL]) {
        if urls.contains(where: { $0.scheme == "systeminsights" && $0.host == "dashboard" }) {
            showDashboard()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showDashboard()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        CacheSecurityCoordinator.lock()
    }

    func showDashboard() {
        if dashboardWindow == nil {
            let contentView = SystemInsightsDashboardView(model: model)
            let controller = NSHostingController(rootView: contentView)
            let window = NSWindow(
                contentRect: .zero,
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.contentViewController = controller
            window.title = "System Insights"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.toolbar = nil
            window.isMovableByWindowBackground = true
            window.isOpaque = false
            window.backgroundColor = .clear
            window.setContentSize(NSSize(width: 1_320, height: 920))
            window.minSize = NSSize(width: 1_080, height: 760)
            window.center()
            window.isReleasedWhenClosed = false
            dashboardWindow = window
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
        dashboardWindow?.makeKeyAndOrderFront(nil)
    }
}

@main
struct SystemInsightsApp: App {
    @NSApplicationDelegateAdaptor(SystemInsightsAppDelegate.self) private var delegate

    init() {
        SystemInsightsLogging.bootstrapIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra {
            InsightMenuView(
                model: delegate.model,
                updater: delegate.updater,
                openDashboard: delegate.showDashboard
            )
        } label: {
            Label("System Insights", systemImage: delegate.model.menuBarSymbol)
        }
        .menuBarExtraStyle(.window)
    }
}
