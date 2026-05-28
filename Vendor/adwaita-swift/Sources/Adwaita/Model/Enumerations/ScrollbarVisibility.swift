//
//  ContentFit.swift
//  Adwaita
//
//  Created by david-swift on 19.07.24.
//

import CAdw

/// The visibility of a scroll bar.
public enum ScrollbarVisibility: UInt32 {

    /// The scrollbar is always visible. The view size is independent of the content.
    case alwaysVisible
    /// The scrollbar will appear and disappear as necessary.
    case automatic
    /// The scrollbar should never appear. In this mode the content determines the size.
    case never
    /// Don’t show a scrollbar, but don’t force the size to follow the content.
    case external

    /// The ScrollbarVisibility value as a GtkPolicyType value.
    var gtkValue: GtkPolicyType {
        .init(rawValue)
    }

}
