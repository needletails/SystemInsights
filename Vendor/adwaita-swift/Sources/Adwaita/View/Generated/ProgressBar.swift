//
//  ProgressBar.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// Displays the progress of a long-running operation.
/// 
/// `GtkProgressBar` provides a visual clue that processing is underway.
/// It can be used in two different modes: percentage mode and activity mode.
/// 
/// 
/// 
/// When an application can determine how much work needs to take place
/// (e.g. read a fixed number of bytes from a file) and can monitor its
/// progress, it can use the `GtkProgressBar` in percentage mode and the
/// user sees a growing bar indicating the percentage of the work that
/// has been completed. In this mode, the application is required to call
/// `Gtk.ProgressBar.set_fraction` periodically to update the progress bar.
/// 
/// When an application has no accurate way of knowing the amount of work
/// to do, it can use the `GtkProgressBar` in activity mode, which shows
/// activity by a block moving back and forth within the progress area. In
/// this mode, the application is required to call `Gtk.ProgressBar.pulse`
/// periodically to update the progress bar.
/// 
/// There is quite a bit of flexibility provided to control the appearance
/// of the `GtkProgressBar`. Functions are provided to control the orientation
/// of the bar, optional text can be displayed along with the bar, and the
/// step size used in activity mode can be set.
/// 
/// 
public struct ProgressBar: AdwaitaWidget {

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
    /// The fraction of total work that has been completed.
    var fraction: Double?
    /// Invert the direction in which the progress bar grows.
    var inverted: Bool?
    /// The fraction of total progress to move the bounding block when pulsed.
    var pulseStep: Double?
    /// Sets whether the progress bar will show a text in addition
    /// to the bar itself.
    /// 
    /// The shown text is either the value of the ``text(_:)``
    /// property or, if that is %NULL, the ``fraction(_:)``
    /// value, as a percentage.
    /// 
    /// To make a progress bar that is styled and sized suitably for showing text
    /// (even if the actual text is blank), set ``showText(_:)``
    /// to `true` and ``text(_:)`` to the empty string (not %NULL).
    var showText: Bool?
    /// Text to be displayed in the progress bar.
    var text: String?

    /// Initialize `ProgressBar`.
    init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(gtk_progress_bar_new()?.opaque())
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

            if let fraction, updateProperties, (storage.previousState as? Self)?.fraction != fraction {
                gtk_progress_bar_set_fraction(widget, fraction)
            }
            if let inverted, updateProperties, (storage.previousState as? Self)?.inverted != inverted {
                gtk_progress_bar_set_inverted(widget, inverted.cBool)
            }
            if let pulseStep, updateProperties, (storage.previousState as? Self)?.pulseStep != pulseStep {
                gtk_progress_bar_set_pulse_step(widget, pulseStep)
            }
            if let showText, updateProperties, (storage.previousState as? Self)?.showText != showText {
                gtk_progress_bar_set_show_text(widget, showText.cBool)
            }
            if let text, updateProperties, (storage.previousState as? Self)?.text != text {
                gtk_progress_bar_set_text(widget, text)
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

    /// The fraction of total work that has been completed.
    public func fraction(_ fraction: Double?) -> Self {
        modify { $0.fraction = fraction }
    }

    /// Invert the direction in which the progress bar grows.
    public func inverted(_ inverted: Bool? = true) -> Self {
        modify { $0.inverted = inverted }
    }

    /// The fraction of total progress to move the bounding block when pulsed.
    public func pulseStep(_ pulseStep: Double?) -> Self {
        modify { $0.pulseStep = pulseStep }
    }

    /// Sets whether the progress bar will show a text in addition
    /// to the bar itself.
    /// 
    /// The shown text is either the value of the ``text(_:)``
    /// property or, if that is %NULL, the ``fraction(_:)``
    /// value, as a percentage.
    /// 
    /// To make a progress bar that is styled and sized suitably for showing text
    /// (even if the actual text is blank), set ``showText(_:)``
    /// to `true` and ``text(_:)`` to the empty string (not %NULL).
    public func showText(_ showText: Bool? = true) -> Self {
        modify { $0.showText = showText }
    }

    /// Text to be displayed in the progress bar.
    public func text(_ text: String?) -> Self {
        modify { $0.text = text }
    }

}
