import Foundation
import SystemInsightCore

@MainActor
struct DashboardSecurityState {
    enum PasswordSetupMode {
        case enable
        case change
    }

    var isUnlocked = false
    var requiresUnlock = false
    var showsPasswordSetup = false
    var passwordSetupMode: PasswordSetupMode = .enable
    var errorMessage: String?

    var isPasswordProtectionEnabled: Bool {
        CacheSecurityCoordinator.isPasswordProtectionEnabled()
    }

    init() {
        refresh()
    }

    mutating func refresh() {
        if CacheSecurityCoordinator.isPasswordProtectionEnabled() {
            _ = CacheSecurityCoordinator.hydrateStoredSessionIfAvailable()
        }
        isUnlocked = !CacheSecurityCoordinator.isPasswordProtectionEnabled() || CacheSecurityCoordinator.isUnlocked()
        requiresUnlock = CacheSecurityCoordinator.isPasswordProtectionEnabled() && !isUnlocked
        showsPasswordSetup = CacheSecurityCoordinator.isPasswordProtectionEnabled() && !isUnlocked
        if !requiresUnlock && !showsPasswordSetup {
            errorMessage = nil
        }
    }

    /// Decrypt the cache. Does not update unlock flags or run bootstrap — caller drives UI transition.
    mutating func attemptUnlock(password: String) -> Bool {
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Enter your password."
            return false
        }
        errorMessage = nil
        do {
            try CacheSecurityCoordinator.unlock(password: trimmed)
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    mutating func attemptEnablePassword(password: String, confirmPassword: String) -> Bool {
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let confirm = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Enter a password."
            return false
        }
        guard trimmed == confirm else {
            errorMessage = "Passwords do not match."
            return false
        }
        errorMessage = nil
        do {
            try CacheSecurityCoordinator.enablePasswordProtection(trimmed)
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    mutating func attemptChangePassword(
        currentPassword: String,
        password: String,
        confirmPassword: String
    ) -> Bool {
        let current = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let confirm = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !current.isEmpty else {
            errorMessage = "Enter your current password."
            return false
        }
        guard !trimmed.isEmpty else {
            errorMessage = "Enter a new password."
            return false
        }
        guard trimmed == confirm else {
            errorMessage = "New passwords do not match."
            return false
        }
        errorMessage = nil
        do {
            try CacheSecurityCoordinator.changePassword(from: current, to: trimmed)
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    mutating func markUnlocked() {
        isUnlocked = true
        requiresUnlock = false
        showsPasswordSetup = false
        errorMessage = nil
    }

    /// Reconcile UI flags with the coordinator after a successful crypto unlock.
    mutating func syncAfterAuthentication() {
        refresh()
        if isUnlocked {
            markUnlocked()
        } else {
            errorMessage = "Unlock succeeded but the cache session could not be established."
        }
    }

    mutating func presentPasswordSetup(mode: PasswordSetupMode) {
        passwordSetupMode = mode
        showsPasswordSetup = true
        requiresUnlock = false
        errorMessage = nil
    }

    mutating func lock(onLocked: (() -> Void)? = nil) {
        CacheSecurityCoordinator.lock()
        refresh()
        onLocked?()
    }
}
