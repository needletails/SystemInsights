import Foundation

#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

/// In-memory encryption session for the snapshot cache.
///
/// The actor serializes unlock/lock. A narrow synchronous bridge (`syncKey`) exists so
/// legacy synchronous cache reads (widgets, CLI) can access the key without blocking
/// on the actor from arbitrary threads.
public actor SnapshotCacheSession {
    public static let shared = SnapshotCacheSession()

    /// Key mirror updated only through `install` / `clear` on the actor.
    nonisolated(unsafe) public private(set) static var syncKey: SymmetricKey?

    private var encryptionKey: SymmetricKey?

    private init() {}

    public var isUnlocked: Bool {
        encryptionKey != nil
    }

    public func install(_ key: SymmetricKey) {
        encryptionKey = key
        Self.syncKey = key
    }

    nonisolated public static func installSyncKey(_ key: SymmetricKey) {
        syncKey = key
    }

    public func clear() {
        encryptionKey = nil
        Self.syncKey = nil
    }

    nonisolated public static func clearSyncKey() {
        syncKey = nil
    }

    public func currentKey() throws -> SymmetricKey {
        guard let encryptionKey else {
            throw SnapshotCacheLockError.locked
        }
        return encryptionKey
    }

    /// Synchronous read used by ``SnapshotCacheKeyStore`` during cache I/O.
    nonisolated public static func currentKeyForSyncAccess() throws -> SymmetricKey {
        guard let syncKey else {
            throw SnapshotCacheLockError.locked
        }
        return syncKey
    }
}
