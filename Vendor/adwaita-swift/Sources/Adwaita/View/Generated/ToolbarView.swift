//
//  ToolbarView.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// A widget containing a page, as well as top and/or bottom bars.
/// 
/// 
/// 
/// `AdwToolbarView` has a single content widget and one or multiple top and
/// bottom bars, shown at the top and bottom sides respectively.
/// 
/// Example of an `AdwToolbarView` UI definition:
/// ```xml
/// <object class="AdwToolbarView"><child type="top"><object class="AdwHeaderBar"/></child><property name="content"><object class="AdwPreferencesPage"><!-- ... --></object></property></object>
/// ```
/// 
/// The following kinds of top and bottom bars are supported:
/// 
/// - `HeaderBar`
/// - `TabBar`
/// - `ViewSwitcherBar`
/// - `Gtk.ActionBar`
/// - `Gtk.HeaderBar`
/// - `Gtk.PopoverMenuBar`
/// - `Gtk.SearchBar`
/// - Any `Gtk.Box` or a similar widget with the
/// [`.toolbar`](style-classes.html
public struct ToolbarView: AdwaitaWidget {

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

    /// The current bottom bar height.
    /// 
    /// Bottom bar height does change depending on
    /// ``revealBottomBars(_:)``, including during the transition.
    /// 
    /// See ``topBarHeight(_:)``.
    var bottomBarHeight: Int?
    /// Appearance of the bottom bars.
    /// 
    /// If set to `ADW_TOOLBAR_FLAT`, bottom bars are flat and scrolling content
    /// has a subtle undershoot shadow when touching them, same as the
    /// [`.undershoot-bottom`](style-classes.html
    var bottomBarStyle: ToolbarStyle?
    /// The content widget.
    var content: Body?
    /// Whether the content widget can extend behind bottom bars.
    /// 
    /// This can be used in combination with
    /// ``revealBottomBars(_:)`` to show and hide toolbars in
    /// fullscreen.
    /// 
    /// See ``extendContentToTopEdge(_:)``.
    var extendContentToBottomEdge: Bool?
    /// Whether the content widget can extend behind top bars.
    /// 
    /// This can be used in combination with ``revealTopBars(_:)``
    /// to show and hide toolbars in fullscreen.
    /// 
    /// See ``extendContentToBottomEdge(_:)``.
    var extendContentToTopEdge: Bool?
    /// Whether bottom bars are visible.
    /// 
    /// The transition will be animated.
    /// 
    /// This can be used in combination with
    /// ``extendContentToBottomEdge(_:)`` to show and hide
    /// toolbars in fullscreen.
    /// 
    /// See ``revealTopBars(_:)``.
    var revealBottomBars: Bool?
    /// Whether top bars are revealed.
    /// 
    /// The transition will be animated.
    /// 
    /// This can be used in combination with
    /// ``extendContentToTopEdge(_:)`` to show and hide toolbars
    /// in fullscreen.
    /// 
    /// See ``revealBottomBars(_:)``.
    var revealTopBars: Bool?
    /// The current top bar height.
    /// 
    /// Top bar height does change depending ``revealTopBars(_:)``,
    /// including during the transition.
    /// 
    /// See ``bottomBarHeight(_:)``.
    var topBarHeight: Int?
    /// Appearance of the top bars.
    /// 
    /// If set to `ADW_TOOLBAR_FLAT`, top bars are flat and scrolling content has a
    /// subtle undershoot shadow when touching them, same as the
    /// [`.undershoot-top`](style-classes.html
    var topBarStyle: ToolbarStyle?
    /// The body for the widget "bottom".
    var bottom: () -> Body = { [] }
    /// The body for the widget "top".
    var top: () -> Body = { [] }

    /// Initialize `ToolbarView`.
    public init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(adw_toolbar_view_new()?.opaque())
        for function in appearFunctions {
            function(storage, data)
        }
        if let contentStorage = content?.storage(data: data, type: type) {
            storage.content["content"] = [contentStorage]
            adw_toolbar_view_set_content(storage.opaquePointer, contentStorage.opaquePointer?.cast())
        }

        var bottomStorage: [ViewStorage] = []
        for view in bottom() {
            bottomStorage.append(view.storage(data: data, type: type))
            adw_toolbar_view_add_bottom_bar(storage.opaquePointer, bottomStorage.last?.opaquePointer?.cast())
        }
        storage.content["bottom"] = bottomStorage
        var topStorage: [ViewStorage] = []
        for view in top() {
            topStorage.append(view.storage(data: data, type: type))
            adw_toolbar_view_add_top_bar(storage.opaquePointer, topStorage.last?.opaquePointer?.cast())
        }
        storage.content["top"] = topStorage
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

            if let bottomBarStyle, updateProperties, (storage.previousState as? Self)?.bottomBarStyle != bottomBarStyle {
                adw_toolbar_view_set_bottom_bar_style(widget, bottomBarStyle.gtkValue)
            }
            if let widget = storage.content["content"]?.first {
                content?.updateStorage(widget, data: data, updateProperties: updateProperties, type: type)
            }
            if let extendContentToBottomEdge, updateProperties, (storage.previousState as? Self)?.extendContentToBottomEdge != extendContentToBottomEdge {
                adw_toolbar_view_set_extend_content_to_bottom_edge(widget, extendContentToBottomEdge.cBool)
            }
            if let extendContentToTopEdge, updateProperties, (storage.previousState as? Self)?.extendContentToTopEdge != extendContentToTopEdge {
                adw_toolbar_view_set_extend_content_to_top_edge(widget, extendContentToTopEdge.cBool)
            }
            if let revealBottomBars, updateProperties, (storage.previousState as? Self)?.revealBottomBars != revealBottomBars {
                adw_toolbar_view_set_reveal_bottom_bars(widget, revealBottomBars.cBool)
            }
            if let revealTopBars, updateProperties, (storage.previousState as? Self)?.revealTopBars != revealTopBars {
                adw_toolbar_view_set_reveal_top_bars(widget, revealTopBars.cBool)
            }
            if let topBarStyle, updateProperties, (storage.previousState as? Self)?.topBarStyle != topBarStyle {
                adw_toolbar_view_set_top_bar_style(widget, topBarStyle.gtkValue)
            }

            if let bottomStorage = storage.content["bottom"] {
                for (index, view) in bottom().enumerated() {
                    if let storage = bottomStorage[safe: index] {
                        view.updateStorage(
                            storage,
                            data: data,
                            updateProperties: updateProperties,
                            type: type
                        )
                    }
                }
            }
            if let topStorage = storage.content["top"] {
                for (index, view) in top().enumerated() {
                    if let storage = topStorage[safe: index] {
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

    /// The current bottom bar height.
    /// 
    /// Bottom bar height does change depending on
    /// ``revealBottomBars(_:)``, including during the transition.
    /// 
    /// See ``topBarHeight(_:)``.
    public func bottomBarHeight(_ bottomBarHeight: Int?) -> Self {
        modify { $0.bottomBarHeight = bottomBarHeight }
    }

    /// Appearance of the bottom bars.
    /// 
    /// If set to `ADW_TOOLBAR_FLAT`, bottom bars are flat and scrolling content
    /// has a subtle undershoot shadow when touching them, same as the
    /// [`.undershoot-bottom`](style-classes.html
    public func bottomBarStyle(_ bottomBarStyle: ToolbarStyle?) -> Self {
        modify { $0.bottomBarStyle = bottomBarStyle }
    }

    /// The content widget.
    public func content(@ViewBuilder _ content: () -> Body) -> Self {
        modify { $0.content = content() }
    }

    /// Whether the content widget can extend behind bottom bars.
    /// 
    /// This can be used in combination with
    /// ``revealBottomBars(_:)`` to show and hide toolbars in
    /// fullscreen.
    /// 
    /// See ``extendContentToTopEdge(_:)``.
    public func extendContentToBottomEdge(_ extendContentToBottomEdge: Bool? = true) -> Self {
        modify { $0.extendContentToBottomEdge = extendContentToBottomEdge }
    }

    /// Whether the content widget can extend behind top bars.
    /// 
    /// This can be used in combination with ``revealTopBars(_:)``
    /// to show and hide toolbars in fullscreen.
    /// 
    /// See ``extendContentToBottomEdge(_:)``.
    public func extendContentToTopEdge(_ extendContentToTopEdge: Bool? = true) -> Self {
        modify { $0.extendContentToTopEdge = extendContentToTopEdge }
    }

    /// Whether bottom bars are visible.
    /// 
    /// The transition will be animated.
    /// 
    /// This can be used in combination with
    /// ``extendContentToBottomEdge(_:)`` to show and hide
    /// toolbars in fullscreen.
    /// 
    /// See ``revealTopBars(_:)``.
    public func revealBottomBars(_ revealBottomBars: Bool? = true) -> Self {
        modify { $0.revealBottomBars = revealBottomBars }
    }

    /// Whether top bars are revealed.
    /// 
    /// The transition will be animated.
    /// 
    /// This can be used in combination with
    /// ``extendContentToTopEdge(_:)`` to show and hide toolbars
    /// in fullscreen.
    /// 
    /// See ``revealBottomBars(_:)``.
    public func revealTopBars(_ revealTopBars: Bool? = true) -> Self {
        modify { $0.revealTopBars = revealTopBars }
    }

    /// The current top bar height.
    /// 
    /// Top bar height does change depending ``revealTopBars(_:)``,
    /// including during the transition.
    /// 
    /// See ``bottomBarHeight(_:)``.
    public func topBarHeight(_ topBarHeight: Int?) -> Self {
        modify { $0.topBarHeight = topBarHeight }
    }

    /// Appearance of the top bars.
    /// 
    /// If set to `ADW_TOOLBAR_FLAT`, top bars are flat and scrolling content has a
    /// subtle undershoot shadow when touching them, same as the
    /// [`.undershoot-top`](style-classes.html
    public func topBarStyle(_ topBarStyle: ToolbarStyle?) -> Self {
        modify { $0.topBarStyle = topBarStyle }
    }

    /// Set the body for "bottom".
    /// - Parameter body: The body.
    /// - Returns: The widget.
    public func bottom(@ViewBuilder _ body: @escaping () -> Body) -> Self {
        var newSelf = self
        newSelf.bottom = body
        return newSelf
    }
    /// Set the body for "top".
    /// - Parameter body: The body.
    /// - Returns: The widget.
    public func top(@ViewBuilder _ body: @escaping () -> Body) -> Self {
        var newSelf = self
        newSelf.top = body
        return newSelf
    }
}
