//
//  StatusPage.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// A page used for empty/error states and similar use-cases.
/// 
/// 
/// 
/// The `AdwStatusPage` widget can have an icon, a title, a description and a
/// custom widget which is displayed below them.
/// 
/// 
public struct StatusPage: AdwaitaWidget {

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

    /// The child widget.
    var child: Body?
    /// The description markup to be displayed below the title.
    var description: String?
    /// The name of the icon to be used.
    /// 
    /// Changing this will set ``paintable(_:)`` to `NULL`.
    var iconName: String?
    /// The title to be displayed below the icon.
    /// 
    /// It is not parsed as Pango markup.
    var title: String?

    /// Initialize `StatusPage`.
    public init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(adw_status_page_new()?.opaque())
        for function in appearFunctions {
            function(storage, data)
        }
        if let childStorage = child?.storage(data: data, type: type) {
            storage.content["child"] = [childStorage]
            adw_status_page_set_child(storage.opaquePointer, childStorage.opaquePointer?.cast())
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

            if let widget = storage.content["child"]?.first {
                child?.updateStorage(widget, data: data, updateProperties: updateProperties, type: type)
            }
            if let description, updateProperties, (storage.previousState as? Self)?.description != description {
                adw_status_page_set_description(widget, description)
            }
            if let iconName, updateProperties, (storage.previousState as? Self)?.iconName != iconName {
                adw_status_page_set_icon_name(widget, iconName)
            }
            if let title, updateProperties, (storage.previousState as? Self)?.title != title {
                adw_status_page_set_title(widget, title)
            }



        }
        for function in updateFunctions {
            function(storage, data, updateProperties)
        }
        if updateProperties {
            storage.previousState = self
        }
    }

    /// The child widget.
    public func child(@ViewBuilder _ child: () -> Body) -> Self {
        modify { $0.child = child() }
    }

    /// The description markup to be displayed below the title.
    public func description(_ description: String?) -> Self {
        modify { $0.description = description }
    }

    /// The name of the icon to be used.
    /// 
    /// Changing this will set ``paintable(_:)`` to `NULL`.
    public func iconName(_ iconName: String?) -> Self {
        modify { $0.iconName = iconName }
    }

    /// The title to be displayed below the icon.
    /// 
    /// It is not parsed as Pango markup.
    public func title(_ title: String?) -> Self {
        modify { $0.title = title }
    }

}
