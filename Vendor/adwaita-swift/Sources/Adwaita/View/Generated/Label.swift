//
//  Label.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// Displays a small amount of text.
/// 
/// Most labels are used to label another widget (such as an `Entry`).
/// 
/// 
/// 
/// 
public struct Label: AdwaitaWidget {

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
    /// The contents of the label.
    /// 
    /// If the string contains Pango markup (see `Pango.parse_markup`),
    /// you will have to set the ``useMarkup(_:)`` property to
    /// true in order for the label to display the markup attributes. See also
    /// `Gtk.Label.set_markup` for a convenience function that sets both
    /// this property and the ``useMarkup(_:)`` property at the
    /// same time.
    /// 
    /// If the string contains underlines acting as mnemonics, you will have to
    /// set the ``useUnderline(_:)`` property to true in order
    /// for the label to display them.
    var label: String
    /// The number of lines to which an ellipsized, wrapping label
    /// should display before it gets ellipsized. This both prevents the label
    /// from ellipsizing before this many lines are displayed, and limits the
    /// height request of the label to this many lines.
    /// 
    /// > [!WARNING]
    /// >     Setting this property has unintuitive and unfortunate consequences
    /// for the minimum _width_ of the label. Specifically, if the height
    /// of the label is such that it fits a smaller number of lines than
    /// the value of this property, the label can not be ellipsized at all,
    /// which means it must be wide enough to fit all the text fully.
    /// 
    /// This property has no effect if the label is not wrapping or ellipsized.
    /// 
    /// Set this property to -1 if you don't want to limit the number of lines.
    var lines: Int?
    /// The desired maximum width of the label, in characters.
    /// 
    /// If this property is set to -1, the width will be calculated automatically.
    /// 
    /// See the section on [text layout](class.Label.html
    var maxWidthChars: Int?
    /// The mnemonic accelerator key for the label.
    var mnemonicKeyval: UInt?
    /// The widget to be activated when the labels mnemonic key is pressed.
    var mnemonicWidget: Body?
    /// Whether the label text can be selected with the mouse.
    var selectable: Bool?
    /// Whether the label is in single line mode.
    /// 
    /// In single line mode, the height of the label does not depend on the
    /// actual text, it is always set to ascent + descent of the font. This
    /// can be an advantage in situations where resizing the label because
    /// of text changes would be distracting, e.g. in a statusbar.
    var singleLineMode: Bool?
    /// True if the text of the label includes Pango markup.
    /// 
    /// See `Pango.parse_markup`.
    var useMarkup: Bool?
    /// True if the text of the label indicates a mnemonic with an `_`
    /// before the mnemonic character.
    var useUnderline: Bool?
    /// The desired width of the label, in characters.
    /// 
    /// If this property is set to -1, the width will be calculated automatically.
    /// 
    /// See the section on [text layout](class.Label.html
    var widthChars: Int?
    /// True if the label text will wrap if it gets too wide.
    var wrap: Bool?
    /// The horizontal alignment of the label text inside its size allocation.
    /// 
    /// Compare this to ``halign(_:)``, which determines how the
    /// labels size allocation is positioned in the space available for the label.
    var xalign: Float?
    /// The vertical alignment of the label text inside its size allocation.
    /// 
    /// Compare this to ``valign(_:)``, which determines how the
    /// labels size allocation is positioned in the space available for the label.
    var yalign: Float?
    /// Gets emitted to copy the selection to the clipboard.
    /// 
    /// The `::copy-clipboard` signal is a [keybinding signal](class.SignalAction.html).
    /// 
    /// The default binding for this signal is <kbd>Ctrl</kbd>+<kbd>c</kbd>.
    var copyClipboard: (() -> Void)?

    /// Initialize `Label`.
    public init(label: String) {
        self.label = label
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(gtk_label_new(label)?.opaque())
        for function in appearFunctions {
            function(storage, data)
        }
        if let mnemonicWidgetStorage = mnemonicWidget?.storage(data: data, type: type) {
            storage.content["mnemonicWidget"] = [mnemonicWidgetStorage]
            gtk_label_set_mnemonic_widget(storage.opaquePointer, mnemonicWidgetStorage.opaquePointer?.cast())
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
        if let copyClipboard {
            storage.connectSignal(name: "copy-clipboard", argCount: 0) {
                copyClipboard()
            }
        }
        storage.modify { widget in

            if updateProperties, (storage.previousState as? Self)?.label != label {
                gtk_label_set_label(widget, label)
            }
            if let lines, updateProperties, (storage.previousState as? Self)?.lines != lines {
                gtk_label_set_lines(widget, lines.cInt)
            }
            if let maxWidthChars, updateProperties, (storage.previousState as? Self)?.maxWidthChars != maxWidthChars {
                gtk_label_set_max_width_chars(widget, maxWidthChars.cInt)
            }
            if let widget = storage.content["mnemonicWidget"]?.first {
                mnemonicWidget?.updateStorage(widget, data: data, updateProperties: updateProperties, type: type)
            }
            if let selectable, updateProperties, (storage.previousState as? Self)?.selectable != selectable {
                gtk_label_set_selectable(widget, selectable.cBool)
            }
            if let singleLineMode, updateProperties, (storage.previousState as? Self)?.singleLineMode != singleLineMode {
                gtk_label_set_single_line_mode(widget, singleLineMode.cBool)
            }
            if let useMarkup, updateProperties, (storage.previousState as? Self)?.useMarkup != useMarkup {
                gtk_label_set_use_markup(widget, useMarkup.cBool)
            }
            if let useUnderline, updateProperties, (storage.previousState as? Self)?.useUnderline != useUnderline {
                gtk_label_set_use_underline(widget, useUnderline.cBool)
            }
            if let widthChars, updateProperties, (storage.previousState as? Self)?.widthChars != widthChars {
                gtk_label_set_width_chars(widget, widthChars.cInt)
            }
            if let wrap, updateProperties, (storage.previousState as? Self)?.wrap != wrap {
                gtk_label_set_wrap(widget, wrap.cBool)
            }
            if let xalign, updateProperties, (storage.previousState as? Self)?.xalign != xalign {
                gtk_label_set_xalign(widget, xalign)
            }
            if let yalign, updateProperties, (storage.previousState as? Self)?.yalign != yalign {
                gtk_label_set_yalign(widget, yalign)
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

    /// The contents of the label.
    /// 
    /// If the string contains Pango markup (see `Pango.parse_markup`),
    /// you will have to set the ``useMarkup(_:)`` property to
    /// true in order for the label to display the markup attributes. See also
    /// `Gtk.Label.set_markup` for a convenience function that sets both
    /// this property and the ``useMarkup(_:)`` property at the
    /// same time.
    /// 
    /// If the string contains underlines acting as mnemonics, you will have to
    /// set the ``useUnderline(_:)`` property to true in order
    /// for the label to display them.
    public func label(_ label: String) -> Self {
        modify { $0.label = label }
    }

    /// The number of lines to which an ellipsized, wrapping label
    /// should display before it gets ellipsized. This both prevents the label
    /// from ellipsizing before this many lines are displayed, and limits the
    /// height request of the label to this many lines.
    /// 
    /// > [!WARNING]
    /// >     Setting this property has unintuitive and unfortunate consequences
    /// for the minimum _width_ of the label. Specifically, if the height
    /// of the label is such that it fits a smaller number of lines than
    /// the value of this property, the label can not be ellipsized at all,
    /// which means it must be wide enough to fit all the text fully.
    /// 
    /// This property has no effect if the label is not wrapping or ellipsized.
    /// 
    /// Set this property to -1 if you don't want to limit the number of lines.
    public func lines(_ lines: Int?) -> Self {
        modify { $0.lines = lines }
    }

    /// The desired maximum width of the label, in characters.
    /// 
    /// If this property is set to -1, the width will be calculated automatically.
    /// 
    /// See the section on [text layout](class.Label.html
    public func maxWidthChars(_ maxWidthChars: Int?) -> Self {
        modify { $0.maxWidthChars = maxWidthChars }
    }

    /// The mnemonic accelerator key for the label.
    public func mnemonicKeyval(_ mnemonicKeyval: UInt?) -> Self {
        modify { $0.mnemonicKeyval = mnemonicKeyval }
    }

    /// The widget to be activated when the labels mnemonic key is pressed.
    public func mnemonicWidget(@ViewBuilder _ mnemonicWidget: () -> Body) -> Self {
        modify { $0.mnemonicWidget = mnemonicWidget() }
    }

    /// Whether the label text can be selected with the mouse.
    public func selectable(_ selectable: Bool? = true) -> Self {
        modify { $0.selectable = selectable }
    }

    /// Whether the label is in single line mode.
    /// 
    /// In single line mode, the height of the label does not depend on the
    /// actual text, it is always set to ascent + descent of the font. This
    /// can be an advantage in situations where resizing the label because
    /// of text changes would be distracting, e.g. in a statusbar.
    public func singleLineMode(_ singleLineMode: Bool? = true) -> Self {
        modify { $0.singleLineMode = singleLineMode }
    }

    /// True if the text of the label includes Pango markup.
    /// 
    /// See `Pango.parse_markup`.
    public func useMarkup(_ useMarkup: Bool? = true) -> Self {
        modify { $0.useMarkup = useMarkup }
    }

    /// True if the text of the label indicates a mnemonic with an `_`
    /// before the mnemonic character.
    public func useUnderline(_ useUnderline: Bool? = true) -> Self {
        modify { $0.useUnderline = useUnderline }
    }

    /// The desired width of the label, in characters.
    /// 
    /// If this property is set to -1, the width will be calculated automatically.
    /// 
    /// See the section on [text layout](class.Label.html
    public func widthChars(_ widthChars: Int?) -> Self {
        modify { $0.widthChars = widthChars }
    }

    /// True if the label text will wrap if it gets too wide.
    public func wrap(_ wrap: Bool? = true) -> Self {
        modify { $0.wrap = wrap }
    }

    /// The horizontal alignment of the label text inside its size allocation.
    /// 
    /// Compare this to ``halign(_:)``, which determines how the
    /// labels size allocation is positioned in the space available for the label.
    public func xalign(_ xalign: Float?) -> Self {
        modify { $0.xalign = xalign }
    }

    /// The vertical alignment of the label text inside its size allocation.
    /// 
    /// Compare this to ``valign(_:)``, which determines how the
    /// labels size allocation is positioned in the space available for the label.
    public func yalign(_ yalign: Float?) -> Self {
        modify { $0.yalign = yalign }
    }

    /// Gets emitted to copy the selection to the clipboard.
    /// 
    /// The `::copy-clipboard` signal is a [keybinding signal](class.SignalAction.html).
    /// 
    /// The default binding for this signal is <kbd>Ctrl</kbd>+<kbd>c</kbd>.
    public func copyClipboard(_ copyClipboard: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.copyClipboard = copyClipboard
        return newSelf
    }

}
