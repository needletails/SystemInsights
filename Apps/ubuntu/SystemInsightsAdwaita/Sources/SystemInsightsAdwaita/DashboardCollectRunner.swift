import Adwaita
import Foundation
import SystemInsightCore

/// Runs policy collection off the GTK thread; posts UI updates through ``Idle`` (GLib main loop).
enum DashboardCollectRunner {
    nonisolated static func start() {
        DashboardCollectDiagnostics.log("collect runner scheduling g_idle")
        Idle {
            DashboardCollectDiagnostics.log("collect runner idle fired, starting detached work")
            Task.detached(priority: .userInitiated) {
                await run()
            }
        }
    }

    nonisolated private static func run() async {
        DashboardCollectDiagnostics.log("collect runner detached entered")
        await onMainActor {
            await DashboardViewModel.shared.collectSnapshotAsync()
        }
        DashboardCollectDiagnostics.log("collect runner detached finished")
    }

    /// Hop to the GTK main loop. ``DispatchQueue.main`` is not pumped under GNOME/GTK on Linux.
    nonisolated private static func onMainActor(_ work: @escaping @MainActor () async -> Void) async {
        await withCheckedContinuation { continuation in
            Idle {
                Task { @MainActor in
                    await work()
                    continuation.resume()
                }
            }
        }
    }
}
