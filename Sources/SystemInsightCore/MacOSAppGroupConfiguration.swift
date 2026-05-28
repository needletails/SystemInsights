import Foundation

#if os(macOS)
/// Resolves the macOS App Group identifier from the environment or the host app bundle — never hard-coded to a Team ID.
public enum MacOSAppGroupConfiguration: Sendable {
    public static let identifierInfoKey = "SystemInsightsAppGroupIdentifier"
    public static let environmentVariable = "SYSTEM_INSIGHTS_APP_GROUP"

    public static func resolvedIdentifier(bundle: Bundle = .main) -> String? {
        if let override = ProcessInfo.processInfo.environment[environmentVariable]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !override.isEmpty {
            return override
        }
        guard
            let plistValue = bundle.object(forInfoDictionaryKey: identifierInfoKey) as? String,
            !plistValue.isEmpty,
            !plistValue.contains("$(")
        else {
            return nil
        }
        return plistValue
    }

    public static func containerURL(bundle: Bundle = .main) -> URL? {
        guard let identifier = resolvedIdentifier(bundle: bundle) else {
            return nil
        }
        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
        ) {
            return container
        }
        let manual = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Group Containers/\(identifier)", isDirectory: true)
        return FileManager.default.fileExists(atPath: manual.path) ? manual : nil
    }
}
#endif
