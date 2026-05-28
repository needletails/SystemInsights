import Foundation

public enum SnapshotCacheStorage: Sendable {
    public static let encryptedFilename = "latest.snapshot"

    public static func encryptedCacheURL(in directory: URL) -> URL {
        directory.appendingPathComponent(encryptedFilename, isDirectory: false)
    }

    public static func candidateReadURLs(in directory: URL) -> [URL] {
        [encryptedCacheURL(in: directory)]
    }

    public static func protectPayload(_ plaintext: Data, cacheDirectory: URL) throws -> Data {
        let key = try SnapshotCacheKeyStore.encryptionKey(forCacheDirectory: cacheDirectory)
        return try SnapshotCacheCipher.seal(plaintext, using: key)
    }

    public static func exposePayload(_ storedData: Data, cacheDirectory: URL) throws -> Data {
        guard SnapshotCacheCipher.isEncrypted(storedData) else {
            throw SnapshotCacheCipher.Error.invalidPayload
        }
        let key = try SnapshotCacheKeyStore.encryptionKey(forCacheDirectory: cacheDirectory)
        return try SnapshotCacheCipher.open(storedData, using: key)
    }
}
