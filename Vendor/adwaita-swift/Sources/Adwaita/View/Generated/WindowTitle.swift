//
//  WindowTitle.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// A helper widget for setting a window's title and subtitle.
/// 
/// 
/// 
/// `AdwWindowTitle` shows a title and subtitle. It's intended to be used as the
/// title child of `Gtk.HeaderBar` or `HeaderBar`.
/// 
/// 
public struct WindowTitle: AdwaitaWidget {

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

    /// The subtitle to display.
    /// 
    /// The subtitle should give the user additional details.
    var subtitle: String
    /// The title to display.
    /// 
    /// The title typically identifies the current view or content item, and
    /// generally does not use the application name.
    var title: String

    /// Initialize `WindowTitle`.
    public init(subtitle: String, title: String) {
        self.subtitle = subtitle
        self.title = title
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(adw_window_title_new(title, subtitle)?.opaque())
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

            if updateProperties, (storage.previousState as? Self)?.subtitle != subtitle {
                adw_window_title_set_subtitle(widget, subtitle)
            }
            if updateProperties, (storage.previousState as? Self)?.title != title {
                adw_window_title_set_title(widget, title)
            }



        }
        for function in updateFunctions {
            function(storage, data, updateProperties)
        }
        if updateProperties {
            storage.previousState = self
        }
    }

    /// The subtitle to display.
    /// 
    /// The subtitle should give the user additional details.
    public func subtitle(_ subtitle: String) -> Self {
        modify { $0.subtitle = subtitle }
    }

    /// The title to display.
    /// 
    /// The title typically identifies the current view or content item, and
    /// generally does not use the application name.
    public func title(_ title: String) -> Self {
        modify { $0.title = title }
    }

}
