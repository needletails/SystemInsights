//
//  ToolbarStyle.swift
//  Adwaita
//
//  Created by david-swift on 15.04.25.
//

import CAdw

/// The top and bottom bar styles.
public enum ToolbarStyle: UInt32 {

    /// No background, shadow only for scrolled content.
    case flat
    /// Opaque background with a persistent shadow.
    case raised
    /// Opaque background with a persistent border.
    case raisedBorder

    /// The ToolbarStyle value as an AdwToolbarStyle value.
    var gtkValue: AdwToolbarStyle {
        .init(rawValue)
    }

}
