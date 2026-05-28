//
//  EntryRow+.swift
//  Adwaita
//
//  Created by david-swift on 20.01.24.
//

import CAdw

extension EntryRow {

    /// Initialize an entry row.
    /// - Parameters:
    ///     - title: The row's title.
    ///     - text: The text.
    public init(_ title: String, text: Binding<String>) {
        self.init()
        self = self.title(title)
        updateFunctions.append { storage, _, updateProperties in
            storage.notify(name: "text", id: "swift-text") {
                let newValue = String(cString: gtk_editable_get_text(storage.opaquePointer))
                EditableTextBinding.adopt(into: text, gtkValue: newValue)
            }
            guard updateProperties else {
                return
            }
            EditableTextBinding.pushToGTKIfNeeded(storage: storage, text: text)
        }
    }

    /// Set the entry row's subtitle.
    /// - Parameter subtitle: The subtitle.
    /// - Returns: The entry row.
    public func onSubmit(_ onSubmit: @escaping () -> Void) -> Self {
        showApplyButton()
            .apply(onSubmit)
    }

    /// Let the user securely enter private text.
    /// - Parameter: The text.
    /// - Returns: The entry row.
    public func secure(text: Binding<String>? = nil) -> PasswordEntryRow {
        .init(title ?? "", text: text ?? .constant(""))
            .activatesDefault(activatesDefault)
            .enableEmojiCompletion(enableEmojiCompletion)
            .showApplyButton(showApplyButton)
            .titleSelectable(titleSelectable)
            .useMarkup(useMarkup)
            .useUnderline(useUnderline)
            .apply(apply ?? { })
            .entryActivated(entryActivated ?? { })
    }

}
