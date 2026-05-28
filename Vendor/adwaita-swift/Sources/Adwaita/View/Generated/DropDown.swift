//
//  DropDown.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// Allows the user to choose an item from a list of options.
/// 
/// 
/// 
/// The `GtkDropDown` displays the [selected]``selected(_:)``
/// choice.
/// 
/// The options are given to `GtkDropDown` in the form of `GListModel`
/// and how the individual options are represented is determined by
/// a `Gtk.ListItemFactory`. The default factory displays simple strings,
/// and adds a checkmark to the selected item in the popup.
/// 
/// To set your own factory, use `Gtk.DropDown.set_factory`. It is
/// possible to use a separate factory for the items in the popup, with
/// `Gtk.DropDown.set_list_factory`.
/// 
/// `GtkDropDown` knows how to obtain strings from the items in a
/// `Gtk.StringList`; for other models, you have to provide an expression
/// to find the strings via `Gtk.DropDown.set_expression`.
/// 
/// `GtkDropDown` can optionally allow search in the popup, which is
/// useful if the list of options is long. To enable the search entry,
/// use `Gtk.DropDown.set_enable_search`.
/// 
/// Here is a UI definition example for `GtkDropDown` with a simple model:
/// 
/// ```xml
/// <object class="GtkDropDown"><property name="model"><object class="GtkStringList"><items><item translatable="yes">Factory</item><item translatable="yes">Home</item><item translatable="yes">Subway</item></items></object></property></object>
/// ```
/// 
/// If a `GtkDropDown` is created in this manner, or with
/// `Gtk.DropDown.new_from_strings`, for instance, the object returned from
/// `Gtk.DropDown.get_selected_item` will be a `Gtk.StringObject`.
/// 
/// To learn more about the list widget framework, see the
/// [overview](section-list-widget.html).
/// 
/// 
public struct DropDown: AdwaitaWidget {

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
    /// Whether to show a search entry in the popup.
    /// 
    /// Note that search requires ``expression(_:)``
    /// to be set.
    var enableSearch: Bool?
    /// The position of the selected item.
    /// 
    /// If no item is selected, the property has the value
    /// %GTK_INVALID_LIST_POSITION.
    var selected: Binding<UInt>?
    /// Whether to show an arrow within the GtkDropDown widget.
    var showArrow: Bool?
    /// Emitted to when the drop down is activated.
    /// 
    /// The `::activate` signal on `GtkDropDown` is an action signal and
    /// emitting it causes the drop down to pop up its dropdown.
    var activate: (() -> Void)?

    /// Initialize `DropDown`.
    init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(gtk_drop_down_new(gtk_string_list_new(nil), nil)?.opaque())
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
        if let activate {
            storage.connectSignal(name: "activate", argCount: 0) {
                activate()
            }
        }
        storage.modify { widget in

        storage.notify(name: "selected") {
            let newValue = UInt(gtk_drop_down_get_selected(storage.opaquePointer))
if let selected, newValue != selected.wrappedValue {
    selected.wrappedValue = newValue
}
        }
            if let enableSearch, updateProperties, (storage.previousState as? Self)?.enableSearch != enableSearch {
                gtk_drop_down_set_enable_search(widget, enableSearch.cBool)
            }
            if let selected, updateProperties, (UInt(gtk_drop_down_get_selected(storage.opaquePointer))) != selected.wrappedValue {
                gtk_drop_down_set_selected(storage.opaquePointer, selected.wrappedValue.cInt)
            }
            if let showArrow, updateProperties, (storage.previousState as? Self)?.showArrow != showArrow {
                gtk_drop_down_set_show_arrow(widget, showArrow.cBool)
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

    /// Whether to show a search entry in the popup.
    /// 
    /// Note that search requires ``expression(_:)``
    /// to be set.
    public func enableSearch(_ enableSearch: Bool? = true) -> Self {
        modify { $0.enableSearch = enableSearch }
    }

    /// The position of the selected item.
    /// 
    /// If no item is selected, the property has the value
    /// %GTK_INVALID_LIST_POSITION.
    public func selected(_ selected: Binding<UInt>?) -> Self {
        modify { $0.selected = selected }
    }

    /// Whether to show an arrow within the GtkDropDown widget.
    public func showArrow(_ showArrow: Bool? = true) -> Self {
        modify { $0.showArrow = showArrow }
    }

    /// Emitted to when the drop down is activated.
    /// 
    /// The `::activate` signal on `GtkDropDown` is an action signal and
    /// emitting it causes the drop down to pop up its dropdown.
    public func activate(_ activate: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.activate = activate
        return newSelf
    }

}
