//
//  PreferencesGroup.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// A group of preference rows.
/// 
/// 
/// 
/// An `AdwPreferencesGroup` represents a group or tightly related preferences,
/// which in turn are represented by `PreferencesRow`.
/// 
/// To summarize the role of the preferences it gathers, a group can have both a
/// title and a description. The title will be used by `PreferencesDialog`
/// to let the user look for a preference.
/// 
/// The ``separateRows(_:)`` property can be used to
/// separate the rows within the group, same as when using the
/// [`.boxed-list-separate`](style-classes.html
public struct PreferencesGroup: AdwaitaWidget {

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

    /// The description for this group of preferences.
    var description: String?
    /// The header suffix widget.
    /// 
    /// Displayed above the list, next to the title and description.
    /// 
    /// Suffixes are commonly used to show a button or a spinner for the whole
    /// group.
    var headerSuffix: Body?
    /// Whether to separate rows.
    /// 
    /// Equivalent to using the
    /// [`.boxed-list-separate`](style-classes.html
    var separateRows: Bool?
    /// The title for this group of preferences.
    var title: String?
    /// The body for the widget "child".
    var child: () -> Body = { [] }

    /// Initialize `PreferencesGroup`.
    init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(adw_preferences_group_new()?.opaque())
        for function in appearFunctions {
            function(storage, data)
        }
        if let headerSuffixStorage = headerSuffix?.storage(data: data, type: type) {
            storage.content["headerSuffix"] = [headerSuffixStorage]
            adw_preferences_group_set_header_suffix(storage.opaquePointer?.cast(), headerSuffixStorage.opaquePointer?.cast())
        }

        var childStorage: [ViewStorage] = []
        for view in child() {
            childStorage.append(view.storage(data: data, type: type))
            adw_preferences_group_add(storage.opaquePointer?.cast(), childStorage.last?.opaquePointer?.cast())
        }
        storage.content["child"] = childStorage
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

            if let description, updateProperties, (storage.previousState as? Self)?.description != description {
                adw_preferences_group_set_description(widget?.cast(), description)
            }
            if let widget = storage.content["headerSuffix"]?.first {
                headerSuffix?.updateStorage(widget, data: data, updateProperties: updateProperties, type: type)
            }
            if let separateRows, updateProperties, (storage.previousState as? Self)?.separateRows != separateRows {
                adw_preferences_group_set_separate_rows(widget?.cast(), separateRows.cBool)
            }
            if let title, updateProperties, (storage.previousState as? Self)?.title != title {
                adw_preferences_group_set_title(widget?.cast(), title)
            }

            if let childStorage = storage.content["child"] {
                for (index, view) in child().enumerated() {
                    if let storage = childStorage[safe: index] {
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

    /// The description for this group of preferences.
    public func description(_ description: String?) -> Self {
        modify { $0.description = description }
    }

    /// The header suffix widget.
    /// 
    /// Displayed above the list, next to the title and description.
    /// 
    /// Suffixes are commonly used to show a button or a spinner for the whole
    /// group.
    public func headerSuffix(@ViewBuilder _ headerSuffix: () -> Body) -> Self {
        modify { $0.headerSuffix = headerSuffix() }
    }

    /// Whether to separate rows.
    /// 
    /// Equivalent to using the
    /// [`.boxed-list-separate`](style-classes.html
    public func separateRows(_ separateRows: Bool? = true) -> Self {
        modify { $0.separateRows = separateRows }
    }

    /// The title for this group of preferences.
    public func title(_ title: String?) -> Self {
        modify { $0.title = title }
    }

    /// Set the body for "child".
    /// - Parameter body: The body.
    /// - Returns: The widget.
    public func child(@ViewBuilder _ body: @escaping () -> Body) -> Self {
        var newSelf = self
        newSelf.child = body
        return newSelf
    }
}
