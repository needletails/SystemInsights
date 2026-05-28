import Foundation
import SystemInsightCore

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

enum CLIError: LocalizedError {
    case unknownCommand(String)
    case missingOutputPath

    var errorDescription: String? {
        switch self {
        case .unknownCommand(let command):
            return "Unknown command: \(command)"
        case .missingOutputPath:
            return "--output requires a file path."
        }
    }
}

struct SystemInsightsCLI {
    static func main() async {
        do {
            try await run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data("system-insights: \(error.localizedDescription)\n".utf8))
            exit(EXIT_FAILURE)
        }
    }

    private static func run(arguments: [String]) async throws {
        if arguments.contains("--help") || arguments.contains("-h") {
            printUsage()
            return
        }

        let command = arguments.first(where: { !$0.hasPrefix("-") }) ?? "collect"
        switch command {
        case "collect":
            try await collect(arguments: arguments)
        case "show":
            try show(arguments: arguments)
        case "panel":
            try panel(arguments: arguments)
        default:
            throw CLIError.unknownCommand(command)
        }
    }

    private static func collect(arguments: [String]) async throws {
        try CacheSecurityCoordinator.unlockFromEnvironmentIfAvailable()
        let outputURL = try outputURL(from: arguments)
        let engine = arguments.contains("--mock") ? InsightEngine.mock() : InsightEngine()
        let baseSnapshot = try await engine.snapshot()
        let connections = arguments.contains("--mock")
            ? []
            : await SystemMetricCollector().collectVisibleSockets()
        let activity = connections.prefix(8).map {
            NetworkActivityEvent(
                timestamp: baseSnapshot.generatedAt,
                action: $0.state == .listening ? .listening : .observed,
                connection: $0
            )
        }
        let snapshot = baseSnapshot.withNetworkActivity(activity)
        try CacheStore(url: outputURL).write(snapshot)
        if !arguments.contains("--quiet") {
            printJSON(snapshot)
        }
    }

    private static func show(arguments: [String]) throws {
        try CacheSecurityCoordinator.unlockFromEnvironmentIfAvailable()
        let snapshot = try CacheStore(url: outputURL(from: arguments)).read()
        printJSON(snapshot)
    }

    private static func panel(arguments: [String]) throws {
        try CacheSecurityCoordinator.unlockFromEnvironmentIfAvailable()
        let presentation: PanelPresentation
        do {
            let snapshot = try CacheStore(url: outputURL(from: arguments)).read()
            presentation = PanelPresentation.make(from: snapshot)
        } catch SnapshotCacheLockError.locked {
            presentation = PanelPresentation.locked()
        } catch {
            presentation = PanelPresentation.unavailable()
        }
        printPanelJSON(presentation)
    }

    private static func outputURL(from arguments: [String]) throws -> URL {
        if let outputIndex = arguments.firstIndex(of: "--output") {
            guard arguments.indices.contains(outputIndex + 1) else {
                throw CLIError.missingOutputPath
            }
            return URL(fileURLWithPath: (arguments[outputIndex + 1] as NSString).expandingTildeInPath)
        }

        #if os(macOS)
        return CacheStore.macOSFallbackURL
        #else
        return CacheStore.ubuntuDefaultURL
        #endif
    }

    private static func printJSON(_ snapshot: InsightSnapshot) {
        guard let data = try? CacheStore.encodedData(for: snapshot) else { return }
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }

    private static func printPanelJSON(_ presentation: PanelPresentation) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(presentation) else { return }
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }

    private static func printUsage() {
        print("""
        Usage:
          system-insights collect [--output PATH] [--mock] [--quiet]
          system-insights show [--output PATH]
          system-insights panel [--output PATH]

        Collect writes an InsightSnapshot JSON file and prints it to stdout unless --quiet is used.
        panel prints preformatted GNOME panel strings as JSON (Swift-derived; no duplicate logic in JS).
        Default cache:
          macOS:  ~/Library/Application Support/SystemInsights/latest.snapshot (AES-GCM encrypted)
          Ubuntu: ~/.local/share/system-insights/latest.snapshot (AES-GCM encrypted)
        """)
    }
}

await SystemInsightsCLI.main()
