//
//  CenterBox.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// Arranges three children in a row, keeping the middle child
/// centered as well as possible.
/// 
/// 
/// 
/// To add children to `GtkCenterBox`, use `Gtk.CenterBox.set_start_widget`,
/// `Gtk.CenterBox.set_center_widget` and
/// `Gtk.CenterBox.set_end_widget`.
/// 
/// The sizing and positioning of children can be influenced with the
/// align and expand properties of the children.
/// 
/// 
public struct CenterBox: AdwaitaWidget {

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

    /// The accessible role of the given `GtkAccessible` implementation.
    /// 
    /// The accessible role cannot be changed once set.
    var accessibleRole: String?
    /// The widget that is placed at the center position.
    var centerWidget: Body?
    /// The widget that is placed at the end position.
    /// 
    /// In vertical orientation, the end position is at the bottom.
    /// In horizontal orientation, the end position is at the trailing
    /// edge with respect to the text direction.
    var endWidget: Body?
    /// Whether to shrink the center widget after other children.
    /// 
    /// By default, when there's no space to give all three children their
    /// natural widths, the start and end widgets start shrinking and the
    /// center child keeps natural width until they reach minimum width.
    /// 
    /// If false, start and end widgets keep natural width and the
    /// center widget starts shrinking instead.
    var shrinkCenterLast: Bool?
    /// The widget that is placed at the start position.
    /// 
    /// In vertical orientation, the start position is at the top.
    /// In horizontal orientation, the start position is at the leading
    /// edge with respect to the text direction.
    var startWidget: Body?

    /// Initialize `CenterBox`.
    public init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(gtk_center_box_new()?.opaque())
        for function in appearFunctions {
            function(storage, data)
        }
        if let centerWidgetStorage = centerWidget?.storage(data: data, type: type) {
            storage.content["centerWidget"] = [centerWidgetStorage]
            gtk_center_box_set_center_widget(storage.opaquePointer, centerWidgetStorage.opaquePointer?.cast())
        }
        if let endWidgetStorage = endWidget?.storage(data: data, type: type) {
            storage.content["endWidget"] = [endWidgetStorage]
            gtk_center_box_set_end_widget(storage.opaquePointer, endWidgetStorage.opaquePointer?.cast())
        }
        if let startWidgetStorage = startWidget?.storage(data: data, type: type) {
            storage.content["startWidget"] = [startWidgetStorage]
            gtk_center_box_set_start_widget(storage.opaquePointer, startWidgetStorage.opaquePointer?.cast())
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

            if let widget = storage.content["centerWidget"]?.first {
                centerWidget?.updateStorage(widget, data: data, updateProperties: updateProperties, type: type)
            }
            if let widget = storage.content["endWidget"]?.first {
                endWidget?.updateStorage(widget, data: data, updateProperties: updateProperties, type: type)
            }
            if let shrinkCenterLast, updateProperties, (storage.previousState as? Self)?.shrinkCenterLast != shrinkCenterLast {
                gtk_center_box_set_shrink_center_last(widget, shrinkCenterLast.cBool)
            }
            if let widget = storage.content["startWidget"]?.first {
                startWidget?.updateStorage(widget, data: data, updateProperties: updateProperties, type: type)
            }



        }
        for function in updateFunctions {
            function(storage, data, updateProperties)
        }
        if updateProperties {
            storage.previousState = self
        }
    }

    /// The accessible role of the given `GtkAccessible` implementation.
    /// 
    /// The accessible role cannot be changed once set.
    public func accessibleRole(_ accessibleRole: String?) -> Self {
        modify { $0.accessibleRole = accessibleRole }
    }

    /// The widget that is placed at the center position.
    public func centerWidget(@ViewBuilder _ centerWidget: () -> Body) -> Self {
        modify { $0.centerWidget = centerWidget() }
    }

    /// The widget that is placed at the end position.
    /// 
    /// In vertical orientation, the end position is at the bottom.
    /// In horizontal orientation, the end position is at the trailing
    /// edge with respect to the text direction.
    public func endWidget(@ViewBuilder _ endWidget: () -> Body) -> Self {
        modify { $0.endWidget = endWidget() }
    }

    /// Whether to shrink the center widget after other children.
    /// 
    /// By default, when there's no space to give all three children their
    /// natural widths, the start and end widgets start shrinking and the
    /// center child keeps natural width until they reach minimum width.
    /// 
    /// If false, start and end widgets keep natural width and the
    /// center widget starts shrinking instead.
    public func shrinkCenterLast(_ shrinkCenterLast: Bool? = true) -> Self {
        modify { $0.shrinkCenterLast = shrinkCenterLast }
    }

    /// The widget that is placed at the start position.
    /// 
    /// In vertical orientation, the start position is at the top.
    /// In horizontal orientation, the start position is at the leading
    /// edge with respect to the text direction.
    public func startWidget(@ViewBuilder _ startWidget: () -> Body) -> Self {
        modify { $0.startWidget = startWidget() }
    }

}
