//
//  Box.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// Arranges child widgets into a single row or column.
/// 
/// 
/// 
/// Whether it is a row or column depends on the value of its
/// ``orientation(_:)`` property. Within the other
/// dimension, all children are allocated the same size. The
/// ``halign(_:)`` and ``valign(_:)``
/// properties can be used on the children to influence their allocation.
/// 
/// Use repeated calls to `Gtk.Box.append` to pack widgets into a
/// `GtkBox` from start to end. Use `Gtk.Box.remove` to remove widgets
/// from the `GtkBox`. `Gtk.Box.insert_child_after` can be used to add
/// a child at a particular position.
/// 
/// Use `Gtk.Box.set_homogeneous` to specify whether or not all children
/// of the `GtkBox` are forced to get the same amount of space.
/// 
/// Use `Gtk.Box.set_spacing` to determine how much space will be minimally
/// placed between all children in the `GtkBox`. Note that spacing is added
/// *between* the children.
/// 
/// Use `Gtk.Box.reorder_child_after` to move a child to a different
/// place in the box.
/// 
/// 
public struct Box: AdwaitaWidget {

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
    /// The position of the child that determines the baseline.
    /// 
    /// This is only relevant if the box is in vertical orientation.
    var baselineChild: Int?
    /// Whether the children should all be the same size.
    var homogeneous: Bool?
    /// The amount of space between children.
    var spacing: Int
    /// The body for the widget "append".
    var append: () -> Body = { [] }
    /// The body for the widget "prepend".
    var prepend: () -> Body = { [] }

    /// Initialize `Box`.
    init(spacing: Int) {
        self.spacing = spacing
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(gtk_box_new(GTK_ORIENTATION_VERTICAL, spacing.cInt)?.opaque())
        for function in appearFunctions {
            function(storage, data)
        }

        var appendStorage: [ViewStorage] = []
        for view in append() {
            appendStorage.append(view.storage(data: data, type: type))
            gtk_box_append(storage.opaquePointer?.cast(), appendStorage.last?.opaquePointer?.cast())
        }
        storage.content["append"] = appendStorage
        var prependStorage: [ViewStorage] = []
        for view in prepend() {
            prependStorage.append(view.storage(data: data, type: type))
            gtk_box_prepend(storage.opaquePointer?.cast(), prependStorage.last?.opaquePointer?.cast())
        }
        storage.content["prepend"] = prependStorage
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

            if let baselineChild, updateProperties, (storage.previousState as? Self)?.baselineChild != baselineChild {
                gtk_box_set_baseline_child(widget?.cast(), baselineChild.cInt)
            }
            if let homogeneous, updateProperties, (storage.previousState as? Self)?.homogeneous != homogeneous {
                gtk_box_set_homogeneous(widget?.cast(), homogeneous.cBool)
            }
            if updateProperties, (storage.previousState as? Self)?.spacing != spacing {
                gtk_box_set_spacing(widget?.cast(), spacing.cInt)
            }

            if let appendStorage = storage.content["append"] {
                for (index, view) in append().enumerated() {
                    if let storage = appendStorage[safe: index] {
                        view.updateStorage(
                            storage,
                            data: data,
                            updateProperties: updateProperties,
                            type: type
                        )
                    }
                }
            }
            if let prependStorage = storage.content["prepend"] {
                for (index, view) in prepend().enumerated() {
                    if let storage = prependStorage[safe: index] {
                        view.updateStorage(
                            storage,
                            data: data,
                            updateProperties: updateProperties,
                            type: type
                        )
                    }
                }
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

    /// The position of the child that determines the baseline.
    /// 
    /// This is only relevant if the box is in vertical orientation.
    public func baselineChild(_ baselineChild: Int?) -> Self {
        modify { $0.baselineChild = baselineChild }
    }

    /// Whether the children should all be the same size.
    public func homogeneous(_ homogeneous: Bool? = true) -> Self {
        modify { $0.homogeneous = homogeneous }
    }

    /// The amount of space between children.
    public func spacing(_ spacing: Int) -> Self {
        modify { $0.spacing = spacing }
    }

    /// Set the body for "append".
    /// - Parameter body: The body.
    /// - Returns: The widget.
    public func append(@ViewBuilder _ body: @escaping () -> Body) -> Self {
        var newSelf = self
        newSelf.append = body
        return newSelf
    }
    /// Set the body for "prepend".
    /// - Parameter body: The body.
    /// - Returns: The widget.
    public func prepend(@ViewBuilder _ body: @escaping () -> Body) -> Self {
        var newSelf = self
        newSelf.prepend = body
        return newSelf
    }
}
