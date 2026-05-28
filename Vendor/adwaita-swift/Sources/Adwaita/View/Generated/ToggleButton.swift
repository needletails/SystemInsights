//
//  ToggleButton.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// Shows a button which remains “pressed-in” when clicked.
/// 
/// 
/// 
/// Clicking again will cause the toggle button to return to its normal state.
/// 
/// A toggle button is created by calling either `Gtk.ToggleButton.new` or
/// `Gtk.ToggleButton.new_with_label`. If using the former, it is advisable
/// to pack a widget, (such as a `GtkLabel` and/or a `GtkImage`), into the toggle
/// button’s container. (See `Gtk.Button` for more information).
/// 
/// The state of a `GtkToggleButton` can be set specifically using
/// `Gtk.ToggleButton.set_active`, and retrieved using
/// `Gtk.ToggleButton.get_active`.
/// 
/// 
public struct ToggleButton: AdwaitaWidget {

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
    /// The name of the action with which this widget should be associated.
    var actionName: String?
    /// If the toggle button should be pressed in.
    var active: Binding<Bool>?
    /// Whether the size of the button can be made smaller than the natural
    /// size of its contents.
    /// 
    /// For text buttons, setting this property will allow ellipsizing the label.
    /// 
    /// If the contents of a button are an icon or a custom widget, setting this
    /// property has no effect.
    var canShrink: Bool?
    /// The child widget.
    var child: Body?
    /// Whether the button has a frame.
    var hasFrame: Bool?
    /// The name of the icon used to automatically populate the button.
    var iconName: String?
    /// Text of the label inside the button, if the button contains a label widget.
    var label: String?
    /// If set, an underline in the text indicates that the following character is
    /// to be used as mnemonic.
    var useUnderline: Bool?
    /// Emitted to animate press then release.
    /// 
    /// This is an action signal. Applications should never connect
    /// to this signal, but use the `Gtk.Button::clicked` signal.
    /// 
    /// The default bindings for this signal are all forms of the
    /// <kbd>␣</kbd> and <kbd>Enter</kbd> keys.
    var activate: (() -> Void)?
    /// Emitted when the button has been activated (pressed and released).
    var clicked: (() -> Void)?
    /// Emitted whenever the `GtkToggleButton`'s state is changed.
    var toggled: (() -> Void)?

    /// Initialize `ToggleButton`.
    init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(gtk_toggle_button_new()?.opaque())
        for function in appearFunctions {
            function(storage, data)
        }
        if let childStorage = child?.storage(data: data, type: type) {
            storage.content["child"] = [childStorage]
            gtk_button_set_child(storage.opaquePointer?.cast(), childStorage.opaquePointer?.cast())
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
        if let toggled {
            storage.connectSignal(name: "toggled", argCount: 0) {
                toggled()
            }
        }
        storage.modify { widget in

        storage.notify(name: "active") {
            let newValue = gtk_toggle_button_get_active(storage.opaquePointer?.cast()) != 0
if let active, newValue != active.wrappedValue {
    active.wrappedValue = newValue
}
        }
            if let actionName, updateProperties, (storage.previousState as? Self)?.actionName != actionName {
                gtk_actionable_set_action_name(widget, actionName)
            }
            if let active, updateProperties, (gtk_toggle_button_get_active(storage.opaquePointer?.cast()) != 0) != active.wrappedValue {
                gtk_toggle_button_set_active(storage.opaquePointer?.cast(), active.wrappedValue.cBool)
            }
            if let canShrink, updateProperties, (storage.previousState as? Self)?.canShrink != canShrink {
                gtk_button_set_can_shrink(widget?.cast(), canShrink.cBool)
            }
            if let widget = storage.content["child"]?.first {
                child?.updateStorage(widget, data: data, updateProperties: updateProperties, type: type)
            }
            if let hasFrame, updateProperties, (storage.previousState as? Self)?.hasFrame != hasFrame {
                gtk_button_set_has_frame(widget?.cast(), hasFrame.cBool)
            }
            if let iconName, updateProperties, (storage.previousState as? Self)?.iconName != iconName {
                gtk_button_set_icon_name(widget?.cast(), iconName)
            }
            if let label, storage.content["child"] == nil, updateProperties, (storage.previousState as? Self)?.label != label {
                gtk_button_set_label(widget?.cast(), label)
            }
            if let useUnderline, updateProperties, (storage.previousState as? Self)?.useUnderline != useUnderline {
                gtk_button_set_use_underline(widget?.cast(), useUnderline.cBool)
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

    /// The name of the action with which this widget should be associated.
    public func actionName(_ actionName: String?) -> Self {
        modify { $0.actionName = actionName }
    }

    /// If the toggle button should be pressed in.
    public func active(_ active: Binding<Bool>?) -> Self {
        modify { $0.active = active }
    }

    /// Whether the size of the button can be made smaller than the natural
    /// size of its contents.
    /// 
    /// For text buttons, setting this property will allow ellipsizing the label.
    /// 
    /// If the contents of a button are an icon or a custom widget, setting this
    /// property has no effect.
    public func canShrink(_ canShrink: Bool? = true) -> Self {
        modify { $0.canShrink = canShrink }
    }

    /// The child widget.
    public func child(@ViewBuilder _ child: () -> Body) -> Self {
        modify { $0.child = child() }
    }

    /// Whether the button has a frame.
    public func hasFrame(_ hasFrame: Bool? = true) -> Self {
        modify { $0.hasFrame = hasFrame }
    }

    /// The name of the icon used to automatically populate the button.
    public func iconName(_ iconName: String?) -> Self {
        modify { $0.iconName = iconName }
    }

    /// Text of the label inside the button, if the button contains a label widget.
    public func label(_ label: String?) -> Self {
        modify { $0.label = label }
    }

    /// If set, an underline in the text indicates that the following character is
    /// to be used as mnemonic.
    public func useUnderline(_ useUnderline: Bool? = true) -> Self {
        modify { $0.useUnderline = useUnderline }
    }

    /// Emitted to animate press then release.
    /// 
    /// This is an action signal. Applications should never connect
    /// to this signal, but use the `Gtk.Button::clicked` signal.
    /// 
    /// The default bindings for this signal are all forms of the
    /// <kbd>␣</kbd> and <kbd>Enter</kbd> keys.
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

    /// Emitted whenever the `GtkToggleButton`'s state is changed.
    public func toggled(_ toggled: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.toggled = toggled
        return newSelf
    }

}
