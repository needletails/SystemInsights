import SwiftUI
import SystemInsightCore

struct CacheUnlockView: View {
    @Bindable var model: InsightViewModel
    @State private var password = ""
    @FocusState private var isPasswordFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Unlock System Insights", systemImage: "lock.fill")
                .font(.headline)

            Text("Enter your cache password to decrypt locally stored health data.")
                .font(.caption)
                .foregroundStyle(.secondary)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .focused($isPasswordFocused)
                .onSubmit(unlock)

            if let error = model.securityErrorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button("Unlock", action: unlock)
                .keyboardShortcut(.defaultAction)
                .disabled(password.isEmpty || model.isSecurityBusy)
        }
        .frame(width: 320)
        .onAppear {
            isPasswordFocused = true
        }
    }

    private func unlock() {
        model.unlock(password: password)
    }
}

struct CachePasswordSetupView: View {
    @Bindable var model: InsightViewModel
    let mode: PasswordSetupMode
    @State private var password = ""
    @State private var confirmation = ""
    @State private var currentPassword = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case current
        case new
        case confirm
    }

    enum PasswordSetupMode {
        case enable
        case change
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "key.fill")
                .font(.headline)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            if mode == .change {
                SecureField("Current password", text: $currentPassword)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .current)
            }

            SecureField("New password", text: $password)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .new)

            SecureField("Confirm password", text: $confirmation)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .confirm)

            if let error = model.securityErrorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                if mode == .enable {
                    Button("Not Now") {
                        model.dismissPasswordSetup()
                    }
                }

                Spacer()

                Button(primaryActionTitle, action: submit)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSubmit || model.isSecurityBusy)
            }
        }
        .frame(width: 340)
        .onAppear {
            focusedField = mode == .change ? .current : .new
        }
    }

    private var title: String {
        switch mode {
        case .enable: return "Protect Cache with Password"
        case .change: return "Change Cache Password"
        }
    }

    private var subtitle: String {
        switch mode {
        case .enable:
            return "Your snapshot is encrypted at rest. The password is required each time you open the app. It is not stored in plain text."
        case .change:
            return "Choose a new password. You will need it the next time the app starts."
        }
    }

    private var primaryActionTitle: String {
        mode == .enable ? "Enable Protection" : "Update Password"
    }

    private var canSubmit: Bool {
        guard password.count >= 8, password == confirmation else { return false }
        if mode == .change {
            return !currentPassword.isEmpty
        }
        return true
    }

    private func submit() {
        switch mode {
        case .enable:
            model.enablePasswordProtection(password: password)
        case .change:
            model.changePassword(current: currentPassword, new: password)
        }
    }
}
