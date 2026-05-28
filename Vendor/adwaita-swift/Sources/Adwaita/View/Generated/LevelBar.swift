//
//  LevelBar.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// Shows a level indicator.
/// 
/// Typical use cases are displaying the strength of a password, or
/// showing the charge level of a battery.
/// 
/// 
/// 
/// Use `Gtk.LevelBar.set_value` to set the current value, and
/// `Gtk.LevelBar.add_offset_value` to set the value offsets at which
/// the bar will be considered in a different state. GTK will add a few
/// offsets by default on the level bar: %GTK_LEVEL_BAR_OFFSET_LOW,
/// %GTK_LEVEL_BAR_OFFSET_HIGH and %GTK_LEVEL_BAR_OFFSET_FULL, with
/// values 0.25, 0.75 and 1.0 respectively.
/// 
/// Note that it is your responsibility to update preexisting offsets
/// when changing the minimum or maximum value. GTK will simply clamp
/// them to the new range.
/// 
/// 
public struct LevelBar: AdwaitaWidget {

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
    /// Whether the `GtkLeveBar` is inverted.
    /// 
    /// Level bars normally grow from top to bottom or left to right.
    /// Inverted level bars grow in the opposite direction.
    var inverted: Bool?
    /// Determines the maximum value of the interval that can be displayed by the bar.
    var maxValue: Double?
    /// Determines the minimum value of the interval that can be displayed by the bar.
    var minValue: Double?
    /// Determines the currently filled value of the level bar.
    var value: Double?
    /// Emitted when an offset specified on the bar changes value.
    /// 
    /// This typically is the result of a `Gtk.LevelBar.add_offset_value`
    /// call.
    /// 
    /// The signal supports detailed connections; you can connect to the
    /// detailed signal "changed::x" in order to only receive callbacks when
    /// the value of offset "x" changes.
    var offsetChanged: (() -> Void)?

    /// Initialize `LevelBar`.
    public init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(gtk_level_bar_new()?.opaque())
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
        if let offsetChanged {
            storage.connectSignal(name: "offset-changed", argCount: 1) {
                offsetChanged()
            }
        }
        storage.modify { widget in

            if let inverted, updateProperties, (storage.previousState as? Self)?.inverted != inverted {
                gtk_level_bar_set_inverted(widget, inverted.cBool)
            }
            if let maxValue, updateProperties, (storage.previousState as? Self)?.maxValue != maxValue {
                gtk_level_bar_set_max_value(widget, maxValue)
            }
            if let minValue, updateProperties, (storage.previousState as? Self)?.minValue != minValue {
                gtk_level_bar_set_min_value(widget, minValue)
            }
            if let value, updateProperties, (storage.previousState as? Self)?.value != value {
                gtk_level_bar_set_value(widget, value)
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

    /// Whether the `GtkLeveBar` is inverted.
    /// 
    /// Level bars normally grow from top to bottom or left to right.
    /// Inverted level bars grow in the opposite direction.
    public func inverted(_ inverted: Bool? = true) -> Self {
        modify { $0.inverted = inverted }
    }

    /// Determines the maximum value of the interval that can be displayed by the bar.
    public func maxValue(_ maxValue: Double?) -> Self {
        modify { $0.maxValue = maxValue }
    }

    /// Determines the minimum value of the interval that can be displayed by the bar.
    public func minValue(_ minValue: Double?) -> Self {
        modify { $0.minValue = minValue }
    }

    /// Determines the currently filled value of the level bar.
    public func value(_ value: Double?) -> Self {
        modify { $0.value = value }
    }

    /// Emitted when an offset specified on the bar changes value.
    /// 
    /// This typically is the result of a `Gtk.LevelBar.add_offset_value`
    /// call.
    /// 
    /// The signal supports detailed connections; you can connect to the
    /// detailed signal "changed::x" in order to only receive callbacks when
    /// the value of offset "x" changes.
    public func offsetChanged(_ offsetChanged: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.offsetChanged = offsetChanged
        return newSelf
    }

}
