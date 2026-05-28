import Foundation

/// Applies security/UI mutations outside GTK signal handlers.
@MainActor
enum SecurityUIUpdate {
    static func afterCurrentEvent(_ work: @escaping @MainActor () -> Void) {
        UIViewDeferral.afterCurrentEvent(work)
    }
}
