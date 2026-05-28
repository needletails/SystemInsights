import Adwaita
import Foundation

/// Password unlock UI. Keeps GTK `notify::text` on local `@State` only — never on ``DashboardView``.
struct CacheUnlockPanel: View {
    let errorMessage: String?
    let onSubmit: (String) -> Void
    @State private var password = PasswordTextBuffer()

    var view: Body {
        VStack {
            Box {
                VStack {
                    Text("Unlock encrypted cache")
                        .title2()
                    Text("Enter the password you chose when password protection was enabled.")
                        .dimLabel()
                        .style("operations-security-copy")
                    OperationsPasswordField(label: "Password", text: password.binding) {
                        submit()
                    }
                    .id("unlock-password-entry")
                    CacheSecurityErrorText(message: errorMessage)
                    HStack(spacing: 12) {
                        Button("Unlock") {
                            submit()
                        }
                        .pill()
                        .style("operations-primary-action")
                        .hexpand()
                    }
                    .style("operations-security-actions")
                }
            }
            .padding()
            .style("operations-surface")
            .style("operations-security-card")
            .frame(maxWidth: 420)
        }
        .hexpand()
        .vexpand()
        .halign(.center)
        .valign(.center)
        .padding(24)
    }

    private func submit() {
        onSubmit(password.value)
    }
}

/// Password setup UI. Field text stays in local buffers until submit.
struct CachePasswordSetupPanel: View {
    let mode: DashboardSecurityState.PasswordSetupMode
    let errorMessage: String?
    let onSubmit: (_ current: String, _ password: String, _ confirm: String) -> Void
    @State private var current = PasswordTextBuffer()
    @State private var password = PasswordTextBuffer()
    @State private var confirm = PasswordTextBuffer()

    var view: Body {
        VStack {
            Box {
                VStack {
                    Text(mode == .enable ? "Enable password protection" : "Change password")
                        .title2()
                    Text(setupDescription)
                        .dimLabel()
                        .style("operations-security-copy")
                    if mode == .change {
                        OperationsPasswordField(label: "Current password", text: current.binding)
                    }
                    OperationsPasswordField(
                        label: mode == .enable ? "Password" : "New password",
                        text: password.binding
                    )
                    OperationsPasswordField(label: "Confirm password", text: confirm.binding) {
                        submit()
                    }
                    CacheSecurityErrorText(message: errorMessage)
                    HStack(spacing: 12) {
                        Button(mode == .enable ? "Enable protection" : "Update password") {
                            submit()
                        }
                        .pill()
                        .style("operations-primary-action")
                        .hexpand()
                    }
                    .style("operations-security-actions")
                }
            }
            .padding()
            .style("operations-surface")
            .style("operations-security-card")
            .frame(maxWidth: 420)
        }
        .hexpand()
        .vexpand()
        .halign(.center)
        .valign(.center)
        .padding(24)
    }

    private var setupDescription: String {
        switch mode {
        case .enable:
            "Encrypt cached snapshots on disk. You will need this password to unlock the cache on this machine."
        case .change:
            "Enter your current password and a new password. Cached data will be re-encrypted."
        }
    }

    private func submit() {
        onSubmit(current.value, password.value, confirm.value)
    }
}

/// Error line isolated so security state updates do not re-sync the password GTK entry.
private struct CacheSecurityErrorText: View {
    let message: String?

    var view: Body {
        if let message, !message.isEmpty {
            Text(message)
                .error()
        }
    }
}
