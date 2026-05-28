import Adwaita
import Foundation

/// Holds password field text without triggering Adwaita view rebuilds on every keystroke.
final class PasswordTextBuffer: @unchecked Sendable {
    var value = ""
}

extension PasswordTextBuffer {
    var binding: Binding<String> {
        Binding(
            get: { self.value },
            set: { self.value = $0 }
        )
    }
}
