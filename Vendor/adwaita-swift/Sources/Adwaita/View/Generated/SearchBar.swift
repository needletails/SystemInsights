//
//  SearchBar.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// Reveals a search entry when search is started.
/// 
/// 
/// 
/// It can also contain additional widgets, such as drop-down menus,
/// or buttons.  The search bar would appear when a search is started
/// through typing on the keyboard, or the application’s search mode
/// is toggled on.
/// 
/// For keyboard presses to start a search, the search bar must be told
/// of a widget to capture key events from through
/// `Gtk.SearchBar.set_key_capture_widget`. This widget will
/// typically be the top-level window, or a parent container of the
/// search bar. Common shortcuts such as Ctrl+F should be handled as an
/// application action, or through the menu items.
/// 
/// You will also need to tell the search bar about which entry you
/// are using as your search entry using `Gtk.SearchBar.connect_entry`.
/// 
/// 
public struct SearchBar: AdwaitaWidget {

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
    /// The key capture widget.
    var keyCaptureWidget: Body?
    /// Whether the search mode is on and the search bar shown.
    var searchModeEnabled: Bool?
    /// Whether to show the close button in the search bar.
    var showCloseButton: Bool?

    /// Initialize `SearchBar`.
    public init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(gtk_search_bar_new()?.opaque())
        for function in appearFunctions {
            function(storage, data)
        }
        if let childStorage = child?.storage(data: data, type: type) {
            storage.content["child"] = [childStorage]
            gtk_search_bar_set_child(storage.opaquePointer, childStorage.opaquePointer?.cast())
        }
        if let keyCaptureWidgetStorage = keyCaptureWidget?.storage(data: data, type: type) {
            storage.content["keyCaptureWidget"] = [keyCaptureWidgetStorage]
            gtk_search_bar_set_key_capture_widget(storage.opaquePointer, keyCaptureWidgetStorage.opaquePointer?.cast())
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
            if let widget = storage.content["keyCaptureWidget"]?.first {
                keyCaptureWidget?.updateStorage(widget, data: data, updateProperties: updateProperties, type: type)
            }
            if let searchModeEnabled, updateProperties, (storage.previousState as? Self)?.searchModeEnabled != searchModeEnabled {
                gtk_search_bar_set_search_mode(widget, searchModeEnabled.cBool)
            }
            if let showCloseButton, updateProperties, (storage.previousState as? Self)?.showCloseButton != showCloseButton {
                gtk_search_bar_set_show_close_button(widget, showCloseButton.cBool)
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

    /// The key capture widget.
    public func keyCaptureWidget(@ViewBuilder _ keyCaptureWidget: () -> Body) -> Self {
        modify { $0.keyCaptureWidget = keyCaptureWidget() }
    }

    /// Whether the search mode is on and the search bar shown.
    public func searchModeEnabled(_ searchModeEnabled: Bool? = true) -> Self {
        modify { $0.searchModeEnabled = searchModeEnabled }
    }

    /// Whether to show the close button in the search bar.
    public func showCloseButton(_ showCloseButton: Bool? = true) -> Self {
        modify { $0.showCloseButton = showCloseButton }
    }

}
