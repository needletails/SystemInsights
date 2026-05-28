//
//  ColorScheme.swift
//  Adwaita
//
//  Created by david-swift on 01.02.26.
//

import CAdw

/// The system color scheme.
public enum ColorScheme: UInt32 {

    /// The dark color scheme.
    case dark = 2
    /// The light color scheme.
    case light = 3

    /// The ColorScheme value as GtkInterfaceColorScheme.
    var gtkValue: GtkInterfaceColorScheme {
        .init(rawValue)
    }

}
