//
//  ComboRow.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// A `Gtk.ListBoxRow` used to choose from a list of items.
/// 
/// 
/// 
/// The `AdwComboRow` widget allows the user to choose from a list of valid
/// choices. The row displays the selected choice. When activated, the row
/// displays a popover which allows the user to make a new choice.
/// 
/// Example of an `AdwComboRow` UI definition:
/// ```xml
/// <object class="AdwComboRow"><property name="title" translatable="yes">Combo Row</property><property name="model"><object class="GtkStringList"><items><item translatable="yes">Foo</item><item translatable="yes">Bar</item><item translatable="yes">Baz</item></items></object></property></object>
/// ```
/// 
/// The ``selected(_:)`` and ``selectedItem(_:)``
/// properties can be used to keep track of the selected item and react to their
/// changes.
/// 
/// `AdwComboRow` mirrors `Gtk.DropDown`, see that widget for details.
/// 
/// `AdwComboRow` is ``activatable(_:)`` if a model is set.
/// 
/// 
public struct ComboRow: AdwaitaWidget {

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

    /// The widget to activate when the row is activated.
    /// 
    /// The row can be activated either by clicking on it, calling
    /// `ActionRow.activate`, or via mnemonics in the title.
    /// See the ``useUnderline(_:)`` property to enable
    /// mnemonics.
    /// 
    /// The target widget will be activated by emitting the
    /// `Gtk.Widget::mnemonic-activate` signal on it.
    var activatableWidget: Body?
    /// Whether to show a search entry in the popup.
    /// 
    /// If set to `true`, a search entry will be shown in the popup that
    /// allows to search for items in the list.
    /// 
    /// Search requires ``expression(_:)`` to be set.
    var enableSearch: Bool?
    /// The position of the selected item.
    /// 
    /// If no item is selected, the property has the value
    /// `Gtk.INVALID_LIST_POSITION`
    var selected: Binding<UInt>?
    /// The subtitle for this row.
    /// 
    /// The subtitle is interpreted as Pango markup unless
    /// ``useMarkup(_:)`` is set to `false`.
    var subtitle: String?
    /// The number of lines at the end of which the subtitle label will be
    /// ellipsized.
    /// 
    /// If the value is 0, the number of lines won't be limited.
    var subtitleLines: Int?
    /// Whether the user can copy the subtitle from the label.
    /// 
    /// See also ``selectable(_:)``.
    var subtitleSelectable: Bool?
    /// The title of the preference represented by this row.
    /// 
    /// The title is interpreted as Pango markup unless
    /// ``useMarkup(_:)`` is set to `false`.
    var title: String?
    /// The number of lines at the end of which the title label will be ellipsized.
    /// 
    /// If the value is 0, the number of lines won't be limited.
    var titleLines: Int?
    /// Whether the user can copy the title from the label.
    /// 
    /// See also ``selectable(_:)``.
    var titleSelectable: Bool?
    /// Whether to use Pango markup for the title label.
    /// 
    /// Subclasses may also use it for other labels, such as subtitle.
    /// 
    /// See also `Pango.parse_markup`.
    var useMarkup: Bool?
    /// Whether to use the current value as the subtitle.
    /// 
    /// If you use a custom list item factory, you will need to give the row a
    /// name conversion expression with ``expression(_:)``.
    /// 
    /// If set to `true`, you should not access ``subtitle(_:)``.
    /// 
    /// The subtitle is interpreted as Pango markup if
    /// ``useMarkup(_:)`` is set to `true`.
    var useSubtitle: Bool?
    /// Whether an embedded underline in the title indicates a mnemonic.
    var useUnderline: Bool?
    /// This signal is emitted after the row has been activated.
    var activated: (() -> Void)?
    /// The body for the widget "suffix".
    var suffix: () -> Body = { [] }
    /// The body for the widget "prefix".
    var prefix: () -> Body = { [] }

    /// Initialize `ComboRow`.
    init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(adw_combo_row_new()?.opaque())
        for function in appearFunctions {
            function(storage, data)
        }
        if let activatableWidgetStorage = activatableWidget?.storage(data: data, type: type) {
            storage.content["activatableWidget"] = [activatableWidgetStorage]
            adw_action_row_set_activatable_widget(storage.opaquePointer?.cast(), activatableWidgetStorage.opaquePointer?.cast())
        }

        var suffixStorage: [ViewStorage] = []
        for view in suffix() {
            suffixStorage.append(view.storage(data: data, type: type))
            adw_action_row_add_suffix(storage.opaquePointer?.cast(), suffixStorage.last?.opaquePointer?.cast())
        }
        storage.content["suffix"] = suffixStorage
        var prefixStorage: [ViewStorage] = []
        for view in prefix() {
            prefixStorage.append(view.storage(data: data, type: type))
            adw_action_row_add_prefix(storage.opaquePointer?.cast(), prefixStorage.last?.opaquePointer?.cast())
        }
        storage.content["prefix"] = prefixStorage
        return storage
    }

    /// Update the stored content.
    /// - Parameters:
    ///     - storage: The storage to update.
    ///     - modifiers: Modify views before being updated
    ///     - updateProperties: Whether to update the view's properties.
    ///     - type: The view render data type.
    public func update<Data>(_ storage: ViewStorage, data: WidgetData, updateProperties: Bool, type: Data.Type) where Data: ViewRenderData {
        if let activated {
            storage.connectSignal(name: "activated", argCount: 0) {
                activated()
            }
        }
        storage.modify { widget in

        storage.notify(name: "selected") {
            let newValue = UInt(adw_combo_row_get_selected(storage.opaquePointer?.cast()))
if let selected, newValue != selected.wrappedValue {
    selected.wrappedValue = newValue
}
        }
            if let widget = storage.content["activatableWidget"]?.first {
                activatableWidget?.updateStorage(widget, data: data, updateProperties: updateProperties, type: type)
            }
            if let enableSearch, updateProperties, (storage.previousState as? Self)?.enableSearch != enableSearch {
                adw_combo_row_set_enable_search(widget?.cast(), enableSearch.cBool)
            }
            if let selected, updateProperties, (UInt(adw_combo_row_get_selected(storage.opaquePointer?.cast()))) != selected.wrappedValue {
                adw_combo_row_set_selected(storage.opaquePointer?.cast(), selected.wrappedValue.cInt)
            }
            if let subtitle, updateProperties, (storage.previousState as? Self)?.subtitle != subtitle {
                adw_action_row_set_subtitle(widget?.cast(), subtitle)
            }
            if let subtitleLines, updateProperties, (storage.previousState as? Self)?.subtitleLines != subtitleLines {
                adw_action_row_set_subtitle_lines(widget?.cast(), subtitleLines.cInt)
            }
            if let subtitleSelectable, updateProperties, (storage.previousState as? Self)?.subtitleSelectable != subtitleSelectable {
                adw_action_row_set_subtitle_selectable(widget?.cast(), subtitleSelectable.cBool)
            }
            if let title, updateProperties, (storage.previousState as? Self)?.title != title {
                adw_preferences_row_set_title(widget?.cast(), title)
            }
            if let titleLines, updateProperties, (storage.previousState as? Self)?.titleLines != titleLines {
                adw_action_row_set_title_lines(widget?.cast(), titleLines.cInt)
            }
            if let titleSelectable, updateProperties, (storage.previousState as? Self)?.titleSelectable != titleSelectable {
                adw_preferences_row_set_title_selectable(widget?.cast(), titleSelectable.cBool)
            }
            if let useMarkup, updateProperties, (storage.previousState as? Self)?.useMarkup != useMarkup {
                adw_preferences_row_set_use_markup(widget?.cast(), useMarkup.cBool)
            }
            if let useSubtitle, updateProperties, (storage.previousState as? Self)?.useSubtitle != useSubtitle {
                adw_combo_row_set_use_subtitle(widget?.cast(), useSubtitle.cBool)
            }
            if let useUnderline, updateProperties, (storage.previousState as? Self)?.useUnderline != useUnderline {
                adw_preferences_row_set_use_underline(widget?.cast(), useUnderline.cBool)
            }



        }
        for function in updateFunctions {
            function(storage, data, updateProperties)
        }
        if updateProperties {
            storage.previousState = self
        }
    }

    /// The widget to activate when the row is activated.
    /// 
    /// The row can be activated either by clicking on it, calling
    /// `ActionRow.activate`, or via mnemonics in the title.
    /// See the ``useUnderline(_:)`` property to enable
    /// mnemonics.
    /// 
    /// The target widget will be activated by emitting the
    /// `Gtk.Widget::mnemonic-activate` signal on it.
    public func activatableWidget(@ViewBuilder _ activatableWidget: () -> Body) -> Self {
        modify { $0.activatableWidget = activatableWidget() }
    }

    /// Whether to show a search entry in the popup.
    /// 
    /// If set to `true`, a search entry will be shown in the popup that
    /// allows to search for items in the list.
    /// 
    /// Search requires ``expression(_:)`` to be set.
    public func enableSearch(_ enableSearch: Bool? = true) -> Self {
        modify { $0.enableSearch = enableSearch }
    }

    /// The position of the selected item.
    /// 
    /// If no item is selected, the property has the value
    /// `Gtk.INVALID_LIST_POSITION`
    public func selected(_ selected: Binding<UInt>?) -> Self {
        modify { $0.selected = selected }
    }

    /// The subtitle for this row.
    /// 
    /// The subtitle is interpreted as Pango markup unless
    /// ``useMarkup(_:)`` is set to `false`.
    public func subtitle(_ subtitle: String?) -> Self {
        modify { $0.subtitle = subtitle }
    }

    /// The number of lines at the end of which the subtitle label will be
    /// ellipsized.
    /// 
    /// If the value is 0, the number of lines won't be limited.
    public func subtitleLines(_ subtitleLines: Int?) -> Self {
        modify { $0.subtitleLines = subtitleLines }
    }

    /// Whether the user can copy the subtitle from the label.
    /// 
    /// See also ``selectable(_:)``.
    public func subtitleSelectable(_ subtitleSelectable: Bool? = true) -> Self {
        modify { $0.subtitleSelectable = subtitleSelectable }
    }

    /// The title of the preference represented by this row.
    /// 
    /// The title is interpreted as Pango markup unless
    /// ``useMarkup(_:)`` is set to `false`.
    public func title(_ title: String?) -> Self {
        modify { $0.title = title }
    }

    /// The number of lines at the end of which the title label will be ellipsized.
    /// 
    /// If the value is 0, the number of lines won't be limited.
    public func titleLines(_ titleLines: Int?) -> Self {
        modify { $0.titleLines = titleLines }
    }

    /// Whether the user can copy the title from the label.
    /// 
    /// See also ``selectable(_:)``.
    public func titleSelectable(_ titleSelectable: Bool? = true) -> Self {
        modify { $0.titleSelectable = titleSelectable }
    }

    /// Whether to use Pango markup for the title label.
    /// 
    /// Subclasses may also use it for other labels, such as subtitle.
    /// 
    /// See also `Pango.parse_markup`.
    public func useMarkup(_ useMarkup: Bool? = true) -> Self {
        modify { $0.useMarkup = useMarkup }
    }

    /// Whether to use the current value as the subtitle.
    /// 
    /// If you use a custom list item factory, you will need to give the row a
    /// name conversion expression with ``expression(_:)``.
    /// 
    /// If set to `true`, you should not access ``subtitle(_:)``.
    /// 
    /// The subtitle is interpreted as Pango markup if
    /// ``useMarkup(_:)`` is set to `true`.
    public func useSubtitle(_ useSubtitle: Bool? = true) -> Self {
        modify { $0.useSubtitle = useSubtitle }
    }

    /// Whether an embedded underline in the title indicates a mnemonic.
    public func useUnderline(_ useUnderline: Bool? = true) -> Self {
        modify { $0.useUnderline = useUnderline }
    }

    /// This signal is emitted after the row has been activated.
    public func activated(_ activated: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.activated = activated
        return newSelf
    }

    /// Set the body for "suffix".
    /// - Parameter body: The body.
    /// - Returns: The widget.
    public func suffix(@ViewBuilder _ body: @escaping () -> Body) -> Self {
        var newSelf = self
        newSelf.suffix = body
        return newSelf
    }
    /// Set the body for "prefix".
    /// - Parameter body: The body.
    /// - Returns: The widget.
    public func prefix(@ViewBuilder _ body: @escaping () -> Body) -> Self {
        var newSelf = self
        newSelf.prefix = body
        return newSelf
    }
}
