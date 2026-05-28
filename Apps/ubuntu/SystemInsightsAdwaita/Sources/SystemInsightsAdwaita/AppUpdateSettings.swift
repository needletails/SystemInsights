import Foundation

/// Configure where the Ubuntu app checks for newer releases (notify-only).
enum AppUpdateSettings {
    private static let repository = "needletails/SystemInsights"

    /// HTTPS JSON feed (`Schema/release.json`). CI uploads `release.json` on each GitHub Release.
    static var feedURL: URL? {
        if let override = ProcessInfo.processInfo.environment["SYSTEM_INSIGHTS_UPDATE_FEED_URL"],
           let url = URL(string: override) {
            return url
        }
        return URL(string: "https://github.com/\(repository)/releases/latest/download/release.json")
    }

    static var installedVersion: String {
        if let override = ProcessInfo.processInfo.environment["SYSTEM_INSIGHTS_INSTALLED_VERSION"],
           !override.isEmpty {
            return override
        }
        if let fromInstall = InstalledVersionReader.fromInstallLayout() {
            return fromInstall
        }
        return "0.0.0-dev"
    }
}

enum InstalledVersionReader {
    static func fromInstallLayout() -> String? {
        let executable = URL(fileURLWithPath: CommandLine.arguments[0])
        let candidates = [
            executable.deletingLastPathComponent().appendingPathComponent("VERSION"),
            executable.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("VERSION"),
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".local/share/system-insights/VERSION")
        ]
        for url in candidates {
            guard let data = try? Data(contentsOf: url),
                  let text = String(data: data, encoding: .utf8) else {
                continue
            }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return nil
    }
}
