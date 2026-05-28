//
//  PasswordEntryRow+.swift
//  Adwaita
//
//  Created by david-swift on 20.01.24.
//

import CAdw

extension PasswordEntryRow {

    /// Initialize an entry row.
    /// - Parameters:
    ///     - title: The row's title.
    ///     - text: The text.
    public init(_ title: String, text: Binding<String>) {
        self.init()
        self = self.title(title)
        updateFunctions.append { storage, _, _ in
            GtkPasswordTextSync.wire(storage: storage, text: text)
        }
    }

    /// Set the entry row's subtitle.
    /// - Parameter subtitle: The subtitle.
    /// - Returns: The entry row.
    public func onSubmit(_ onSubmit: @escaping () -> Void) -> Self {
        apply(onSubmit)
    }

}
