import Foundation

#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

public enum SnapshotCacheCipher: Sendable {
    public static let magic = Data([0x53, 0x49, 0x4e, 0x53]) // SINS
    public static let formatVersion: UInt8 = 1

    public enum Error: Swift.Error, Equatable {
        case invalidPayload
        case decryptionFailed
    }

    public static func isEncrypted(_ data: Data) -> Bool {
        data.starts(with: magic)
    }

    public static func seal(_ plaintext: Data, using key: SymmetricKey) throws -> Data {
        let sealed = try AES.GCM.seal(plaintext, using: key)
        guard let combined = sealed.combined else {
            throw Error.invalidPayload
        }
        var payload = Data()
        payload.append(magic)
        payload.append(formatVersion)
        payload.append(combined)
        return payload
    }

    public static func open(_ payload: Data, using key: SymmetricKey) throws -> Data {
        guard payload.starts(with: magic), payload.count > magic.count + 1 else {
            throw Error.invalidPayload
        }
        let version = payload[magic.count]
        guard version == formatVersion else {
            throw Error.invalidPayload
        }
        let combined = payload.dropFirst(magic.count + 1)
        do {
            let box = try AES.GCM.SealedBox(combined: Data(combined))
            return try AES.GCM.open(box, using: key)
        } catch {
            throw Error.decryptionFailed
        }
    }
}
