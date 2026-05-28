//
//  Avatar.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// A widget displaying an image, with a generated fallback.
/// 
/// 
/// 
/// `AdwAvatar` is a widget that shows a round avatar.
/// 
/// `AdwAvatar` generates an avatar with the initials of  the
/// ``text(_:)`` on top of a colored background.
/// 
/// The color is picked based on the hash of the ``text(_:)``.
/// 
/// If ``showInitials(_:)`` is set to `false`,
/// ``iconName(_:)`` or `avatar-default-symbolic` is shown instead of
/// the initials.
/// 
/// Use ``customImage(_:)`` to set a custom image.
/// 
/// 
public struct Avatar: AdwaitaWidget {

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

    /// The name of an icon to use as a fallback.
    /// 
    /// If no name is set, `avatar-default-symbolic` will be used.
    var iconName: String?
    /// Whether initials are used instead of an icon on the fallback avatar.
    /// 
    /// See ``iconName(_:)`` for how to change the fallback icon.
    var showInitials: Bool
    /// The size of the avatar.
    var size: Int
    /// Sets the text used to generate the fallback initials and color.
    /// 
    /// It's only used to generate the color if ``showInitials(_:)`` is
    /// `false`.
    var text: String?

    /// Initialize `Avatar`.
    public init(showInitials: Bool, size: Int) {
        self.showInitials = showInitials
        self.size = size
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(adw_avatar_new(size.cInt, text, showInitials.cBool)?.opaque())
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

            if let iconName, updateProperties, (storage.previousState as? Self)?.iconName != iconName {
                adw_avatar_set_icon_name(widget, iconName)
            }
            if updateProperties, (storage.previousState as? Self)?.showInitials != showInitials {
                adw_avatar_set_show_initials(widget, showInitials.cBool)
            }
            if updateProperties, (storage.previousState as? Self)?.size != size {
                adw_avatar_set_size(widget, size.cInt)
            }
            if let text, updateProperties, (storage.previousState as? Self)?.text != text {
                adw_avatar_set_text(widget, text)
            }



        }
        for function in updateFunctions {
            function(storage, data, updateProperties)
        }
        if updateProperties {
            storage.previousState = self
        }
    }

    /// The name of an icon to use as a fallback.
    /// 
    /// If no name is set, `avatar-default-symbolic` will be used.
    public func iconName(_ iconName: String?) -> Self {
        modify { $0.iconName = iconName }
    }

    /// Whether initials are used instead of an icon on the fallback avatar.
    /// 
    /// See ``iconName(_:)`` for how to change the fallback icon.
    public func showInitials(_ showInitials: Bool) -> Self {
        modify { $0.showInitials = showInitials }
    }

    /// The size of the avatar.
    public func size(_ size: Int) -> Self {
        modify { $0.size = size }
    }

    /// Sets the text used to generate the fallback initials and color.
    /// 
    /// It's only used to generate the color if ``showInitials(_:)`` is
    /// `false`.
    public func text(_ text: String?) -> Self {
        modify { $0.text = text }
    }

}
