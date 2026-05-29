import Adwaita
import Foundation

/// GTK often does not fire `onAppear` on the dashboard root; this zero-size box is realized with the window.
@MainActor
enum DashboardLaunchState {
    static var didBootstrap = false
}

@MainActor
struct DashboardLaunchTrigger: @preconcurrency View {
    let onReady: () -> Void

    var view: Body {
        Box { }
            .frame(minWidth: 1, minHeight: 1)
            .onAppear {
                UIViewDeferral.run {
                    guard !DashboardLaunchState.didBootstrap else { return }
                    DashboardLaunchState.didBootstrap = true
                    DashboardCollectDiagnostics.log("dashboard launch trigger appeared")
                    onReady()
                }
            }
    }
}
