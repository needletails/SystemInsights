//
//  Popover.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// Presents a bubble-like popup.
/// 
/// 
/// 
/// It is primarily meant to provide context-dependent information
/// or options. Popovers are attached to a parent widget. The parent widget
/// must support popover children, as `Gtk.MenuButton` and
/// `Gtk.PopoverMenuBar` do. If you want to make a custom widget that
/// has an attached popover, you need to call `Gtk.Popover.present`
/// in your [vfunc@Gtk.Widget.size_allocate] vfunc, in order to update the
/// positioning of the popover.
/// 
/// The position of a popover relative to the widget it is attached to
/// can also be changed with `Gtk.Popover.set_position`. By default,
/// it points to the whole widget area, but it can be made to point to
/// a specific area using `Gtk.Popover.set_pointing_to`.
/// 
/// By default, `GtkPopover` performs a grab, in order to ensure input
/// events get redirected to it while it is shown, and also so the popover
/// is dismissed in the expected situations (clicks outside the popover,
/// or the Escape key being pressed). If no such modal behavior is desired
/// on a popover, `Gtk.Popover.set_autohide` may be called on it to
/// tweak its behavior.
/// 
/// 
public struct Popover: AdwaitaWidget {

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
    /// Whether to dismiss the popover on outside clicks.
    var autohide: Bool?
    /// Whether the popover pops down after a child popover.
    /// 
    /// This is used to implement the expected behavior of submenus.
    var cascadePopdown: Bool?
    /// The child widget.
    var child: Body?
    /// The default widget inside the popover.
    var defaultWidget: Body?
    /// Whether to draw an arrow.
    var hasArrow: Bool?
    /// Whether mnemonics are currently visible in this popover.
    var mnemonicsVisible: Bool?
    /// Emitted whend the user activates the default widget.
    /// 
    /// This is a [keybinding signal](class.SignalAction.html).
    /// 
    /// The default binding for this signal is <kbd>Enter</kbd>.
    var activateDefault: (() -> Void)?
    /// Emitted when the popover is closed.
    var closed: (() -> Void)?

    /// Initialize `Popover`.
    public init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(gtk_popover_new()?.opaque())
        for function in appearFunctions {
            function(storage, data)
        }
        if let childStorage = child?.storage(data: data, type: type) {
            storage.content["child"] = [childStorage]
            gtk_popover_set_child(storage.opaquePointer?.cast(), childStorage.opaquePointer?.cast())
        }
        if let defaultWidgetStorage = defaultWidget?.storage(data: data, type: type) {
            storage.content["defaultWidget"] = [defaultWidgetStorage]
            gtk_popover_set_default_widget(storage.opaquePointer?.cast(), defaultWidgetStorage.opaquePointer?.cast())
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
        if let activateDefault {
            storage.connectSignal(name: "activate-default", argCount: 0) {
                activateDefault()
            }
        }
        if let closed {
            storage.connectSignal(name: "closed", argCount: 0) {
                closed()
            }
        }
        storage.modify { widget in

            if let autohide, updateProperties, (storage.previousState as? Self)?.autohide != autohide {
                gtk_popover_set_autohide(widget?.cast(), autohide.cBool)
            }
            if let cascadePopdown, updateProperties, (storage.previousState as? Self)?.cascadePopdown != cascadePopdown {
                gtk_popover_set_cascade_popdown(widget?.cast(), cascadePopdown.cBool)
            }
            if let widget = storage.content["child"]?.first {
                child?.updateStorage(widget, data: data, updateProperties: updateProperties, type: type)
            }
            if let widget = storage.content["defaultWidget"]?.first {
                defaultWidget?.updateStorage(widget, data: data, updateProperties: updateProperties, type: type)
            }
            if let hasArrow, updateProperties, (storage.previousState as? Self)?.hasArrow != hasArrow {
                gtk_popover_set_has_arrow(widget?.cast(), hasArrow.cBool)
            }
            if let mnemonicsVisible, updateProperties, (storage.previousState as? Self)?.mnemonicsVisible != mnemonicsVisible {
                gtk_popover_set_mnemonics_visible(widget?.cast(), mnemonicsVisible.cBool)
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

    /// Whether to dismiss the popover on outside clicks.
    public func autohide(_ autohide: Bool? = true) -> Self {
        modify { $0.autohide = autohide }
    }

    /// Whether the popover pops down after a child popover.
    /// 
    /// This is used to implement the expected behavior of submenus.
    public func cascadePopdown(_ cascadePopdown: Bool? = true) -> Self {
        modify { $0.cascadePopdown = cascadePopdown }
    }

    /// The child widget.
    public func child(@ViewBuilder _ child: () -> Body) -> Self {
        modify { $0.child = child() }
    }

    /// The default widget inside the popover.
    public func defaultWidget(@ViewBuilder _ defaultWidget: () -> Body) -> Self {
        modify { $0.defaultWidget = defaultWidget() }
    }

    /// Whether to draw an arrow.
    public func hasArrow(_ hasArrow: Bool? = true) -> Self {
        modify { $0.hasArrow = hasArrow }
    }

    /// Whether mnemonics are currently visible in this popover.
    public func mnemonicsVisible(_ mnemonicsVisible: Bool? = true) -> Self {
        modify { $0.mnemonicsVisible = mnemonicsVisible }
    }

    /// Emitted whend the user activates the default widget.
    /// 
    /// This is a [keybinding signal](class.SignalAction.html).
    /// 
    /// The default binding for this signal is <kbd>Enter</kbd>.
    public func activateDefault(_ activateDefault: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.activateDefault = activateDefault
        return newSelf
    }

    /// Emitted when the popover is closed.
    public func closed(_ closed: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.closed = closed
        return newSelf
    }

}
