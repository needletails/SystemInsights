import CAdw
import Foundation

/// Keeps GTK `GtkEditable` text and Swift bindings in sync without clobbering in-progress typing.
enum EditableTextBinding {
    static func adopt(into text: Binding<String>, gtkValue: String) {
        if text.wrappedValue == gtkValue {
            return
        }
        if gtkValue.isEmpty, !text.wrappedValue.isEmpty {
            return
        }
        text.wrappedValue = gtkValue
    }

    static func pushToGTKIfNeeded(storage: ViewStorage, text: Binding<String>) {
        let gtkText = String(cString: gtk_editable_get_text(storage.opaquePointer))
        let swiftText = text.wrappedValue
        if gtkText == swiftText {
            return
        }
        if gtkText.isEmpty, !swiftText.isEmpty {
            gtk_editable_set_text(storage.opaquePointer, swiftText)
            return
        }
        if !gtkText.isEmpty {
            return
        }
        gtk_editable_set_text(storage.opaquePointer, swiftText)
    }
}
