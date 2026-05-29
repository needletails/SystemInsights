import Foundation

#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

public enum CacheSecurityCoordinator: Sendable {
    public static func primaryCacheDirectory() -> URL {
        #if os(macOS)
        for directory in macOSCacheDirectories() {
            if SnapshotCachePasswordProtection.isProtectionEnabled(in: directory) {
                return directory
            }
        }
        return CacheStore.macOSFallbackURL.deletingLastPathComponent()
        #else
        return CacheStore.ubuntuDefaultURL.deletingLastPathComponent()
        #endif
    }

    #if os(macOS)
    private static func macOSCacheDirectories() -> [URL] {
        var directories = [CacheStore.macOSFallbackURL.deletingLastPathComponent()]
        if let container = MacOSAppGroupConfiguration.containerURL(),
           !directories.contains(container) {
            directories.insert(container, at: 0)
        }
        return directories
    }
    #endif

    public static func isPasswordProtectionEnabled() -> Bool {
        #if os(macOS)
        macOSCacheDirectories().contains {
            SnapshotCachePasswordProtection.isProtectionEnabled(in: $0)
        }
        #else
        SnapshotCachePasswordProtection.isProtectionEnabled(in: primaryCacheDirectory())
        #endif
    }

    /// Whether the in-memory session key is installed (required for cache I/O).
    public static func isUnlocked() -> Bool {
        SnapshotCacheSession.syncKey != nil
    }

    /// Restores a persisted session key into memory after launch or before UI refresh.
    @discardableResult
    public static func hydrateStoredSessionIfAvailable() -> Bool {
        guard SnapshotCacheSession.syncKey == nil else { return true }
        #if os(macOS)
        guard let key = SnapshotCacheKeychain.loadSessionKey() else { return false }
        #else
        guard let key = SnapshotCacheSessionFile.loadSessionKey(from: primaryCacheDirectory()) else {
            return false
        }
        #endif
        installSessionKey(key)
        return true
    }

    public static func unlock(password: String) throws {
        let directory = primaryCacheDirectory()
        let key = try SnapshotCachePasswordProtection.unlock(password: password, in: directory)
        installSessionKey(key)
        #if os(macOS)
        try SnapshotCacheKeychain.storeSessionKey(key)
        #else
        try SnapshotCacheSessionFile.storeSessionKey(key, in: directory)
        #endif
    }

    public static func unlockFromEnvironmentIfAvailable() throws {
        guard let password = ProcessInfo.processInfo.environment["SYSTEM_INSIGHTS_CACHE_PASSWORD"],
              !password.isEmpty else {
            return
        }
        try unlock(password: password)
    }

    /// Restores a session after the user cancels a voluntary lock (toolbar or settings).
    public static func restoreUnlockedSession(_ key: SymmetricKey) {
        installSessionKey(key)
        #if os(macOS)
        try? SnapshotCacheKeychain.storeSessionKey(key)
        #else
        try? SnapshotCacheSessionFile.storeSessionKey(key, in: primaryCacheDirectory())
        #endif
    }

    public static func lock() {
        Task { await SnapshotCacheSession.shared.clear() }
        SnapshotCacheSession.clearSyncKey()
        #if os(macOS)
        SnapshotCacheKeychain.clearSessionKey()
        #else
        SnapshotCacheSessionFile.clearSessionKey(in: primaryCacheDirectory())
        #endif
    }

    public static func enablePasswordProtection(_ password: String) throws {
        let directory = primaryCacheDirectory()
        let key = try SnapshotCachePasswordProtection.setupPassword(password, in: directory)
        installSessionKey(key)
        #if os(macOS)
        try SnapshotCacheKeychain.storeSessionKey(key)
        #else
        try SnapshotCacheSessionFile.storeSessionKey(key, in: directory)
        #endif
    }

    public static func changePassword(from oldPassword: String, to newPassword: String) throws {
        let directory = primaryCacheDirectory()
        let key = try SnapshotCachePasswordProtection.changePassword(
            from: oldPassword,
            to: newPassword,
            in: directory
        )
        installSessionKey(key)
        #if os(macOS)
        try SnapshotCacheKeychain.storeSessionKey(key)
        #else
        try SnapshotCacheSessionFile.storeSessionKey(key, in: directory)
        #endif
    }

    private static func installSessionKey(_ key: SymmetricKey) {
        SnapshotCacheSession.installSyncKey(key)
        Task { await SnapshotCacheSession.shared.adoptSyncKey() }
    }

    public static func disablePasswordProtection(password: String) throws {
        _ = try SnapshotCachePasswordProtection.unlock(password: password, in: primaryCacheDirectory())
        try SnapshotCachePasswordProtection.removeProtection(in: primaryCacheDirectory())
        lock()
    }
}
