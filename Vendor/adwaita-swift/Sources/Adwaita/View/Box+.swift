//
//  Box+.swift
//  Adwaita
//
//  Created by david-swift on 16.10.24.
//

extension Box {

    /// Link the children.
    public func linked(_ active: Bool = true) -> AnyView {
        style("linked", active: active)
    }

}
