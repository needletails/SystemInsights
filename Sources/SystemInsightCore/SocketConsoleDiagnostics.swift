import Foundation
import NeedleTailLogger

/// Opt-in logging for socket sampling and service classification (paste-friendly).
///
/// Emits at swift-log `.debug` only. In Debug builds logging is on by default
/// (`SYSTEM_INSIGHTS_SOCKET_LOG=0` to disable). Release requires `SYSTEM_INSIGHTS_SOCKET_LOG=1`.
/// File output uses NeedleTailLogger under `~/Library/Logs/NeedleTailLogger/`.
public enum SocketConsoleDiagnostics {
    public static let environmentVariable = "SYSTEM_INSIGHTS_SOCKET_LOG"
    private static let loggerLabel = "[SystemInsights.SocketConsole]"

    public static var isEnabled: Bool {
        let value = ProcessInfo.processInfo.environment[environmentVariable]?.lowercased()
        if value == "0" || value == "false" || value == "no" {
            return false
        }
        #if DEBUG
        return true
        #else
        return value == "1" || value == "true" || value == "yes"
        #endif
    }

    public static var logFileURL: URL {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        let directory: FileManager.SearchPathDirectory = .libraryDirectory
        #else
        let directory: FileManager.SearchPathDirectory = .documentDirectory
        #endif
        let base = FileManager.default.urls(for: directory, in: .userDomainMask).first
        return (base ?? URL(fileURLWithPath: NSTemporaryDirectory()))
            .appendingPathComponent("Logs/NeedleTailLogger/\(loggerLabel)/logs.txt", isDirectory: false)
    }

    private nonisolated(unsafe) static var cachedLogger: NeedleTailLogger?

    private static func logger() -> NeedleTailLogger {
        if let cachedLogger {
            return cachedLogger
        }
        let instance = NeedleTailLogger(
            loggerLabel,
            level: .info,
            maxLines: 4000,
            maxLineLength: 2048,
            writeToFile: isEnabled
        )
        cachedLogger = instance
        return instance
    }

    public static func logRefresh(
        source: String,
        connections: [VisibleSocket],
        fingerprint: UInt64,
        appliedToUI: Bool
    ) {
        guard isEnabled else { return }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        var lines: [String] = []
        lines.append(
            "=== \(timestamp) source=\(source) sockets=\(connections.count) fingerprint=\(fingerprint) uiUpdate=\(appliedToUI) ==="
        )

        let unclassified = connections.filter { $0.serviceHint.confidence == .unclassified }
        let classifiedCount = connections.count - unclassified.count
        lines.append("summary classified=\(classifiedCount) unclassified=\(unclassified.count)")

        if !unclassified.isEmpty {
            lines.append("-- UNCLASSIFIED (full detail) --")
            for socket in unclassified.prefix(64) {
                lines.append(format(socket))
            }
            if unclassified.count > 64 {
                lines.append("... \(unclassified.count - 64) more unclassified sockets omitted")
            }
        }

        if !connections.isEmpty {
            lines.append("-- SAMPLE (first 12 connections) --")
            for socket in connections.prefix(12) {
                lines.append(format(socket))
            }
        }

        write(lines.joined(separator: "\n"))
    }

    private static func format(_ socket: VisibleSocket) -> String {
        let hint = socket.serviceHint
        let localPort = SocketServiceClassifier.portNumber(from: socket.localEndpoint)
        let remotePort = SocketServiceClassifier.portNumber(from: socket.remoteEndpoint)
        let remote = socket.remoteEndpoint ?? "(none)"
        return [
            "label=\(hint.label)",
            "confidence=\(hint.confidence.rawValue)",
            "basis=\(hint.basis)",
            "transport=\(socket.transport.rawValue)",
            "state=\(socket.state.rawValue)",
            "pid=\(socket.pid)",
            "process=\(socket.processName)",
            "localPort=\(localPort.map(String.init) ?? "nil")",
            "remotePort=\(remotePort.map(String.init) ?? "nil")",
            "local='\(socket.localEndpoint)'",
            "remote='\(remote)'"
        ].joined(separator: " ")
    }

    private static func write(_ text: String) {
        SystemInsightsLogging.bootstrapIfNeeded()
        let log = logger()
        for line in text.split(whereSeparator: \.isNewline) {
            guard !line.isEmpty else { continue }
            log.log(
                level: .debug,
                message: Message(stringLiteral: String(line)),
                displayIcons: false
            )
        }
    }
}
