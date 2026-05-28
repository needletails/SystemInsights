//
//  Spinner.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// A widget showing a loading spinner.
/// 
/// 
/// 
/// The size of the spinner depends on the available size, never smaller than
/// 16×16 pixels and never larger than 64×64 pixels.
/// 
/// Use the ``halign(_:)`` and ``valign(_:)``
/// properties in combination with ``widthRequest(_:)`` and
/// ``heightRequest(_:)`` for fine sizing control.
/// 
/// For example, the following snippet shows the spinner at 48×48 pixels:
/// 
/// ```xml
/// <object class="AdwSpinner"><property name="halign">center</property><property name="valign">center</property><property name="width-request">48</property><property name="height-request">48</property></object>
/// ```
/// 
/// See `SpinnerPaintable` for cases where using a widget is impractical or
/// impossible, such as ``paintable(_:)``.
/// 
/// 
public struct Spinner: AdwaitaWidget {

    #if exposeGeneratedAppearUpdateFunctions
    /// Additional update functions for type extensions.
    public var updateFunctions: [(ViewStorage, WidgetData, Bool) -> Void] = []
    /// Additional appear functions for type extensions.
    public var appearFunctions: [(ViewStorage, WidgetData) -> Void] = []
    #else
    /// Additional update functions for type extensions.
    var updateFunctions: [(ViewStorage, WidgetData, Bool) -> Void] = []
    /// Additional appear functions for type extensions.
    var appearFunctions: [(ViewStorage, WidgetData) -> Void] = []
    #endif


    /// Initialize `Spinner`.
    public init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(adw_spinner_new()?.opaque())
        for function in appearFunctions {
            function(storage, data)
        }

        return storage
    }

    /// Update the stored content.
    /// - Parameters:
    ///     - storage: The storage to update.
    ///     - modifiers: Modify views before being updated
    ///     - updateProperties: Whether to update the view's properties.
    ///     - type: The view render data type.
    public func update<Data>(_ storage: ViewStorage, data: WidgetData, updateProperties: Bool, type: Data.Type) where Data: ViewRenderData {
        storage.modify { widget in




        }
        for function in updateFunctions {
            function(storage, data, updateProperties)
        }
        if updateProperties {
            storage.previousState = self
        }
    }

}
