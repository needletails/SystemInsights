import Foundation

/// Bumps a generation counter so Adwaita re-reads ``DashboardViewModel`` after GTK recreates the view.
@MainActor
final class DashboardRenderState {
    private(set) var generation = 0

    func bump() {
        generation += 1
    }
}
