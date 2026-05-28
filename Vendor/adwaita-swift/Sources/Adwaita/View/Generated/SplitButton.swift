//
//  SplitButton.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// A combined button and dropdown widget.
/// 
/// 
/// 
/// `AdwSplitButton` is typically used to present a set of actions in a menu,
/// but allow access to one of them with a single click.
/// 
/// The API is very similar to `Gtk.Button` and `Gtk.MenuButton`, see
/// their documentation for details.
/// 
/// 
public struct SplitButton: AdwaitaWidget {

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

    /// Whether the button can be smaller than the natural size of its contents.
    /// 
    /// If set to `true`, the label will ellipsize.
    /// 
    /// See ``canShrink(_:)`` and
    /// ``canShrink(_:)``.
    var canShrink: Bool?
    /// The child widget.
    /// 
    /// Setting the child widget will set ``label(_:)`` and
    /// ``iconName(_:)`` to `NULL`.
    var child: Body?
    /// The tooltip of the dropdown button.
    /// 
    /// The tooltip can be marked up with the Pango text markup language.
    var dropdownTooltip: String?
    /// The name of the icon used to automatically populate the button.
    /// 
    /// Setting the icon name will set ``label(_:)`` and
    /// ``child(_:)`` to `NULL`.
    var iconName: String?
    /// The label for the button.
    /// 
    /// Setting the label will set ``iconName(_:)`` and
    /// ``child(_:)`` to `NULL`.
    var label: String?
    /// The `GMenuModel` from which the popup will be created.
    /// 
    /// If the menu model is `NULL`, the dropdown is disabled.
    /// 
    /// A `Gtk.Popover` will be created from the menu model with
    /// `Gtk.PopoverMenu.new_from_model`. Actions will be connected as
    /// documented for this function.
    /// 
    /// If ``popover(_:)`` is already set, it will be dissociated
    /// from the button, and the property is set to `NULL`.
    var menuModel: Body?
    /// Whether an underline in the text indicates a mnemonic.
    /// 
    /// See ``label(_:)``.
    var useUnderline: Bool?
    /// Emitted to animate press then release.
    /// 
    /// This is an action signal. Applications should never connect to this signal,
    /// but use the `SplitButton::clicked` signal.
    var activate: (() -> Void)?
    /// Emitted when the button has been activated (pressed and released).
    var clicked: (() -> Void)?

    /// Initialize `SplitButton`.
    public init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(adw_split_button_new()?.opaque())
        for function in appearFunctions {
            function(storage, data)
        }
        if let childStorage = child?.storage(data: data, type: type) {
            storage.content["child"] = [childStorage]
            adw_split_button_set_child(storage.opaquePointer, childStorage.opaquePointer?.cast())
        }
        if let menuModel {
            let childStorage = MenuCollection { menuModel }.getMenu(data: data)
            storage.content["menuModel"] = [childStorage]
            adw_split_button_set_menu_model(storage.opaquePointer, childStorage.opaquePointer?.cast())
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
        if let clicked {
            storage.connectSignal(name: "clicked", argCount: 0) {
                clicked()
            }
        }
        storage.modify { widget in

            if let canShrink, updateProperties, (storage.previousState as? Self)?.canShrink != canShrink {
                adw_split_button_set_can_shrink(widget, canShrink.cBool)
            }
            if let widget = storage.content["child"]?.first {
                child?.updateStorage(widget, data: data, updateProperties: updateProperties, type: type)
            }
            if let dropdownTooltip, updateProperties, (storage.previousState as? Self)?.dropdownTooltip != dropdownTooltip {
                adw_split_button_set_dropdown_tooltip(widget, dropdownTooltip)
            }
            if let iconName, updateProperties, (storage.previousState as? Self)?.iconName != iconName {
                adw_split_button_set_icon_name(widget, iconName)
            }
            if let label, storage.content["child"] == nil, updateProperties, (storage.previousState as? Self)?.label != label {
                adw_split_button_set_label(widget, label)
            }
            if let menu = storage.content["menuModel"]?.first {
                MenuCollection { menuModel ?? [] }
                    .updateStorage(menu, data: data.noModifiers, updateProperties: updateProperties, type: MenuContext.self)
            }
            if let useUnderline, updateProperties, (storage.previousState as? Self)?.useUnderline != useUnderline {
                adw_split_button_set_use_underline(widget, useUnderline.cBool)
            }



        }
        for function in updateFunctions {
            function(storage, data, updateProperties)
        }
        if updateProperties {
            storage.previousState = self
        }
    }

    /// Whether the button can be smaller than the natural size of its contents.
    /// 
    /// If set to `true`, the label will ellipsize.
    /// 
    /// See ``canShrink(_:)`` and
    /// ``canShrink(_:)``.
    public func canShrink(_ canShrink: Bool? = true) -> Self {
        modify { $0.canShrink = canShrink }
    }

    /// The child widget.
    /// 
    /// Setting the child widget will set ``label(_:)`` and
    /// ``iconName(_:)`` to `NULL`.
    public func child(@ViewBuilder _ child: () -> Body) -> Self {
        modify { $0.child = child() }
    }

    /// The tooltip of the dropdown button.
    /// 
    /// The tooltip can be marked up with the Pango text markup language.
    public func dropdownTooltip(_ dropdownTooltip: String?) -> Self {
        modify { $0.dropdownTooltip = dropdownTooltip }
    }

    /// The name of the icon used to automatically populate the button.
    /// 
    /// Setting the icon name will set ``label(_:)`` and
    /// ``child(_:)`` to `NULL`.
    public func iconName(_ iconName: String?) -> Self {
        modify { $0.iconName = iconName }
    }

    /// The label for the button.
    /// 
    /// Setting the label will set ``iconName(_:)`` and
    /// ``child(_:)`` to `NULL`.
    public func label(_ label: String?) -> Self {
        modify { $0.label = label }
    }

    /// The `GMenuModel` from which the popup will be created.
    /// 
    /// If the menu model is `NULL`, the dropdown is disabled.
    /// 
    /// A `Gtk.Popover` will be created from the menu model with
    /// `Gtk.PopoverMenu.new_from_model`. Actions will be connected as
    /// documented for this function.
    /// 
    /// If ``popover(_:)`` is already set, it will be dissociated
    /// from the button, and the property is set to `NULL`.
    public func menuModel(@ViewBuilder _ menuModel: () -> Body) -> Self {
        modify { $0.menuModel = menuModel() }
    }

    /// Whether an underline in the text indicates a mnemonic.
    /// 
    /// See ``label(_:)``.
    public func useUnderline(_ useUnderline: Bool? = true) -> Self {
        modify { $0.useUnderline = useUnderline }
    }

    /// Emitted to animate press then release.
    /// 
    /// This is an action signal. Applications should never connect to this signal,
    /// but use the `SplitButton::clicked` signal.
    public func activate(_ activate: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.activate = activate
        return newSelf
    }

    /// Emitted when the button has been activated (pressed and released).
    public func clicked(_ clicked: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.clicked = clicked
        return newSelf
    }

}
