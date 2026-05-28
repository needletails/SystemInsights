import Foundation

#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

#if os(macOS)
import Security

public enum SnapshotCacheKeychain {
    private static let service = "com.needletails.SystemInsights.snapshot-session"
    private static let account = "v1"
    private static let keyByteCount = 32

    public static func storeSessionKey(_ key: SymmetricKey) throws {
        let data = key.withUnsafeBytes { Data($0) }
        guard data.count == keyByteCount else { return }

        clearSessionKey()

        var query = baseQuery()
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status)
        }
    }

    public static func loadSessionKey() -> SymmetricKey? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data, data.count == keyByteCount else {
            return nil
        }
        return SymmetricKey(data: data)
    }

    public static func hasSessionKey() -> Bool {
        loadSessionKey() != nil
    }

    public static func clearSessionKey() {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            return
        }
    }

    private static func baseQuery() -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        if let accessGroup = keychainAccessGroup() {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }

    private static func keychainAccessGroup() -> String? {
        if let fromEnvironment = ProcessInfo.processInfo.environment["SYSTEM_INSIGHTS_KEYCHAIN_ACCESS_GROUP"],
           !fromEnvironment.isEmpty {
            return fromEnvironment
        }
        if let fromBundle = Bundle.main.object(forInfoDictionaryKey: "SystemInsightsKeychainAccessGroup") as? String,
           !fromBundle.isEmpty,
           !fromBundle.contains("$(") {
            return fromBundle
        }
        return nil
    }

    public enum KeychainError: Error {
        case unhandled(OSStatus)
    }
}
#endif
