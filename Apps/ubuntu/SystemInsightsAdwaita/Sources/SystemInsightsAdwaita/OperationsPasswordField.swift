import Adwaita
import Foundation

/// Password field with Adwaita's reveal control (`AdwPasswordEntryRow`) and GTK-safe text sync.
struct OperationsPasswordField: View {
    let label: String
    @Binding var text: String
    var onActivate: (() -> Void)?

    var view: Body {
        PasswordEntryRow(label, text: $text)
            .activatesDefault(false)
            .entryActivated {
                onActivate?()
            }
            .hexpand()
            .style("operations-password-field")
    }
}
