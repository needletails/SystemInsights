import CAdw
import Foundation

/// `AdwPasswordEntryRow` sometimes emits `notify::text` with an empty string while typing.
/// GTK is the source of truth: never push Swift into the entry, and restore spurious clears.
enum GtkPasswordTextSync {
    private static let lastGTKTextKey = "gtkPasswordLastText"
    private static let wiredKey = "gtkPasswordWired"

    static func wire(storage: ViewStorage, text: Binding<String>) {
        guard storage.fields[wiredKey] == nil else {
            return
        }
        storage.fields[wiredKey] = true

        storage.notify(name: "text", id: "gtk-password-sync") {
            let pointer = storage.opaquePointer
            let gtkValue = String(cString: gtk_editable_get_text(pointer))
            let lastGTK = storage.fields[lastGTKTextKey] as? String ?? ""

            if gtkValue.isEmpty, !lastGTK.isEmpty {
                // Spurious clears arrive before Swift state catches up (focus / first key).
                // Real deletes happen after `text` already mirrors GTK content.
                if text.wrappedValue.isEmpty {
                    gtk_editable_set_text(pointer, lastGTK)
                    return
                }
                storage.fields[lastGTKTextKey] = ""
                if text.wrappedValue != "" {
                    text.wrappedValue = ""
                }
                return
            }

            if gtkValue != lastGTK {
                storage.fields[lastGTKTextKey] = gtkValue
            }
            if text.wrappedValue != gtkValue {
                text.wrappedValue = gtkValue
            }
        }
    }
}
