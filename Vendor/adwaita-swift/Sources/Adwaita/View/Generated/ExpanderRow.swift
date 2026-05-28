//
//  ExpanderRow.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// A `Gtk.ListBoxRow` used to reveal widgets.
/// 
/// 
/// 
/// The `AdwExpanderRow` widget allows the user to reveal or hide widgets below
/// it. It also allows the user to enable the expansion of the row, allowing to
/// disable all that the row contains.
/// 
/// 
public struct ExpanderRow: AdwaitaWidget {

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

    /// Whether expansion is enabled.
    var enableExpansion: Binding<Bool>?
    /// Whether the row is expanded.
    var expanded: Binding<Bool>?
    /// Whether the switch enabling the expansion is visible.
    var showEnableSwitch: Bool?
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
    /// Whether an embedded underline in the title indicates a mnemonic.
    var useUnderline: Bool?
    /// The body for the widget "rows".
    var rows: () -> Body = { [] }
    /// The body for the widget "suffix".
    var suffix: () -> Body = { [] }
    /// The body for the widget "prefix".
    var prefix: () -> Body = { [] }

    /// Initialize `ExpanderRow`.
    public init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(adw_expander_row_new()?.opaque())
        for function in appearFunctions {
            function(storage, data)
        }

        var rowsStorage: [ViewStorage] = []
        for view in rows() {
            rowsStorage.append(view.storage(data: data, type: type))
            adw_expander_row_add_row(storage.opaquePointer?.cast(), rowsStorage.last?.opaquePointer?.cast())
        }
        storage.content["rows"] = rowsStorage
        var suffixStorage: [ViewStorage] = []
        for view in suffix() {
            suffixStorage.append(view.storage(data: data, type: type))
            adw_expander_row_add_suffix(storage.opaquePointer?.cast(), suffixStorage.last?.opaquePointer?.cast())
        }
        storage.content["suffix"] = suffixStorage
        var prefixStorage: [ViewStorage] = []
        for view in prefix() {
            prefixStorage.append(view.storage(data: data, type: type))
            adw_expander_row_add_prefix(storage.opaquePointer?.cast(), prefixStorage.last?.opaquePointer?.cast())
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
        storage.modify { widget in

        storage.notify(name: "enable-expansion") {
            let newValue = adw_expander_row_get_enable_expansion(storage.opaquePointer?.cast()) != 0
if let enableExpansion, newValue != enableExpansion.wrappedValue {
    enableExpansion.wrappedValue = newValue
}
        }
        storage.notify(name: "expanded") {
            let newValue = adw_expander_row_get_expanded(storage.opaquePointer?.cast()) != 0
if let expanded, newValue != expanded.wrappedValue {
    expanded.wrappedValue = newValue
}
        }
            if let enableExpansion, updateProperties, (adw_expander_row_get_enable_expansion(storage.opaquePointer?.cast()) != 0) != enableExpansion.wrappedValue {
                adw_expander_row_set_enable_expansion(storage.opaquePointer?.cast(), enableExpansion.wrappedValue.cBool)
            }
            if let expanded, updateProperties, (adw_expander_row_get_expanded(storage.opaquePointer?.cast()) != 0) != expanded.wrappedValue {
                adw_expander_row_set_expanded(storage.opaquePointer?.cast(), expanded.wrappedValue.cBool)
            }
            if let showEnableSwitch, updateProperties, (storage.previousState as? Self)?.showEnableSwitch != showEnableSwitch {
                adw_expander_row_set_show_enable_switch(widget?.cast(), showEnableSwitch.cBool)
            }
            if let subtitle, updateProperties, (storage.previousState as? Self)?.subtitle != subtitle {
                adw_expander_row_set_subtitle(widget?.cast(), subtitle)
            }
            if let subtitleLines, updateProperties, (storage.previousState as? Self)?.subtitleLines != subtitleLines {
                adw_expander_row_set_subtitle_lines(widget?.cast(), subtitleLines.cInt)
            }
            if let title, updateProperties, (storage.previousState as? Self)?.title != title {
                adw_preferences_row_set_title(widget?.cast(), title)
            }
            if let titleLines, updateProperties, (storage.previousState as? Self)?.titleLines != titleLines {
                adw_expander_row_set_title_lines(widget?.cast(), titleLines.cInt)
            }
            if let titleSelectable, updateProperties, (storage.previousState as? Self)?.titleSelectable != titleSelectable {
                adw_preferences_row_set_title_selectable(widget?.cast(), titleSelectable.cBool)
            }
            if let useMarkup, updateProperties, (storage.previousState as? Self)?.useMarkup != useMarkup {
                adw_preferences_row_set_use_markup(widget?.cast(), useMarkup.cBool)
            }
            if let useUnderline, updateProperties, (storage.previousState as? Self)?.useUnderline != useUnderline {
                adw_preferences_row_set_use_underline(widget?.cast(), useUnderline.cBool)
            }

            if let rowsStorage = storage.content["rows"] {
                for (index, view) in rows().enumerated() {
                    if let storage = rowsStorage[safe: index] {
                        view.updateStorage(
                            storage,
                            data: data,
                            updateProperties: updateProperties,
                            type: type
                        )
                    }
                }
            }
            if let suffixStorage = storage.content["suffix"] {
                for (index, view) in suffix().enumerated() {
                    if let storage = suffixStorage[safe: index] {
                        view.updateStorage(
                            storage,
                            data: data,
                            updateProperties: updateProperties,
                            type: type
                        )
                    }
                }
            }
            if let prefixStorage = storage.content["prefix"] {
                for (index, view) in prefix().enumerated() {
                    if let storage = prefixStorage[safe: index] {
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

    /// Whether expansion is enabled.
    public func enableExpansion(_ enableExpansion: Binding<Bool>?) -> Self {
        modify { $0.enableExpansion = enableExpansion }
    }

    /// Whether the row is expanded.
    public func expanded(_ expanded: Binding<Bool>?) -> Self {
        modify { $0.expanded = expanded }
    }

    /// Whether the switch enabling the expansion is visible.
    public func showEnableSwitch(_ showEnableSwitch: Bool? = true) -> Self {
        modify { $0.showEnableSwitch = showEnableSwitch }
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

    /// Whether an embedded underline in the title indicates a mnemonic.
    public func useUnderline(_ useUnderline: Bool? = true) -> Self {
        modify { $0.useUnderline = useUnderline }
    }

    /// Set the body for "rows".
    /// - Parameter body: The body.
    /// - Returns: The widget.
    public func rows(@ViewBuilder _ body: @escaping () -> Body) -> Self {
        var newSelf = self
        newSelf.rows = body
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
