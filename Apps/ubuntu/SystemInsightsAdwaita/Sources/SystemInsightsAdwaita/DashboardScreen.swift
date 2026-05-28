import Foundation

/// UI phase for the operations window. Kept separate from ``DashboardSecurityState`` so
/// unlock can finish on the GTK main loop before the view tree swaps branches.
enum DashboardScreen: Equatable {
    case unlock
    case passwordSetup
    case main

    static func from(security: DashboardSecurityState) -> DashboardScreen {
        if security.requiresUnlock {
            .unlock
        } else if security.showsPasswordSetup {
            .passwordSetup
        } else {
            .main
        }
    }
}
