import Foundation

/// Remote release metadata for notify-only update checks (no auto-install).
public struct ReleaseUpdateFeed: Codable, Sendable, Equatable {
    public var version: String
    public var downloadURL: String
    public var releaseNotes: String?
    public var ubuntuAMD64DownloadURL: String?
    public var ubuntuARM64DownloadURL: String?
    public var macOSARM64DownloadURL: String?

    public init(
        version: String,
        downloadURL: String,
        releaseNotes: String? = nil,
        ubuntuAMD64DownloadURL: String? = nil,
        ubuntuARM64DownloadURL: String? = nil,
        macOSARM64DownloadURL: String? = nil
    ) {
        self.version = version
        self.downloadURL = downloadURL
        self.releaseNotes = releaseNotes
        self.ubuntuAMD64DownloadURL = ubuntuAMD64DownloadURL
        self.ubuntuARM64DownloadURL = ubuntuARM64DownloadURL
        self.macOSARM64DownloadURL = macOSARM64DownloadURL
    }

    public func resolvedDownloadURL(for platform: ReleaseUpdatePlatform) -> URL? {
        let candidate: String?
        switch platform {
        case .ubuntuAMD64:
            candidate = ubuntuAMD64DownloadURL ?? downloadURL
        case .ubuntuARM64:
            candidate = ubuntuARM64DownloadURL ?? downloadURL
        case .macOSARM64:
            candidate = macOSARM64DownloadURL ?? downloadURL
        }
        guard let candidate, let url = URL(string: candidate) else {
            return nil
        }
        return url
    }

    public func isNewer(than installedVersion: String) -> Bool {
        ReleaseVersionComparator.isVersion(installedVersion, olderThan: version)
    }
}

public enum ReleaseUpdatePlatform: Sendable {
    case ubuntuAMD64
    case ubuntuARM64
    case macOSARM64

    #if os(macOS)
    public static var current: ReleaseUpdatePlatform { .macOSARM64 }
    #elseif arch(arm64)
    public static var current: ReleaseUpdatePlatform { .ubuntuARM64 }
    #else
    public static var current: ReleaseUpdatePlatform { .ubuntuAMD64 }
    #endif
}

public enum ReleaseUpdateConfiguration: Sendable {
    /// Override with `SYSTEM_INSIGHTS_UPDATE_FEED_URL` for staging or a self-hosted feed.
    public static var feedURL: URL? {
        if let override = ProcessInfo.processInfo.environment["SYSTEM_INSIGHTS_UPDATE_FEED_URL"],
           let url = URL(string: override) {
            return url
        }
        return defaultFeedURL
    }

    /// Set at build time via `SYSTEM_INSIGHTS_VERSION` in the Adwaita / app package, or `0.0.0-dev`.
    public static var installedVersion: String {
        if let override = ProcessInfo.processInfo.environment["SYSTEM_INSIGHTS_INSTALLED_VERSION"],
           !override.isEmpty {
            return override
        }
        return bundledVersion
    }

    public static let bundledVersion = "0.0.0-dev"
    public static let defaultFeedURL: URL? = nil
}

public enum ReleaseUpdateChecker: Sendable {
    public enum Error: Swift.Error, Equatable {
        case invalidFeedURL
        case invalidResponse
    }

    public static func fetchLatest(from url: URL) async throws -> ReleaseUpdateFeed {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 8

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw Error.invalidResponse
        }
        let decoder = JSONDecoder()
        return try decoder.decode(ReleaseUpdateFeed.self, from: data)
    }

    public static func availableUpdate(
        feedURL: URL? = ReleaseUpdateConfiguration.feedURL,
        installedVersion: String = ReleaseUpdateConfiguration.installedVersion,
        platform: ReleaseUpdatePlatform = .current
    ) async -> (feed: ReleaseUpdateFeed, downloadURL: URL)? {
        guard let feedURL else { return nil }
        guard let feed = try? await fetchLatest(from: feedURL),
              feed.isNewer(than: installedVersion),
              let downloadURL = feed.resolvedDownloadURL(for: platform) else {
            return nil
        }
        return (feed, downloadURL)
    }
}

enum ReleaseVersionComparator {
    static func isVersion(_ installed: String, olderThan latest: String) -> Bool {
        compare(installed, latest) == .orderedAscending
    }

    private static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let left = lhs.split(separator: ".", omittingEmptySubsequences: false).map { Int($0) ?? 0 }
        let right = rhs.split(separator: ".", omittingEmptySubsequences: false).map { Int($0) ?? 0 }
        let count = max(left.count, right.count)
        for index in 0..<count {
            let a = index < left.count ? left[index] : 0
            let b = index < right.count ? right[index] : 0
            if a < b { return .orderedAscending }
            if a > b { return .orderedDescending }
        }
        return .orderedSame
    }
}
