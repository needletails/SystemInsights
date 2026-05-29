import Adwaita
import Foundation

/// Routes ``MainActor`` work through the platform UI loop (GTK ``Idle`` on Linux, ``MainActor`` elsewhere).
enum DashboardGTKBridge {
    nonisolated static func runOnMain<T: Sendable>(
        _ work: @escaping @MainActor () -> T
    ) async -> T {
        #if os(Linux)
        await withCheckedContinuation { continuation in
            Idle {
                let value = MainActor.assumeIsolated { work() }
                continuation.resume(returning: value)
            }
        }
        #else
        await MainActor.run { work() }
        #endif
    }

    nonisolated static func runOnMain(_ work: @escaping @MainActor () -> Void) async {
        #if os(Linux)
        await withCheckedContinuation { continuation in
            Idle {
                MainActor.assumeIsolated { work() }
                continuation.resume()
            }
        }
        #else
        await MainActor.run { work() }
        #endif
    }
}
