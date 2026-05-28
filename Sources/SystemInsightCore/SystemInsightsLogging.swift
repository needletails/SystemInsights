import Foundation
import Logging

/// Routes swift-log (used by NeedleTailLogger) to stderr.
/// Handler threshold is `.debug` so socket diagnostics appear in the Xcode console (Debug builds only).
public enum SystemInsightsLogging {
    private nonisolated(unsafe) static var didBootstrap = false

    public static func bootstrapIfNeeded() {
        guard !didBootstrap else { return }
        didBootstrap = true
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardError(label: label)
            handler.logLevel = .debug
            return handler
        }
    }
}
