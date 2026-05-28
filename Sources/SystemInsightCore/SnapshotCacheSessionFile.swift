import Foundation

#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

#if !os(macOS)
/// Ephemeral session key on disk (mode `0600`) so CLI/GNOME can read the cache while the app is unlocked.
/// Cleared when the app locks or quits — analogous to the macOS Keychain session entry.
public enum SnapshotCacheSessionFile: Sendable {
    public static let filename = ".snapshot-session"
    private static let keyByteCount = 32

    public static func sessionFileURL(forCacheDirectory directory: URL) -> URL {
        directory.appendingPathComponent(filename, isDirectory: false)
    }

    public static func hasSessionKey(in directory: URL) -> Bool {
        FileManager.default.fileExists(atPath: sessionFileURL(forCacheDirectory: directory).path)
    }

    public static func storeSessionKey(_ key: SymmetricKey, in directory: URL) throws {
        let data = key.withUnsafeBytes { Data($0) }
        guard data.count == keyByteCount else { return }

        clearSessionKey(in: directory)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: NSNumber(value: Int16(0o700))]
        )
        let url = sessionFileURL(forCacheDirectory: directory)
        try data.write(to: url, options: .atomic)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o600))],
            ofItemAtPath: url.path
        )
    }

    public static func loadSessionKey(from directory: URL) -> SymmetricKey? {
        let url = sessionFileURL(forCacheDirectory: directory)
        guard let data = try? Data(contentsOf: url), data.count == keyByteCount else {
            return nil
        }
        return SymmetricKey(data: data)
    }

    public static func clearSessionKey(in directory: URL) {
        let url = sessionFileURL(forCacheDirectory: directory)
        try? FileManager.default.removeItem(at: url)
    }
}
#endif
