//
//  ButtonContent.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// A helper widget for creating buttons.
/// 
/// 
/// 
/// `AdwButtonContent` is a box-like widget with an icon and a label.
/// 
/// It's intended to be used as a direct child of `Gtk.Button`,
/// `Gtk.MenuButton` or `SplitButton`, when they need to have both an
/// icon and a label, as follows:
/// 
/// ```xml
/// <object class="GtkButton"><property name="child"><object class="AdwButtonContent"><property name="icon-name">document-open-symbolic</property><property name="label" translatable="yes">_Open</property><property name="use-underline">True</property></object></property></object>
/// ```
/// 
/// `AdwButtonContent` handles style classes and connecting the mnemonic to the
/// button automatically.
/// 
/// 
public struct ButtonContent: AdwaitaWidget {

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
    /// See ``canShrink(_:)``.
    var canShrink: Bool?
    /// The name of the displayed icon.
    /// 
    /// If empty, the icon is not shown.
    var iconName: String?
    /// The displayed label.
    var label: String?
    /// Whether an underline in the text indicates a mnemonic.
    /// 
    /// The mnemonic can be used to activate the parent button.
    /// 
    /// See ``label(_:)``.
    var useUnderline: Bool?

    /// Initialize `ButtonContent`.
    public init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(adw_button_content_new()?.opaque())
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
        storage.modify { widget in

            if let canShrink, updateProperties, (storage.previousState as? Self)?.canShrink != canShrink {
                adw_button_content_set_can_shrink(widget, canShrink.cBool)
            }
            if let iconName, updateProperties, (storage.previousState as? Self)?.iconName != iconName {
                adw_button_content_set_icon_name(widget, iconName)
            }
            if let label, updateProperties, (storage.previousState as? Self)?.label != label {
                adw_button_content_set_label(widget, label)
            }
            if let useUnderline, updateProperties, (storage.previousState as? Self)?.useUnderline != useUnderline {
                adw_button_content_set_use_underline(widget, useUnderline.cBool)
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
    /// See ``canShrink(_:)``.
    public func canShrink(_ canShrink: Bool? = true) -> Self {
        modify { $0.canShrink = canShrink }
    }

    /// The name of the displayed icon.
    /// 
    /// If empty, the icon is not shown.
    public func iconName(_ iconName: String?) -> Self {
        modify { $0.iconName = iconName }
    }

    /// The displayed label.
    public func label(_ label: String?) -> Self {
        modify { $0.label = label }
    }

    /// Whether an underline in the text indicates a mnemonic.
    /// 
    /// The mnemonic can be used to activate the parent button.
    /// 
    /// See ``label(_:)``.
    public func useUnderline(_ useUnderline: Bool? = true) -> Self {
        modify { $0.useUnderline = useUnderline }
    }

}
