import Adwaita
import Foundation

/// Schedules work after the current GTK/Meta view update pass.
/// Use for handlers wired from GTK signals (`entry-activated`, `clicked`, `notify::text` setters, etc.)
/// so `@State` / `@Binding` writes do not call `getState()` re-entrantly.
enum UIViewDeferral {
    /// Reads MainActor state on the GTK main loop (Linux) or the dispatch queue (macOS).
    static func readOnMain<T: Sendable>(_ work: @escaping @MainActor () -> T) async -> T {
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

    /// Preferred entry point for GTK signal handlers and button actions.
    nonisolated static func run(_ work: @escaping () -> Void) {
        let deferred = DeferredUIAction(work)
        #if os(Linux)
        Idle {
            deferred.perform()
        }
        #else
        DispatchQueue.main.async {
            deferred.perform()
        }
        #endif
    }

    nonisolated static func afterCurrentEvent(_ work: @escaping () -> Void) {
        run(work)
    }

    /// Updates a string binding on the next main-queue turn (GTK handlers are synchronous).
    static func setStringIfNeeded(_ binding: Binding<String>, to value: String) {
        let target = DeferredBinding(binding)
        let committed = value
        #if os(Linux)
        Idle {
            target.setIfNeeded(committed)
        }
        #else
        DispatchQueue.main.async {
            target.setIfNeeded(committed)
        }
        #endif
    }

    static func setScopeIfNeeded(_ binding: Binding<SocketScope>, id newID: String) {
        let target = DeferredBinding(binding)
        let committed = SocketScope(rawValue: newID) ?? .all
        #if os(Linux)
        Idle {
            target.setIfNeeded(committed)
        }
        #else
        DispatchQueue.main.async {
            target.setIfNeeded(committed)
        }
        #endif
    }
}

/// Holds GTK UI work while it crosses to the next main-queue pass.
private final class DeferredUIAction: @unchecked Sendable {
    private let work: () -> Void

    init(_ work: @escaping () -> Void) {
        self.work = work
    }

    func perform() {
        work()
    }
}

/// Captures binding get/set for the next main-queue turn (GTK signals are synchronous).
private final class DeferredBinding<Value: Equatable>: @unchecked Sendable {
    private let get: () -> Value
    private let set: (Value) -> Void

    init(_ binding: Binding<Value>) {
        get = { binding.wrappedValue }
        set = { binding.wrappedValue = $0 }
    }

    func setIfNeeded(_ value: Value) {
        if get() != value {
            set(value)
        }
    }
}
