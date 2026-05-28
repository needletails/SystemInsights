//
//  Picture.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// Displays a `GdkPaintable`.
/// 
/// 
/// 
/// Many convenience functions are provided to make pictures simple to use.
/// For example, if you want to load an image from a file, and then display
/// it, there’s a convenience function to do this:
/// 
/// ```c
/// GtkWidget *widget = gtk_picture_new_for_filename ("myfile.png");
/// ```
/// 
/// If the file isn’t loaded successfully, the picture will contain a
/// “broken image” icon similar to that used in many web browsers.
/// If you want to handle errors in loading the file yourself,
/// for example by displaying an error message, then load the image with
/// and image loading framework such as libglycin, then create the `GtkPicture`
/// with `Gtk.Picture.new_for_paintable`.
/// 
/// Sometimes an application will want to avoid depending on external data
/// files, such as image files. See the documentation of `GResource` for details.
/// In this case, `Gtk.Picture.new_for_resource` and
/// `Gtk.Picture.set_resource` should be used.
/// 
/// `GtkPicture` displays an image at its natural size. See `Gtk.Image`
/// if you want to display a fixed-size image, such as an icon.
/// 
/// 
public struct Picture: AdwaitaWidget {

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
    /// The alternative textual description for the picture.
    var alternativeText: String?
    /// If the `GtkPicture` can be made smaller than the natural size of its contents.
    var canShrink: Bool?
    /// How the content should be resized to fit inside the `GtkPicture`.
    var contentFit: ContentFit?

    /// Initialize `Picture`.
    public init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(gtk_picture_new()?.opaque())
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

            if let alternativeText, updateProperties, (storage.previousState as? Self)?.alternativeText != alternativeText {
                gtk_picture_set_alternative_text(widget, alternativeText)
            }
            if let canShrink, updateProperties, (storage.previousState as? Self)?.canShrink != canShrink {
                gtk_picture_set_can_shrink(widget, canShrink.cBool)
            }
            if let contentFit, updateProperties, (storage.previousState as? Self)?.contentFit != contentFit {
                gtk_picture_set_content_fit(widget, contentFit.gtkValue)
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

    /// The alternative textual description for the picture.
    public func alternativeText(_ alternativeText: String?) -> Self {
        modify { $0.alternativeText = alternativeText }
    }

    /// If the `GtkPicture` can be made smaller than the natural size of its contents.
    public func canShrink(_ canShrink: Bool? = true) -> Self {
        modify { $0.canShrink = canShrink }
    }

    /// How the content should be resized to fit inside the `GtkPicture`.
    public func contentFit(_ contentFit: ContentFit?) -> Self {
        modify { $0.contentFit = contentFit }
    }

}
