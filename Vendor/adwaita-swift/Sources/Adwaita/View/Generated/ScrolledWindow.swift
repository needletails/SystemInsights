//
//  ScrolledWindow.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// Makes its child scrollable.
/// 
/// 
/// 
/// It does so using either internally added scrollbars or externally
/// associated adjustments, and optionally draws a frame around the child.
/// 
/// Widgets with native scrolling support, i.e. those whose classes implement
/// the `Gtk.Scrollable` interface, are added directly. For other types
/// of widget, the class `Gtk.Viewport` acts as an adaptor, giving
/// scrollability to other widgets. `Gtk.ScrolledWindow.set_child`
/// intelligently accounts for whether or not the added child is a `GtkScrollable`.
/// If it isn’t, then it wraps the child in a `GtkViewport`. Therefore, you can
/// just add any child widget and not worry about the details.
/// 
/// If `Gtk.ScrolledWindow.set_child` has added a `GtkViewport` for you,
/// it will be automatically removed when you unset the child.
/// Unless ``hscrollbarPolicy(_:)`` and
/// ``vscrollbarPolicy(_:)`` are %GTK_POLICY_NEVER or
/// %GTK_POLICY_EXTERNAL, `GtkScrolledWindow` adds internal `GtkScrollbar` widgets
/// around its child. The scroll position of the child, and if applicable the
/// scrollbars, is controlled by the ``hadjustment(_:)``
/// and ``vadjustment(_:)`` that are associated with the
/// `GtkScrolledWindow`. See the docs on `Gtk.Scrollbar` for the details,
/// but note that the “step_increment” and “page_increment” fields are only
/// effective if the policy causes scrollbars to be present.
/// 
/// If a `GtkScrolledWindow` doesn’t behave quite as you would like, or
/// doesn’t have exactly the right layout, it’s very possible to set up
/// your own scrolling with `GtkScrollbar` and for example a `GtkGrid`.
/// 
/// 
public struct ScrolledWindow: AdwaitaWidget {

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
    /// 
    /// When setting this property, if the child widget does not implement
    /// `Gtk.Scrollable`, the scrolled window will add the child to
    /// a `Gtk.Viewport` and then set the viewport as the child.
    var child: Body?
    /// Whether to draw a frame around the contents.
    var hasFrame: Bool?
    /// When the horizontal scrollbar is displayed.
    /// 
    /// Use `Gtk.ScrolledWindow.set_policy` to set
    /// this property.
    var hscrollbarPolicy: ScrollbarVisibility?
    /// Whether kinetic scrolling is enabled or not.
    /// 
    /// Kinetic scrolling only applies to devices with source %GDK_SOURCE_TOUCHSCREEN.
    var kineticScrolling: Bool?
    /// The maximum content height of @scrolled_window.
    var maxContentHeight: Int?
    /// The maximum content width of @scrolled_window.
    var maxContentWidth: Int?
    /// The minimum content height of @scrolled_window.
    var minContentHeight: Int?
    /// The minimum content width of @scrolled_window.
    var minContentWidth: Int?
    /// Whether overlay scrolling is enabled or not.
    /// 
    /// If it is, the scrollbars are only added as traditional widgets
    /// when a mouse is present. Otherwise, they are overlaid on top of
    /// the content, as narrow indicators.
    /// 
    /// Note that overlay scrolling can also be globally disabled, with
    /// the ``gtkOverlayScrolling(_:)`` setting.
    var overlayScrolling: Bool?
    /// Whether the natural height of the child should be calculated and propagated
    /// through the scrolled window’s requested natural height.
    /// 
    /// This is useful in cases where an attempt should be made to allocate exactly
    /// enough space for the natural size of the child.
    var propagateNaturalHeight: Bool?
    /// Whether the natural width of the child should be calculated and propagated
    /// through the scrolled window’s requested natural width.
    /// 
    /// This is useful in cases where an attempt should be made to allocate exactly
    /// enough space for the natural size of the child.
    var propagateNaturalWidth: Bool?
    /// When the vertical scrollbar is displayed.
    /// 
    /// Use `Gtk.ScrolledWindow.set_policy` to set
    /// this property.
    var vscrollbarPolicy: ScrollbarVisibility?
    /// Emitted whenever user initiated scrolling makes the scrolled
    /// window firmly surpass the limits defined by the adjustment
    /// in that orientation.
    /// 
    /// A similar behavior without edge resistance is provided by the
    /// `Gtk.ScrolledWindow::edge-reached` signal.
    /// 
    /// Note: The @pos argument is LTR/RTL aware, so callers should be
    /// aware too if intending to provide behavior on horizontal edges.
    var edgeOvershot: (() -> Void)?
    /// Emitted whenever user-initiated scrolling makes the scrolled
    /// window exactly reach the lower or upper limits defined by the
    /// adjustment in that orientation.
    /// 
    /// A similar behavior with edge resistance is provided by the
    /// `Gtk.ScrolledWindow::edge-overshot` signal.
    /// 
    /// Note: The @pos argument is LTR/RTL aware, so callers should be
    /// aware too if intending to provide behavior on horizontal edges.
    var edgeReached: (() -> Void)?
    /// Emitted when focus is moved away from the scrolled window by a
    /// keybinding.
    /// 
    /// This is a [keybinding signal](class.SignalAction.html).
    /// 
    /// The default bindings for this signal are
    /// <kbd>Ctrl</kbd>+<kbd>Tab</kbd> to move forward and
    /// <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Tab</kbd>` to move backward.
    var moveFocusOut: (() -> Void)?
    /// Emitted when a keybinding that scrolls is pressed.
    /// 
    /// This is a [keybinding signal](class.SignalAction.html).
    /// 
    /// The horizontal or vertical adjustment is updated which triggers a
    /// signal that the scrolled window’s child may listen to and scroll itself.
    var scrollChild: (() -> Void)?

    /// Initialize `ScrolledWindow`.
    init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(gtk_scrolled_window_new()?.opaque())
        for function in appearFunctions {
            function(storage, data)
        }
        if let childStorage = child?.storage(data: data, type: type) {
            storage.content["child"] = [childStorage]
            gtk_scrolled_window_set_child(storage.opaquePointer, childStorage.opaquePointer?.cast())
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
        if let edgeOvershot {
            storage.connectSignal(name: "edge-overshot", argCount: 1) {
                edgeOvershot()
            }
        }
        if let edgeReached {
            storage.connectSignal(name: "edge-reached", argCount: 1) {
                edgeReached()
            }
        }
        if let moveFocusOut {
            storage.connectSignal(name: "move-focus-out", argCount: 1) {
                moveFocusOut()
            }
        }
        if let scrollChild {
            storage.connectSignal(name: "scroll-child", argCount: 2) {
                scrollChild()
            }
        }
        storage.modify { widget in

            if let widget = storage.content["child"]?.first {
                child?.updateStorage(widget, data: data, updateProperties: updateProperties, type: type)
            }
            if let hasFrame, updateProperties, (storage.previousState as? Self)?.hasFrame != hasFrame {
                gtk_scrolled_window_set_has_frame(widget, hasFrame.cBool)
            }
            if let kineticScrolling, updateProperties, (storage.previousState as? Self)?.kineticScrolling != kineticScrolling {
                gtk_scrolled_window_set_kinetic_scrolling(widget, kineticScrolling.cBool)
            }
            if let maxContentHeight, updateProperties, (storage.previousState as? Self)?.maxContentHeight != maxContentHeight {
                gtk_scrolled_window_set_max_content_height(widget, maxContentHeight.cInt)
            }
            if let maxContentWidth, updateProperties, (storage.previousState as? Self)?.maxContentWidth != maxContentWidth {
                gtk_scrolled_window_set_max_content_width(widget, maxContentWidth.cInt)
            }
            if let minContentHeight, updateProperties, (storage.previousState as? Self)?.minContentHeight != minContentHeight {
                gtk_scrolled_window_set_min_content_height(widget, minContentHeight.cInt)
            }
            if let minContentWidth, updateProperties, (storage.previousState as? Self)?.minContentWidth != minContentWidth {
                gtk_scrolled_window_set_min_content_width(widget, minContentWidth.cInt)
            }
            if let overlayScrolling, updateProperties, (storage.previousState as? Self)?.overlayScrolling != overlayScrolling {
                gtk_scrolled_window_set_overlay_scrolling(widget, overlayScrolling.cBool)
            }
            if let propagateNaturalHeight, updateProperties, (storage.previousState as? Self)?.propagateNaturalHeight != propagateNaturalHeight {
                gtk_scrolled_window_set_propagate_natural_height(widget, propagateNaturalHeight.cBool)
            }
            if let propagateNaturalWidth, updateProperties, (storage.previousState as? Self)?.propagateNaturalWidth != propagateNaturalWidth {
                gtk_scrolled_window_set_propagate_natural_width(widget, propagateNaturalWidth.cBool)
            }



if hscrollbarPolicy != (storage.previousState as? Self)?.hscrollbarPolicy
|| vscrollbarPolicy != (storage.previousState as? Self)?.vscrollbarPolicy {
    gtk_scrolled_window_set_policy(
        widget,
        (hscrollbarPolicy ?? .automatic).gtkValue,
        (vscrollbarPolicy ?? .automatic).gtkValue
    )
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
    /// 
    /// When setting this property, if the child widget does not implement
    /// `Gtk.Scrollable`, the scrolled window will add the child to
    /// a `Gtk.Viewport` and then set the viewport as the child.
    public func child(@ViewBuilder _ child: () -> Body) -> Self {
        modify { $0.child = child() }
    }

    /// Whether to draw a frame around the contents.
    public func hasFrame(_ hasFrame: Bool? = true) -> Self {
        modify { $0.hasFrame = hasFrame }
    }

    /// When the horizontal scrollbar is displayed.
    /// 
    /// Use `Gtk.ScrolledWindow.set_policy` to set
    /// this property.
    public func hscrollbarPolicy(_ hscrollbarPolicy: ScrollbarVisibility?) -> Self {
        modify { $0.hscrollbarPolicy = hscrollbarPolicy }
    }

    /// Whether kinetic scrolling is enabled or not.
    /// 
    /// Kinetic scrolling only applies to devices with source %GDK_SOURCE_TOUCHSCREEN.
    public func kineticScrolling(_ kineticScrolling: Bool? = true) -> Self {
        modify { $0.kineticScrolling = kineticScrolling }
    }

    /// The maximum content height of @scrolled_window.
    public func maxContentHeight(_ maxContentHeight: Int?) -> Self {
        modify { $0.maxContentHeight = maxContentHeight }
    }

    /// The maximum content width of @scrolled_window.
    public func maxContentWidth(_ maxContentWidth: Int?) -> Self {
        modify { $0.maxContentWidth = maxContentWidth }
    }

    /// The minimum content height of @scrolled_window.
    public func minContentHeight(_ minContentHeight: Int?) -> Self {
        modify { $0.minContentHeight = minContentHeight }
    }

    /// The minimum content width of @scrolled_window.
    public func minContentWidth(_ minContentWidth: Int?) -> Self {
        modify { $0.minContentWidth = minContentWidth }
    }

    /// Whether overlay scrolling is enabled or not.
    /// 
    /// If it is, the scrollbars are only added as traditional widgets
    /// when a mouse is present. Otherwise, they are overlaid on top of
    /// the content, as narrow indicators.
    /// 
    /// Note that overlay scrolling can also be globally disabled, with
    /// the ``gtkOverlayScrolling(_:)`` setting.
    public func overlayScrolling(_ overlayScrolling: Bool? = true) -> Self {
        modify { $0.overlayScrolling = overlayScrolling }
    }

    /// Whether the natural height of the child should be calculated and propagated
    /// through the scrolled window’s requested natural height.
    /// 
    /// This is useful in cases where an attempt should be made to allocate exactly
    /// enough space for the natural size of the child.
    public func propagateNaturalHeight(_ propagateNaturalHeight: Bool? = true) -> Self {
        modify { $0.propagateNaturalHeight = propagateNaturalHeight }
    }

    /// Whether the natural width of the child should be calculated and propagated
    /// through the scrolled window’s requested natural width.
    /// 
    /// This is useful in cases where an attempt should be made to allocate exactly
    /// enough space for the natural size of the child.
    public func propagateNaturalWidth(_ propagateNaturalWidth: Bool? = true) -> Self {
        modify { $0.propagateNaturalWidth = propagateNaturalWidth }
    }

    /// When the vertical scrollbar is displayed.
    /// 
    /// Use `Gtk.ScrolledWindow.set_policy` to set
    /// this property.
    public func vscrollbarPolicy(_ vscrollbarPolicy: ScrollbarVisibility?) -> Self {
        modify { $0.vscrollbarPolicy = vscrollbarPolicy }
    }

    /// Emitted whenever user initiated scrolling makes the scrolled
    /// window firmly surpass the limits defined by the adjustment
    /// in that orientation.
    /// 
    /// A similar behavior without edge resistance is provided by the
    /// `Gtk.ScrolledWindow::edge-reached` signal.
    /// 
    /// Note: The @pos argument is LTR/RTL aware, so callers should be
    /// aware too if intending to provide behavior on horizontal edges.
    public func edgeOvershot(_ edgeOvershot: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.edgeOvershot = edgeOvershot
        return newSelf
    }

    /// Emitted whenever user-initiated scrolling makes the scrolled
    /// window exactly reach the lower or upper limits defined by the
    /// adjustment in that orientation.
    /// 
    /// A similar behavior with edge resistance is provided by the
    /// `Gtk.ScrolledWindow::edge-overshot` signal.
    /// 
    /// Note: The @pos argument is LTR/RTL aware, so callers should be
    /// aware too if intending to provide behavior on horizontal edges.
    public func edgeReached(_ edgeReached: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.edgeReached = edgeReached
        return newSelf
    }

    /// Emitted when focus is moved away from the scrolled window by a
    /// keybinding.
    /// 
    /// This is a [keybinding signal](class.SignalAction.html).
    /// 
    /// The default bindings for this signal are
    /// <kbd>Ctrl</kbd>+<kbd>Tab</kbd> to move forward and
    /// <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Tab</kbd>` to move backward.
    public func moveFocusOut(_ moveFocusOut: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.moveFocusOut = moveFocusOut
        return newSelf
    }

    /// Emitted when a keybinding that scrolls is pressed.
    /// 
    /// This is a [keybinding signal](class.SignalAction.html).
    /// 
    /// The horizontal or vertical adjustment is updated which triggers a
    /// signal that the scrolled window’s child may listen to and scroll itself.
    public func scrollChild(_ scrollChild: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.scrollChild = scrollChild
        return newSelf
    }

}
