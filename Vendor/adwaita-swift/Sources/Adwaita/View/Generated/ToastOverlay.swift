//
//  ToastOverlay.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// A widget showing toasts above its content.
/// 
/// 
/// 
/// Much like `Gtk.Overlay`, `AdwToastOverlay` is a container with a single
/// main child, on top of which it can display a `Toast`, overlaid.
/// Toasts can be shown with `ToastOverlay.add_toast`.
/// 
/// Use `ToastOverlay.dismiss_all` to dismiss all toasts at once, or
/// `Toast.dismiss` to dismiss a single toast.
/// 
/// See `Toast` for details.
/// 
/// 
public struct ToastOverlay: AdwaitaWidget {

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

    /// The child widget.
    var child: Body?

    /// Initialize `ToastOverlay`.
    init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(adw_toast_overlay_new()?.opaque())
        for function in appearFunctions {
            function(storage, data)
        }
        if let childStorage = child?.storage(data: data, type: type) {
            storage.content["child"] = [childStorage]
            adw_toast_overlay_set_child(storage.opaquePointer, childStorage.opaquePointer?.cast())
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

            if let widget = storage.content["child"]?.first {
                child?.updateStorage(widget, data: data, updateProperties: updateProperties, type: type)
            }



        }
        for function in updateFunctions {
            function(storage, data, updateProperties)
        }
        if updateProperties {
            storage.previousState = self
        }
    }

    /// The child widget.
    public func child(@ViewBuilder _ child: () -> Body) -> Self {
        modify { $0.child = child() }
    }

}
