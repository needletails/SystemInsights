import Foundation

#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

public enum SnapshotCacheKeyStore: Sendable {
    public static let keyFilename = ".snapshot-key"

    public enum Error: Swift.Error, Equatable {
        case invalidKeyMaterial
        case keyUnavailable
    }

    public static func keyFileURL(forCacheDirectory directory: URL) -> URL {
        directory.appendingPathComponent(keyFilename, isDirectory: false)
    }

    public static func encryptionKey(forCacheDirectory directory: URL) throws -> SymmetricKey {
        if let override = ProcessInfo.processInfo.environment["SYSTEM_INSIGHTS_CACHE_KEY_FILE"],
           !override.isEmpty {
            return try loadKey(from: URL(fileURLWithPath: (override as NSString).expandingTildeInPath))
        }

        if SnapshotCacheSession.syncKey != nil {
            return try SnapshotCacheSession.currentKeyForSyncAccess()
        }

        #if os(macOS)
        if let keychainKey = SnapshotCacheKeychain.loadSessionKey() {
            SnapshotCacheSession.installSyncKey(keychainKey)
            return keychainKey
        }
        #else
        if let sessionKey = SnapshotCacheSessionFile.loadSessionKey(from: directory) {
            SnapshotCacheSession.installSyncKey(sessionKey)
            return sessionKey
        }
        #endif

        if SnapshotCachePasswordProtection.isProtectionEnabled(in: directory) {
            throw SnapshotCacheLockError.locked
        }

        return try fileBasedKey(forCacheDirectory: directory)
    }

    public static func synchronizeKey(from sourceDirectory: URL, to destinationDirectory: URL) throws {
        if SnapshotCachePasswordProtection.isProtectionEnabled(in: sourceDirectory)
            || SnapshotCachePasswordProtection.isProtectionEnabled(in: destinationDirectory) {
            return
        }

        let sourceURL = keyFileURL(forCacheDirectory: sourceDirectory)
        let destinationURL = keyFileURL(forCacheDirectory: destinationDirectory)
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: sourceURL.path) {
            try fileManager.createDirectory(
                at: destinationDirectory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: NSNumber(value: Int16(0o700))]
            )
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            try fileManager.setAttributes(
                [.posixPermissions: NSNumber(value: Int16(0o600))],
                ofItemAtPath: destinationURL.path
            )
            return
        }

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.createDirectory(
                at: sourceDirectory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: NSNumber(value: Int16(0o700))]
            )
            try fileManager.copyItem(at: destinationURL, to: sourceURL)
            try fileManager.setAttributes(
                [.posixPermissions: NSNumber(value: Int16(0o600))],
                ofItemAtPath: sourceURL.path
            )
            return
        }

        let key = try fileBasedKey(forCacheDirectory: sourceDirectory)
        try storeFileKey(key, at: destinationURL)
    }

    public static func loadKey(from url: URL) throws -> SymmetricKey {
        let data = try Data(contentsOf: url)
        guard data.count == 32 else {
            throw Error.invalidKeyMaterial
        }
        return SymmetricKey(data: data)
    }

    private static func fileBasedKey(forCacheDirectory directory: URL) throws -> SymmetricKey {
        let keyURL = keyFileURL(forCacheDirectory: directory)
        if FileManager.default.fileExists(atPath: keyURL.path) {
            return try loadKey(from: keyURL)
        }

        let key = SymmetricKey(size: .bits256)
        try storeFileKey(key, at: keyURL)
        return key
    }

    private static func storeFileKey(_ key: SymmetricKey, at url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: NSNumber(value: Int16(0o700))]
        )
        let keyData = key.withUnsafeBytes { Data($0) }
        guard keyData.count == 32 else {
            throw Error.invalidKeyMaterial
        }
        try keyData.write(to: url, options: .atomic)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o600))],
            ofItemAtPath: url.path
        )
    }
}
