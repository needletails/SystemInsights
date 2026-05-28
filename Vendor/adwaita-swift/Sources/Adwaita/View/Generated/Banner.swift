//
//  Banner.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// A bar with contextual information.
/// 
/// 
/// 
/// Banners are hidden by default, use ``revealed(_:)`` to show them.
/// 
/// Banners have a title, set with ``title(_:)``. Titles can be marked
/// up with Pango markup, use ``useMarkup(_:)`` to enable it.
/// 
/// The title will be shown centered or left-aligned depending on available
/// space.
/// 
/// Banners can optionally have a button with text on it, set through
/// ``buttonLabel(_:)``. The button can be used with a `GAction`,
/// or with the `Banner::button-clicked` signal. The button can have
/// different styles, a gray style and a suggested style.
/// 
/// 
/// 
/// 
public struct Banner: AdwaitaWidget {

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

    /// The label to show on the button.
    /// 
    /// If set to `""` or `NULL`, the button won't be shown.
    /// 
    /// The button can be used with a `GAction`, or with the
    /// `Banner::button-clicked` signal.
    var buttonLabel: String?
    /// Whether the banner is currently revealed.
    var revealed: Bool?
    /// The title for this banner.
    /// 
    /// See also: ``useMarkup(_:)``.
    var title: String
    /// Whether to use Pango markup for the banner title.
    /// 
    /// See also `Pango.parse_markup`.
    var useMarkup: Bool?
    /// This signal is emitted after the action button has been clicked.
    /// 
    /// It can be used as an alternative to setting an action.
    var buttonClicked: (() -> Void)?

    /// Initialize `Banner`.
    public init(title: String) {
        self.title = title
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(adw_banner_new(title)?.opaque())
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
        if let buttonClicked {
            storage.connectSignal(name: "button-clicked", argCount: 0) {
                buttonClicked()
            }
        }
        storage.modify { widget in

            if let buttonLabel, updateProperties, (storage.previousState as? Self)?.buttonLabel != buttonLabel {
                adw_banner_set_button_label(widget, buttonLabel)
            }
            if let revealed, updateProperties, (storage.previousState as? Self)?.revealed != revealed {
                adw_banner_set_revealed(widget, revealed.cBool)
            }
            if updateProperties, (storage.previousState as? Self)?.title != title {
                adw_banner_set_title(widget, title)
            }
            if let useMarkup, updateProperties, (storage.previousState as? Self)?.useMarkup != useMarkup {
                adw_banner_set_use_markup(widget, useMarkup.cBool)
            }



        }
        for function in updateFunctions {
            function(storage, data, updateProperties)
        }
        if updateProperties {
            storage.previousState = self
        }
    }

    /// The label to show on the button.
    /// 
    /// If set to `""` or `NULL`, the button won't be shown.
    /// 
    /// The button can be used with a `GAction`, or with the
    /// `Banner::button-clicked` signal.
    public func buttonLabel(_ buttonLabel: String?) -> Self {
        modify { $0.buttonLabel = buttonLabel }
    }

    /// Whether the banner is currently revealed.
    public func revealed(_ revealed: Bool? = true) -> Self {
        modify { $0.revealed = revealed }
    }

    /// The title for this banner.
    /// 
    /// See also: ``useMarkup(_:)``.
    public func title(_ title: String) -> Self {
        modify { $0.title = title }
    }

    /// Whether to use Pango markup for the banner title.
    /// 
    /// See also `Pango.parse_markup`.
    public func useMarkup(_ useMarkup: Bool? = true) -> Self {
        modify { $0.useMarkup = useMarkup }
    }

    /// This signal is emitted after the action button has been clicked.
    /// 
    /// It can be used as an alternative to setting an action.
    public func buttonClicked(_ buttonClicked: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.buttonClicked = buttonClicked
        return newSelf
    }

}
