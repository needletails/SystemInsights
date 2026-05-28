//
//  Image.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// Displays an image.
/// 
/// 
/// 
/// Various kinds of object can be displayed as an image; most typically,
/// you would load a `GdkTexture` from a file, using the convenience function
/// `Gtk.Image.new_from_file`, for instance:
/// 
/// ```c
/// GtkWidget *image = gtk_image_new_from_file ("myfile.png");
/// ```
/// 
/// If the file isn’t loaded successfully, the image will contain a
/// “broken image” icon similar to that used in many web browsers.
/// 
/// If you want to handle errors in loading the file yourself, for example
/// by displaying an error message, then load the image with an image
/// loading framework such as libglycin, then create the `GtkImage` with
/// `Gtk.Image.new_from_paintable`.
/// 
/// Sometimes an application will want to avoid depending on external data
/// files, such as image files. See the documentation of `GResource` inside
/// GIO, for details. In this case, ``resource(_:)``,
/// `Gtk.Image.new_from_resource`, and `Gtk.Image.set_from_resource`
/// should be used.
/// 
/// `GtkImage` displays its image as an icon, with a size that is determined
/// by the application. See `Gtk.Picture` if you want to show an image
/// at is actual size.
/// 
/// 
public struct Image: AdwaitaWidget {

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
    /// The name of the icon in the icon theme.
    /// 
    /// If the icon theme is changed, the image will be updated automatically.
    var iconName: String?
    /// The size in pixels to display icons at.
    /// 
    /// If set to a value != -1, this property overrides the
    /// ``iconSize(_:)`` property for images of type
    /// `GTK_IMAGE_ICON_NAME`.
    var pixelSize: Int?
    /// A path to a resource file to display.
    var resource: String?
    /// The representation being used for image data.
    var storageType: String?
    /// Whether the icon displayed in the `GtkImage` will use
    /// standard icon names fallback.
    /// 
    /// The value of this property is only relevant for images of type
    /// %GTK_IMAGE_ICON_NAME and %GTK_IMAGE_GICON.
    var useFallback: Bool?

    /// Initialize `Image`.
    public init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(gtk_image_new()?.opaque())
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
                gtk_image_set_from_icon_name(widget, iconName)
            }
            if let pixelSize, updateProperties, (storage.previousState as? Self)?.pixelSize != pixelSize {
                gtk_image_set_pixel_size(widget, pixelSize.cInt)
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

    /// The name of the icon in the icon theme.
    /// 
    /// If the icon theme is changed, the image will be updated automatically.
    public func iconName(_ iconName: String?) -> Self {
        modify { $0.iconName = iconName }
    }

    /// The size in pixels to display icons at.
    /// 
    /// If set to a value != -1, this property overrides the
    /// ``iconSize(_:)`` property for images of type
    /// `GTK_IMAGE_ICON_NAME`.
    public func pixelSize(_ pixelSize: Int?) -> Self {
        modify { $0.pixelSize = pixelSize }
    }

    /// A path to a resource file to display.
    public func resource(_ resource: String?) -> Self {
        modify { $0.resource = resource }
    }

    /// The representation being used for image data.
    public func storageType(_ storageType: String?) -> Self {
        modify { $0.storageType = storageType }
    }

    /// Whether the icon displayed in the `GtkImage` will use
    /// standard icon names fallback.
    /// 
    /// The value of this property is only relevant for images of type
    /// %GTK_IMAGE_ICON_NAME and %GTK_IMAGE_GICON.
    public func useFallback(_ useFallback: Bool? = true) -> Self {
        modify { $0.useFallback = useFallback }
    }

}
