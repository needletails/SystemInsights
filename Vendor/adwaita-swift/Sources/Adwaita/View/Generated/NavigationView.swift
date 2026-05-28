//
//  NavigationView.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// A page-based navigation container.
/// 
/// 
/// 
/// `AdwNavigationView` presents one child at a time, similar to
/// `Gtk.Stack`.
/// 
/// `AdwNavigationView` can only contain `NavigationPage` children.
/// 
/// It maintains a navigation stack that can be controlled with
/// `NavigationView.push` and `NavigationView.pop`. The whole
/// navigation stack can also be replaced using `NavigationView.replace`.
/// 
/// `AdwNavigationView` allows to manage pages statically or dynamically.
/// 
/// Static pages can be added using the `NavigationView.add` method. The
/// `AdwNavigationView` will keep a reference to these pages, but they aren't
/// accessible to the user until `NavigationView.push` is called (except
/// for the first page, which is pushed automatically). Use the
/// `NavigationView.remove` method to remove them. This is useful for
/// applications that have a small number of unique pages and just need
/// navigation between them.
/// 
/// Dynamic pages are automatically destroyed once they are popped off the
/// navigation stack. To add a page like this, push it using the
/// `NavigationView.push` method without calling
/// `NavigationView.add` first.
/// 
/// 
public struct NavigationView: AdwaitaWidget {

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

    /// Whether to animate page transitions.
    /// 
    /// Gesture-based transitions are always animated.
    var animateTransitions: Bool?
    /// Whether the view is horizontally homogeneous.
    /// 
    /// If the view is horizontally homogeneous, it allocates the same width for
    /// all pages.
    /// 
    /// If it's not, the page may change width when a different page becomes
    /// visible.
    var hhomogeneous: Bool?
    /// Whether pressing Escape pops the current page.
    /// 
    /// Applications using `AdwNavigationView` to implement a browser may want to
    /// disable it.
    var popOnEscape: Bool?
    /// Whether the view is vertically homogeneous.
    /// 
    /// If the view is vertically homogeneous, it allocates the same height for
    /// all pages.
    /// 
    /// If it's not, the view may change height when a different page becomes
    /// visible.
    var vhomogeneous: Bool?
    /// The tag of the currently visible page.
    var visiblePageTag: String?
    /// Emitted when a push shortcut or a gesture is triggered.
    /// 
    /// To support the push shortcuts and gestures, the application is expected to
    /// return the page to push in the handler.
    /// 
    /// This signal can be emitted multiple times for the gestures, for example
    /// when the gesture is cancelled by the user. As such, the application must
    /// not make any irreversible changes in the handler, such as removing the page
    /// from a forward stack.
    /// 
    /// Instead, it should be done in the `NavigationView::pushed` handler.
    var getNextPage: (() -> Void)?
    /// Emitted after @page has been popped from the navigation stack.
    /// 
    /// See `NavigationView.pop`.
    /// 
    /// When using `NavigationView.pop_to_page` or
    /// `NavigationView.pop_to_tag`, this signal is emitted for each of the
    /// popped pages.
    var popped: (() -> Void)?
    /// Emitted after a page has been pushed to the navigation stack.
    /// 
    /// See `NavigationView.push`.
    var pushed: (() -> Void)?
    /// Emitted after the navigation stack has been replaced.
    /// 
    /// See `NavigationView.replace`.
    var replaced: (() -> Void)?

    /// Initialize `NavigationView`.
    init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(adw_navigation_view_new()?.opaque())
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
        if let getNextPage {
            storage.connectSignal(name: "get-next-page", argCount: 0) {
                getNextPage()
            }
        }
        if let popped {
            storage.connectSignal(name: "popped", argCount: 1) {
                popped()
            }
        }
        if let pushed {
            storage.connectSignal(name: "pushed", argCount: 0) {
                pushed()
            }
        }
        if let replaced {
            storage.connectSignal(name: "replaced", argCount: 0) {
                replaced()
            }
        }
        storage.modify { widget in

            if let animateTransitions, updateProperties, (storage.previousState as? Self)?.animateTransitions != animateTransitions {
                adw_navigation_view_set_animate_transitions(widget, animateTransitions.cBool)
            }
            if let hhomogeneous, updateProperties, (storage.previousState as? Self)?.hhomogeneous != hhomogeneous {
                adw_navigation_view_set_hhomogeneous(widget, hhomogeneous.cBool)
            }
            if let popOnEscape, updateProperties, (storage.previousState as? Self)?.popOnEscape != popOnEscape {
                adw_navigation_view_set_pop_on_escape(widget, popOnEscape.cBool)
            }
            if let vhomogeneous, updateProperties, (storage.previousState as? Self)?.vhomogeneous != vhomogeneous {
                adw_navigation_view_set_vhomogeneous(widget, vhomogeneous.cBool)
            }



        }
        for function in updateFunctions {
            function(storage, data, updateProperties)
        }
        if updateProperties {
            storage.previousState = self
        }
    }

    /// Whether to animate page transitions.
    /// 
    /// Gesture-based transitions are always animated.
    public func animateTransitions(_ animateTransitions: Bool? = true) -> Self {
        modify { $0.animateTransitions = animateTransitions }
    }

    /// Whether the view is horizontally homogeneous.
    /// 
    /// If the view is horizontally homogeneous, it allocates the same width for
    /// all pages.
    /// 
    /// If it's not, the page may change width when a different page becomes
    /// visible.
    public func hhomogeneous(_ hhomogeneous: Bool? = true) -> Self {
        modify { $0.hhomogeneous = hhomogeneous }
    }

    /// Whether pressing Escape pops the current page.
    /// 
    /// Applications using `AdwNavigationView` to implement a browser may want to
    /// disable it.
    public func popOnEscape(_ popOnEscape: Bool? = true) -> Self {
        modify { $0.popOnEscape = popOnEscape }
    }

    /// Whether the view is vertically homogeneous.
    /// 
    /// If the view is vertically homogeneous, it allocates the same height for
    /// all pages.
    /// 
    /// If it's not, the view may change height when a different page becomes
    /// visible.
    public func vhomogeneous(_ vhomogeneous: Bool? = true) -> Self {
        modify { $0.vhomogeneous = vhomogeneous }
    }

    /// The tag of the currently visible page.
    public func visiblePageTag(_ visiblePageTag: String?) -> Self {
        modify { $0.visiblePageTag = visiblePageTag }
    }

    /// Emitted when a push shortcut or a gesture is triggered.
    /// 
    /// To support the push shortcuts and gestures, the application is expected to
    /// return the page to push in the handler.
    /// 
    /// This signal can be emitted multiple times for the gestures, for example
    /// when the gesture is cancelled by the user. As such, the application must
    /// not make any irreversible changes in the handler, such as removing the page
    /// from a forward stack.
    /// 
    /// Instead, it should be done in the `NavigationView::pushed` handler.
    public func getNextPage(_ getNextPage: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.getNextPage = getNextPage
        return newSelf
    }

    /// Emitted after @page has been popped from the navigation stack.
    /// 
    /// See `NavigationView.pop`.
    /// 
    /// When using `NavigationView.pop_to_page` or
    /// `NavigationView.pop_to_tag`, this signal is emitted for each of the
    /// popped pages.
    public func popped(_ popped: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.popped = popped
        return newSelf
    }

    /// Emitted after a page has been pushed to the navigation stack.
    /// 
    /// See `NavigationView.push`.
    public func pushed(_ pushed: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.pushed = pushed
        return newSelf
    }

    /// Emitted after the navigation stack has been replaced.
    /// 
    /// See `NavigationView.replace`.
    public func replaced(_ replaced: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.replaced = replaced
        return newSelf
    }

}
