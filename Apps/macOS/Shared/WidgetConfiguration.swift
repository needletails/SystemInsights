import Foundation
import SystemInsightCore

enum SharedWidgetConfiguration {
    static let kind = "SystemInsightsWidget"
    static let dashboardURL = URL(string: "systeminsights://dashboard")!
    static var appGroupIdentifier: String? {
        MacOSAppGroupConfiguration.resolvedIdentifier()
    }

    static var cacheURL: URL {
        cacheURLs.first ?? CacheStore.macOSFallbackURL
    }

    static var cacheURLs: [URL] {
        var urls: [URL] = []
        if let appGroupURL = appGroupContainerURL {
            urls.append(SnapshotCacheStorage.encryptedCacheURL(in: appGroupURL))
        }
        urls.append(CacheStore.macOSFallbackURL)
        return urls
    }

    static func readSnapshot() -> InsightSnapshot? {
        readSnapshotWithDiagnostics().snapshot
    }

    static func readSnapshotWithDiagnostics() -> (snapshot: InsightSnapshot?, diagnostic: String) {
        for url in cacheURLs {
            guard FileManager.default.fileExists(atPath: url.path) else {
                continue
            }

            do {
                let snapshot = try CacheStore(url: url).read()
                return (snapshot, "Read OK")
            } catch SnapshotCacheLockError.locked {
                return (
                    nil,
                    "Cache is locked. Open System Insights and enter your password."
                )
            } catch {
                continue
            }
        }

        if CacheSecurityCoordinator.isPasswordProtectionEnabled() {
            return (
                nil,
                "Cache is locked. Open System Insights and enter your password."
            )
        }

        if appGroupContainerURL == nil {
            return noCachedSnapshot(diagnosticPrefix: "App Group unavailable")
        }
        return noCachedSnapshot(diagnosticPrefix: "Encrypted cache missing")
    }

    private static func noCachedSnapshot(diagnosticPrefix: String) -> (snapshot: InsightSnapshot?, diagnostic: String) {
        (nil, "\(diagnosticPrefix) | Open the app to refresh")
    }

    static func writeSnapshot(_ snapshot: InsightSnapshot) throws {
        let directories = cacheURLs.map { $0.deletingLastPathComponent() }
        try CacheStore.synchronizeEncryptionKeys(across: directories)

        var firstError: Error?
        var didWrite = false

        for url in cacheURLs {
            do {
                try CacheStore(url: url).write(snapshot)
                didWrite = true
            } catch {
                firstError = firstError ?? error
            }
        }

        if !didWrite, let firstError {
            throw firstError
        }
    }

    private static var appGroupContainerURL: URL? {
        MacOSAppGroupConfiguration.containerURL()
    }
}
