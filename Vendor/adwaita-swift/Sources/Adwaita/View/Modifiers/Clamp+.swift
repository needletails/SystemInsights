//
//  Clamp+.swift
//  Adwaita
//
//  Created by david-swift on 20.01.24.
//

import CAdw

extension Clamp {

    /// Initialize either a horizontal or vertical clamp.
    /// - Parameter vertical: Whether it is a vertical clamp.
    public init(vertical: Bool) {
        self.init()
        if vertical {
            appearFunctions.append { storage, _ in
                gtk_orientable_set_orientation(storage.opaquePointer, GTK_ORIENTATION_VERTICAL)
            }
        }
    }

}
