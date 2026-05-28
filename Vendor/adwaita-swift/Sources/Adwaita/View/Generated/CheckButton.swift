//
//  CheckButton.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// Places a label next to an indicator.
/// 
/// 
/// 
/// A `GtkCheckButton` is created by calling either `Gtk.CheckButton.new`
/// or `Gtk.CheckButton.new_with_label`.
/// 
/// The state of a `GtkCheckButton` can be set specifically using
/// `Gtk.CheckButton.set_active`, and retrieved using
/// `Gtk.CheckButton.get_active`.
/// 
/// 
public struct CheckButton: AdwaitaWidget {

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
    /// If the check button is active.
    /// 
    /// Setting `active` to `true` will add the `:checked:` state to both
    /// the check button and the indicator CSS node.
    var active: Binding<Bool>?
    /// The child widget.
    var child: Body?
    /// If the check button is in an “in between” state.
    /// 
    /// The inconsistent state only affects visual appearance,
    /// not the semantics of the button.
    var inconsistent: Bool?
    /// Text of the label inside the check button, if it contains a label widget.
    var label: String?
    /// If set, an underline in the text indicates that the following
    /// character is to be used as mnemonic.
    var useUnderline: Bool?
    /// Emitted to when the check button is activated.
    /// 
    /// The `::activate` signal on `GtkCheckButton` is an action signal and
    /// emitting it causes the button to animate press then release.
    /// 
    /// Applications should never connect to this signal, but use the
    /// `Gtk.CheckButton::toggled` signal.
    /// 
    /// The default bindings for this signal are all forms of the
    /// <kbd>␣</kbd> and <kbd>Enter</kbd> keys.
    var activate: (() -> Void)?
    /// Emitted when the buttons's ``active(_:)``
    /// property changes.
    var toggled: (() -> Void)?

    /// Initialize `CheckButton`.
    public init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(gtk_check_button_new()?.opaque())
        for function in appearFunctions {
            function(storage, data)
        }
        if let childStorage = child?.storage(data: data, type: type) {
            storage.content["child"] = [childStorage]
            gtk_check_button_set_child(storage.opaquePointer?.cast(), childStorage.opaquePointer?.cast())
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
        if let toggled {
            storage.connectSignal(name: "toggled", argCount: 0) {
                toggled()
            }
        }
        storage.modify { widget in

        storage.notify(name: "active") {
            let newValue = gtk_check_button_get_active(storage.opaquePointer?.cast()) != 0
if let active, newValue != active.wrappedValue {
    active.wrappedValue = newValue
}
        }
            if let actionName, updateProperties, (storage.previousState as? Self)?.actionName != actionName {
                gtk_actionable_set_action_name(widget, actionName)
            }
            if let active, updateProperties, (gtk_check_button_get_active(storage.opaquePointer?.cast()) != 0) != active.wrappedValue {
                gtk_check_button_set_active(storage.opaquePointer?.cast(), active.wrappedValue.cBool)
            }
            if let widget = storage.content["child"]?.first {
                child?.updateStorage(widget, data: data, updateProperties: updateProperties, type: type)
            }
            if let inconsistent, updateProperties, (storage.previousState as? Self)?.inconsistent != inconsistent {
                gtk_check_button_set_inconsistent(widget?.cast(), inconsistent.cBool)
            }
            if let label, storage.content["child"] == nil, updateProperties, (storage.previousState as? Self)?.label != label {
                gtk_check_button_set_label(widget?.cast(), label)
            }
            if let useUnderline, updateProperties, (storage.previousState as? Self)?.useUnderline != useUnderline {
                gtk_check_button_set_use_underline(widget?.cast(), useUnderline.cBool)
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

    /// If the check button is active.
    /// 
    /// Setting `active` to `true` will add the `:checked:` state to both
    /// the check button and the indicator CSS node.
    public func active(_ active: Binding<Bool>?) -> Self {
        modify { $0.active = active }
    }

    /// The child widget.
    public func child(@ViewBuilder _ child: () -> Body) -> Self {
        modify { $0.child = child() }
    }

    /// If the check button is in an “in between” state.
    /// 
    /// The inconsistent state only affects visual appearance,
    /// not the semantics of the button.
    public func inconsistent(_ inconsistent: Bool? = true) -> Self {
        modify { $0.inconsistent = inconsistent }
    }

    /// Text of the label inside the check button, if it contains a label widget.
    public func label(_ label: String?) -> Self {
        modify { $0.label = label }
    }

    /// If set, an underline in the text indicates that the following
    /// character is to be used as mnemonic.
    public func useUnderline(_ useUnderline: Bool? = true) -> Self {
        modify { $0.useUnderline = useUnderline }
    }

    /// Emitted to when the check button is activated.
    /// 
    /// The `::activate` signal on `GtkCheckButton` is an action signal and
    /// emitting it causes the button to animate press then release.
    /// 
    /// Applications should never connect to this signal, but use the
    /// `Gtk.CheckButton::toggled` signal.
    /// 
    /// The default bindings for this signal are all forms of the
    /// <kbd>␣</kbd> and <kbd>Enter</kbd> keys.
    public func activate(_ activate: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.activate = activate
        return newSelf
    }

    /// Emitted when the buttons's ``active(_:)``
    /// property changes.
    public func toggled(_ toggled: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.toggled = toggled
        return newSelf
    }

}
