//
//  AspectFrame.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// Preserves the aspect ratio of its child.
/// 
/// The frame can respect the aspect ratio of the child widget,
/// or use its own aspect ratio.
/// 
/// 
public struct AspectFrame: AdwaitaWidget {

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
    /// The child widget.
    var child: Body?
    /// Whether the `GtkAspectFrame` should use the aspect ratio of its child.
    var obeyChild: Bool?
    /// The aspect ratio to be used by the `GtkAspectFrame`.
    /// 
    /// This property is only used if
    /// ``obeyChild(_:)`` is set to `false`.
    var ratio: Float
    /// The horizontal alignment of the child.
    var xalign: Float?
    /// The vertical alignment of the child.
    var yalign: Float?

    /// Initialize `AspectFrame`.
    public init(ratio: Float) {
        self.ratio = ratio
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(gtk_aspect_frame_new(0.5, 0.5, ratio, 0)?.opaque())
        for function in appearFunctions {
            function(storage, data)
        }
        if let childStorage = child?.storage(data: data, type: type) {
            storage.content["child"] = [childStorage]
            gtk_aspect_frame_set_child(storage.opaquePointer, childStorage.opaquePointer?.cast())
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
            if let obeyChild, updateProperties, (storage.previousState as? Self)?.obeyChild != obeyChild {
                gtk_aspect_frame_set_obey_child(widget, obeyChild.cBool)
            }
            if updateProperties, (storage.previousState as? Self)?.ratio != ratio {
                gtk_aspect_frame_set_ratio(widget, ratio)
            }
            if let xalign, updateProperties, (storage.previousState as? Self)?.xalign != xalign {
                gtk_aspect_frame_set_xalign(widget, xalign)
            }
            if let yalign, updateProperties, (storage.previousState as? Self)?.yalign != yalign {
                gtk_aspect_frame_set_yalign(widget, yalign)
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

    /// The child widget.
    public func child(@ViewBuilder _ child: () -> Body) -> Self {
        modify { $0.child = child() }
    }

    /// Whether the `GtkAspectFrame` should use the aspect ratio of its child.
    public func obeyChild(_ obeyChild: Bool? = true) -> Self {
        modify { $0.obeyChild = obeyChild }
    }

    /// The aspect ratio to be used by the `GtkAspectFrame`.
    /// 
    /// This property is only used if
    /// ``obeyChild(_:)`` is set to `false`.
    public func ratio(_ ratio: Float) -> Self {
        modify { $0.ratio = ratio }
    }

    /// The horizontal alignment of the child.
    public func xalign(_ xalign: Float?) -> Self {
        modify { $0.xalign = xalign }
    }

    /// The vertical alignment of the child.
    public func yalign(_ yalign: Float?) -> Self {
        modify { $0.yalign = yalign }
    }

}
