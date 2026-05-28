//
//  GtkWrapMode.swift
//  Adwaita
//
//  Created by mlm on 24.08.25.
//

import CAdw

/// Add ExpressibleByIntegerLiteral conformance to make GtkWrapMode usable as
/// a RawValue in an enum.
extension GtkWrapMode: @retroactive ExpressibleByIntegerLiteral {

    /// Initialize from an integer literal.
    public init(integerLiteral value: Int) {
        self.init(UInt32(value))
    }

}
