import Foundation

#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

public enum SnapshotCachePasswordProtection: Sendable {
    public static let wrapFilename = ".snapshot-key-wrap"
    private static let magic = Data([0x53, 0x49, 0x4e, 0x4b]) // SINK
    private static let formatVersion: UInt8 = 1
    private static let saltByteCount = 16
    private static let masterKeyByteCount = 32
    public static let pbkdf2IterationCount = 600_000

    public static func wrapFileURL(forCacheDirectory directory: URL) -> URL {
        directory.appendingPathComponent(wrapFilename, isDirectory: false)
    }

    public static func isProtectionEnabled(in directory: URL) -> Bool {
        FileManager.default.fileExists(atPath: wrapFileURL(forCacheDirectory: directory).path)
    }

    public static func setupPassword(_ password: String, in directory: URL) throws -> SymmetricKey {
        let masterKey = SymmetricKey(size: .bits256)
        try storeWrappedKey(masterKey, password: password, in: directory)
        return masterKey
    }

    public static func unlock(password: String, in directory: URL) throws -> SymmetricKey {
        let wrapURL = wrapFileURL(forCacheDirectory: directory)
        guard FileManager.default.fileExists(atPath: wrapURL.path) else {
            throw SnapshotCacheLockError.protectionNotConfigured
        }

        let payload = try Data(contentsOf: wrapURL)
        guard let (salt, sealedBox) = try parseWrapPayload(payload) else {
            throw SnapshotCacheLockError.invalidWrappedKey
        }

        let derivedKey = deriveKey(from: password, salt: salt)
        do {
            let masterData = try AES.GCM.open(sealedBox, using: derivedKey)
            guard masterData.count == masterKeyByteCount else {
                throw SnapshotCacheLockError.invalidWrappedKey
            }
            return SymmetricKey(data: masterData)
        } catch {
            throw SnapshotCacheLockError.invalidPassword
        }
    }

    public static func changePassword(
        from oldPassword: String,
        to newPassword: String,
        in directory: URL
    ) throws -> SymmetricKey {
        let masterKey = try unlock(password: oldPassword, in: directory)
        try storeWrappedKey(masterKey, password: newPassword, in: directory)
        return masterKey
    }

    public static func storeWrappedKey(_ masterKey: SymmetricKey, password: String, in directory: URL) throws {
        let salt = randomSalt()
        let derivedKey = deriveKey(from: password, salt: salt)
        let masterData = masterKeyData(masterKey)
        let sealed = try AES.GCM.seal(masterData, using: derivedKey)
        guard let combined = sealed.combined else {
            throw SnapshotCacheLockError.invalidWrappedKey
        }

        var payload = Data()
        payload.append(magic)
        payload.append(formatVersion)
        payload.append(salt)
        payload.append(combined)

        let directoryURL = directory
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: NSNumber(value: Int16(0o700))]
        )

        let wrapURL = wrapFileURL(forCacheDirectory: directory)
        try payload.write(to: wrapURL, options: .atomic)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o600))],
            ofItemAtPath: wrapURL.path
        )

        let unprotectedKeyURL = SnapshotCacheKeyStore.keyFileURL(forCacheDirectory: directory)
        if FileManager.default.fileExists(atPath: unprotectedKeyURL.path) {
            try FileManager.default.removeItem(at: unprotectedKeyURL)
        }
    }

    public static func removeProtection(in directory: URL) throws {
        let wrapURL = wrapFileURL(forCacheDirectory: directory)
        if FileManager.default.fileExists(atPath: wrapURL.path) {
            try FileManager.default.removeItem(at: wrapURL)
        }
    }

    private static func deriveKey(from password: String, salt: Data) -> SymmetricKey {
        let derived = pbkdf2SHA256(
            password: Data(password.utf8),
            salt: salt,
            iterations: pbkdf2IterationCount,
            keyLength: masterKeyByteCount
        )
        return SymmetricKey(data: derived)
    }

    private static func pbkdf2SHA256(password: Data, salt: Data, iterations: Int, keyLength: Int) -> Data {
        var derived = Data()
        var blockIndex: UInt32 = 1
        while derived.count < keyLength {
            var block = salt
            var bigEndian = blockIndex.bigEndian
            withUnsafeBytes(of: &bigEndian) { block.append(contentsOf: $0) }

            var u = Data(HMAC<SHA256>.authenticationCode(for: block, using: SymmetricKey(data: password)))
            var digest = u
            if iterations > 1 {
                for _ in 1..<iterations {
                    u = Data(HMAC<SHA256>.authenticationCode(for: u, using: SymmetricKey(data: password)))
                    digest = Data(zip(digest, u).map { $0 ^ $1 })
                }
            }
            derived.append(digest)
            blockIndex += 1
        }
        return derived.prefix(keyLength)
    }

    private static func parseWrapPayload(_ payload: Data) throws -> (salt: Data, sealedBox: AES.GCM.SealedBox)? {
        guard payload.starts(with: magic), payload.count > magic.count + 1 + saltByteCount else {
            return nil
        }
        guard payload[magic.count] == formatVersion else {
            return nil
        }
        let saltStart = magic.count + 1
        let salt = payload[saltStart..<(saltStart + saltByteCount)]
        let combined = payload[(saltStart + saltByteCount)...]
        return (Data(salt), try AES.GCM.SealedBox(combined: Data(combined)))
    }

    private static func randomSalt() -> Data {
        SymmetricKey(size: .bits256).withUnsafeBytes { Data($0.prefix(saltByteCount)) }
    }

    private static func masterKeyData(_ key: SymmetricKey) -> Data {
        key.withUnsafeBytes { Data($0) }
    }
}
