import Adwaita
import Foundation

/// Runs MainActor work on the GTK main loop. Required on Linux — ``MainActor.run`` does not pump from worker threads.
enum DashboardGTKBridge {
    static func runOnMain<T: Sendable>(
        _ work: @escaping @MainActor () -> T
    ) async -> T {
        #if os(Linux)
        await withCheckedContinuation { continuation in
            Idle {
                let value = MainActor.assumeIsolated {
                    work()
                }
                continuation.resume(returning: value)
            }
        }
        #else
        await MainActor.run {
            work()
        }
        #endif
    }

    static func runOnMain(_ work: @escaping @MainActor () -> Void) async {
        await runOnMain { () -> Void in
            work()
            return ()
        }
    }
}
