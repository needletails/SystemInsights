//
//  WrapMode.swift
//  Adwaita
//
//  Created by mlm on 24.08.25.
//

import CAdw

/// Wrap modes for `TextView`/`TextEditor`
public enum WrapMode: GtkWrapMode, RawRepresentable {

    // swiftlint:disable discouraged_none_name
    /// GTK_WRAP_NONE
    case none
    // swiftlint:enable discouraged_none_name
    /// GTK_WRAP_CHAR
    case char
    /// GTK_WRAP_WORD
    case word
    /// GTK_WRAP_WORD_CHAR
    case wordChar

    /// Get the GtkWrapMode.
    public var rawValue: GtkWrapMode {
        switch self {
        case .none:
            GTK_WRAP_NONE
        case .char:
            GTK_WRAP_CHAR
        case .word:
            GTK_WRAP_WORD
        case .wordChar:
            GTK_WRAP_WORD_CHAR
        }
    }

    /// Initialize from the GtkWrapMode.
    /// - Parameter rawValue: The GtkWrapMode.
    public init?(rawValue: GtkWrapMode) {
        switch rawValue {
        case GTK_WRAP_NONE:
            self = .none
        case GTK_WRAP_CHAR:
            self = .char
        case GTK_WRAP_WORD:
            self = .word
        case GTK_WRAP_WORD_CHAR:
            self = .wordChar
        default:
            return nil
        }
    }
}
