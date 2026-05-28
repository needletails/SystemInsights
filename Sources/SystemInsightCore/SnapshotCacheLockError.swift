import Foundation

public enum SnapshotCacheLockError: Error, Equatable, Sendable {
    case locked
    case protectionNotConfigured
    case invalidPassword
    case invalidWrappedKey
}

extension SnapshotCacheLockError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .locked:
            return "Cache is locked. Unlock System Insights or set SYSTEM_INSIGHTS_CACHE_PASSWORD."
        case .protectionNotConfigured:
            return "Password protection is not configured for this cache."
        case .invalidPassword:
            return "Incorrect cache password."
        case .invalidWrappedKey:
            return "The wrapped cache key file is invalid or corrupted."
        }
    }
}
