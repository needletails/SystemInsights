import Foundation
import SystemInsightCore

/// Resolves encrypted snapshot locations (mirrors the macOS app + widget layout).
enum DashboardCacheLocations {
    static var readURLs: [URL] {
        #if os(macOS)
        var urls: [URL] = [CacheStore.macOSFallbackURL]
        if let container = MacOSAppGroupConfiguration.containerURL() {
            let appGroupURL = SnapshotCacheStorage.encryptedCacheURL(in: container)
            if !urls.contains(appGroupURL) {
                urls.append(appGroupURL)
            }
        }
        return urls
        #else
        [CacheStore.ubuntuDefaultURL]
        #endif
    }

    static var primaryWriteURL: URL {
        readURLs.first ?? CacheStore.macOSFallbackURL
    }

    static func cacheExists(at url: URL) -> Bool {
        let directory = url.deletingLastPathComponent()
        let fileManager = FileManager.default
        return SnapshotCacheStorage.candidateReadURLs(in: directory).contains {
            fileManager.fileExists(atPath: $0.path)
        }
    }

    static func readSnapshot() throws -> InsightSnapshot {
        var lastError: Error?
        for url in readURLs where cacheExists(at: url) {
            do {
                return try CacheStore(url: url).read()
            } catch SnapshotCacheLockError.locked {
                lastError = SnapshotCacheLockError.locked
            } catch {
                lastError = error
            }
        }
        if let lastError {
            throw lastError
        }
        throw CocoaError(.fileReadNoSuchFile)
    }

    static func writeSnapshot(_ snapshot: InsightSnapshot) throws {
        let directories = readURLs.map { $0.deletingLastPathComponent() }
        try CacheStore.synchronizeEncryptionKeys(across: directories)

        var firstError: Error?
        var didWrite = false
        for url in readURLs {
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
}
