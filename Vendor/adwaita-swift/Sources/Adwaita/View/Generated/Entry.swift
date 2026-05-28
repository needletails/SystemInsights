//
//  Entry.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// A single-line text entry widget.
/// 
/// 
/// 
/// A fairly large set of key bindings are supported by default. If the
/// entered text is longer than the allocation of the widget, the widget
/// will scroll so that the cursor position is visible.
/// 
/// When using an entry for passwords and other sensitive information, it
/// can be put into “password mode” using `Gtk.Entry.set_visibility`.
/// In this mode, entered text is displayed using a “invisible” character.
/// By default, GTK picks the best invisible character that is available
/// in the current font, but it can be changed with
/// `Gtk.Entry.set_invisible_char`.
/// 
/// `GtkEntry` has the ability to display progress or activity
/// information behind the text. To make an entry display such information,
/// use `Gtk.Entry.set_progress_fraction` or
/// `Gtk.Entry.set_progress_pulse_step`.
/// 
/// Additionally, `GtkEntry` can show icons at either side of the entry.
/// These icons can be activatable by clicking, can be set up as drag source
/// and can have tooltips. To add an icon, use
/// `Gtk.Entry.set_icon_from_gicon` or one of the various other functions
/// that set an icon from an icon name or a paintable. To trigger an action when
/// the user clicks an icon, connect to the `Gtk.Entry::icon-press` signal.
/// To allow DND operations from an icon, use
/// `Gtk.Entry.set_icon_drag_source`. To set a tooltip on an icon, use
/// `Gtk.Entry.set_icon_tooltip_text` or the corresponding function
/// for markup.
/// 
/// Note that functionality or information that is only available by clicking
/// on an icon in an entry may not be accessible at all to users which are not
/// able to use a mouse or other pointing device. It is therefore recommended
/// that any such functionality should also be available by other means, e.g.
/// via the context menu of the entry.
/// 
/// 
public struct Entry: AdwaitaWidget {

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
    /// The current position of the insertion cursor in chars.
    var cursorPosition: Int?
    /// Whether the entry contents can be edited.
    var editable: Bool?
    /// Indicates whether editing on the cell has been canceled.
    var editingCanceled: Bool?
    /// Whether to suggest Emoji replacements for :-delimited names
    /// like `:heart:`.
    var enableEmojiCompletion: Bool?
    /// If undo/redo should be enabled for the editable.
    var enableUndo: Bool?
    /// A menu model whose contents will be appended to the context menu.
    var extraMenu: Body?
    /// Whether the entry should draw a frame.
    var hasFrame: Bool?
    /// Which IM (input method) module should be used for this entry.
    /// 
    /// See `Gtk.IMContext`.
    /// 
    /// Setting this to a non-%NULL value overrides the system-wide IM
    /// module setting. See the GtkSettings ``gtkImModule(_:)``
    /// property.
    var imModule: String?
    /// The character to use when masking entry contents (“password mode”).
    var invisibleCharacter: UInt?
    /// Whether the invisible char has been set for the `GtkEntry`.
    var invisibleCharacterSet: Bool?
    /// Maximum number of characters for this entry.
    var maxLength: Int?
    /// The desired maximum width of the entry, in characters.
    var maxWidthChars: Int?
    /// Text for an item in the context menu to activate the primary icon action.
    /// 
    /// When the primary icon is activatable and this property has been set, a new entry
    /// in the context menu of this GtkEntry will appear with this text. Selecting that
    /// menu entry will result in the primary icon being activated, exactly in the same way
    /// as it would be activated from a mouse click.
    /// 
    /// This simplifies adding accessibility support to applications using activatable
    /// icons. The activatable icons aren't focusable when navigating the interface with
    /// the keyboard This is why Gtk recommends to also add those actions in the context
    /// menu. This set of methods greatly simplifies this, by adding a menu item that, when
    /// enabled, calls the same callback than clicking on the icon.
    var menuEntryIconPrimaryText: String?
    /// Text for an item in the context menu to activate the secondary icon action.
    /// 
    /// When the primary icon is activatable and this property has been set, a new entry
    /// in the context menu of this GtkEntry will appear with this text. Selecting that
    /// menu entry will result in the primary icon being activated, exactly in the same way
    /// as it would be activated from a mouse click.
    /// 
    /// This simplifies adding accessibility support to applications using activatable
    /// icons. The activatable icons aren't focusable when navigating the interface with
    /// the keyboard This is why Gtk recommends to also add those actions in the context
    /// menu. This set of methods greatly simplifies this, by adding a menu item that, when
    /// enabled, calls the same callback than clicking on the icon.
    var menuEntryIconSecondaryText: String?
    /// If text is overwritten when typing in the `GtkEntry`.
    var overwriteMode: Bool?
    /// The text that will be displayed in the `GtkEntry` when it is empty
    /// and unfocused.
    var placeholderText: String?
    /// Whether the primary icon is activatable.
    /// 
    /// GTK emits the `Gtk.Entry::icon-press` and
    /// `Gtk.Entry::icon-release` signals only on sensitive,
    /// activatable icons.
    /// 
    /// Sensitive, but non-activatable icons can be used for purely
    /// informational purposes.
    var primaryIconActivatable: Bool?
    /// The icon name to use for the primary icon for the entry.
    var primaryIconName: String?
    /// Whether the primary icon is sensitive.
    /// 
    /// An insensitive icon appears grayed out. GTK does not emit the
    /// `Gtk.Entry::icon-press` and `Gtk.Entry::icon-release`
    /// signals and does not allow DND from insensitive icons.
    /// 
    /// An icon should be set insensitive if the action that would trigger
    /// when clicked is currently not available.
    var primaryIconSensitive: Bool?
    /// The contents of the tooltip on the primary icon, with markup.
    /// 
    /// Also see `Gtk.Entry.set_icon_tooltip_markup`.
    var primaryIconTooltipMarkup: String?
    /// The contents of the tooltip on the primary icon.
    /// 
    /// Also see `Gtk.Entry.set_icon_tooltip_text`.
    var primaryIconTooltipText: String?
    /// The current fraction of the task that's been completed.
    var progressFraction: Double?
    /// The fraction of total entry width to move the progress
    /// bouncing block for each pulse.
    /// 
    /// See `Gtk.Entry.progress_pulse`.
    var progressPulseStep: Double?
    /// Number of pixels of the entry scrolled off the screen to the left.
    var scrollOffset: Int?
    /// Whether the secondary icon is activatable.
    /// 
    /// GTK emits the `Gtk.Entry::icon-press` and
    /// `Gtk.Entry::icon-release` signals only on sensitive,
    /// activatable icons.
    /// 
    /// Sensitive, but non-activatable icons can be used for purely
    /// informational purposes.
    var secondaryIconActivatable: Bool?
    /// The icon name to use for the secondary icon for the entry.
    var secondaryIconName: String?
    /// Whether the secondary icon is sensitive.
    /// 
    /// An insensitive icon appears grayed out. GTK does not emit the
    /// `Gtk.Entry::icon-press[ and [signal@Gtk.Entry::icon-release`
    /// signals and does not allow DND from insensitive icons.
    /// 
    /// An icon should be set insensitive if the action that would trigger
    /// when clicked is currently not available.
    var secondaryIconSensitive: Bool?
    /// The contents of the tooltip on the secondary icon, with markup.
    /// 
    /// Also see `Gtk.Entry.set_icon_tooltip_markup`.
    var secondaryIconTooltipMarkup: String?
    /// The contents of the tooltip on the secondary icon.
    /// 
    /// Also see `Gtk.Entry.set_icon_tooltip_text`.
    var secondaryIconTooltipText: String?
    /// The position of the opposite end of the selection from the cursor in chars.
    var selectionBound: Int?
    /// Whether the entry will show an Emoji icon in the secondary icon position
    /// to open the Emoji chooser.
    var showEmojiIcon: Bool?
    /// The contents of the entry.
    var text: Binding<String>?
    /// The length of the text in the `GtkEntry`.
    var textLength: UInt?
    /// When `true`, pasted multi-line text is truncated to the first line.
    var truncateMultiline: Bool?
    /// Whether the entry should show the “invisible char” instead of the
    /// actual text (“password mode”).
    var visibility: Bool?
    /// Number of characters to leave space for in the entry.
    var widthChars: Int?
    /// The horizontal alignment, from 0 (left) to 1 (right).
    /// 
    /// Reversed for RTL layouts.
    var xalign: Float?
    /// Emitted when the entry is activated.
    /// 
    /// The keybindings for this signal are all forms of the Enter key.
    var activate: (() -> Void)?
    /// Emitted at the end of a single user-visible operation on the
    /// contents.
    /// 
    /// E.g., a paste operation that replaces the contents of the
    /// selection will cause only one signal emission (even though it
    /// is implemented by first deleting the selection, then inserting
    /// the new content, and may cause multiple ::notify::text signals
    /// to be emitted).
    var changed: (() -> Void)?
    /// Emitted when text is deleted from the widget by the user.
    /// 
    /// The default handler for this signal will normally be responsible for
    /// deleting the text, so by connecting to this signal and then stopping
    /// the signal with g_signal_stop_emission(), it is possible to modify the
    /// range of deleted text, or prevent it from being deleted entirely.
    /// 
    /// The @start_pos and @end_pos parameters are interpreted as for
    /// `Gtk.Editable.delete_text`.
    var deleteText: (() -> Void)?
    /// This signal is a sign for the cell renderer to update its
    /// value from the @cell_editable.
    /// 
    /// Implementations of `GtkCellEditable` are responsible for
    /// emitting this signal when they are done editing, e.g.
    /// `GtkEntry` emits this signal when the user presses Enter. Typical things to
    /// do in a handler for ::editing-done are to capture the edited value,
    /// disconnect the @cell_editable from signals on the `GtkCellRenderer`, etc.
    /// 
    /// gtk_cell_editable_editing_done() is a convenience method
    /// for emitting `GtkCellEditable::editing-done`.
    var editingDone: (() -> Void)?
    /// Emitted when an activatable icon is clicked.
    var iconPress: (() -> Void)?
    /// Emitted on the button release from a mouse click
    /// over an activatable icon.
    var iconRelease: (() -> Void)?
    /// Emitted when text is inserted into the widget by the user.
    /// 
    /// The default handler for this signal will normally be responsible
    /// for inserting the text, so by connecting to this signal and then
    /// stopping the signal with g_signal_stop_emission(), it is possible
    /// to modify the inserted text, or prevent it from being inserted entirely.
    var insertText: (() -> Void)?
    /// This signal is meant to indicate that the cell is finished
    /// editing, and the @cell_editable widget is being removed and may
    /// subsequently be destroyed.
    /// 
    /// Implementations of `GtkCellEditable` are responsible for
    /// emitting this signal when they are done editing. It must
    /// be emitted after the `GtkCellEditable::editing-done` signal,
    /// to give the cell renderer a chance to update the cell's value
    /// before the widget is removed.
    /// 
    /// gtk_cell_editable_remove_widget() is a convenience method
    /// for emitting `GtkCellEditable::remove-widget`.
    var removeWidget: (() -> Void)?

    /// Initialize `Entry`.
    init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(gtk_entry_new()?.opaque())
        for function in appearFunctions {
            function(storage, data)
        }
        if let extraMenu {
            let childStorage = MenuCollection { extraMenu }.getMenu(data: data)
            storage.content["extraMenu"] = [childStorage]
            gtk_entry_set_extra_menu(storage.opaquePointer?.cast(), childStorage.opaquePointer?.cast())
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
        if let activate {
            storage.connectSignal(name: "activate", argCount: 0) {
                activate()
            }
        }
        if let changed {
            storage.connectSignal(name: "changed", argCount: 0) {
                changed()
            }
        }
        if let deleteText {
            storage.connectSignal(name: "delete-text", argCount: 2) {
                deleteText()
            }
        }
        if let editingDone {
            storage.connectSignal(name: "editing-done", argCount: 0) {
                editingDone()
            }
        }
        if let iconPress {
            storage.connectSignal(name: "icon-press", argCount: 1) {
                iconPress()
            }
        }
        if let iconRelease {
            storage.connectSignal(name: "icon-release", argCount: 1) {
                iconRelease()
            }
        }
        if let insertText {
            storage.connectSignal(name: "insert-text", argCount: 3) {
                insertText()
            }
        }
        if let removeWidget {
            storage.connectSignal(name: "remove-widget", argCount: 0) {
                removeWidget()
            }
        }
        storage.modify { widget in

        storage.notify(name: "text", id: "swift-text") {
            let newValue = String(cString: gtk_editable_get_text(storage.opaquePointer))
            if let text {
                EditableTextBinding.adopt(into: text, gtkValue: newValue)
            }
        }
            if let cursorPosition, updateProperties, (storage.previousState as? Self)?.cursorPosition != cursorPosition {
                gtk_editable_set_position(widget, cursorPosition.cInt)
            }
            if let editable, updateProperties, (storage.previousState as? Self)?.editable != editable {
                gtk_editable_set_editable(widget, editable.cBool)
            }
            if let enableUndo, updateProperties, (storage.previousState as? Self)?.enableUndo != enableUndo {
                gtk_editable_set_enable_undo(widget, enableUndo.cBool)
            }
            if let menu = storage.content["extraMenu"]?.first {
                MenuCollection { extraMenu ?? [] }
                    .updateStorage(menu, data: data.noModifiers, updateProperties: updateProperties, type: MenuContext.self)
            }
            if let hasFrame, updateProperties, (storage.previousState as? Self)?.hasFrame != hasFrame {
                gtk_entry_set_has_frame(widget?.cast(), hasFrame.cBool)
            }
            if let invisibleCharacter, updateProperties, (storage.previousState as? Self)?.invisibleCharacter != invisibleCharacter {
                gtk_entry_set_invisible_char(widget?.cast(), invisibleCharacter.cInt)
            }
            if let maxLength, updateProperties, (storage.previousState as? Self)?.maxLength != maxLength {
                gtk_entry_set_max_length(widget?.cast(), maxLength.cInt)
            }
            if let maxWidthChars, updateProperties, (storage.previousState as? Self)?.maxWidthChars != maxWidthChars {
                gtk_editable_set_max_width_chars(widget, maxWidthChars.cInt)
            }
            if let overwriteMode, updateProperties, (storage.previousState as? Self)?.overwriteMode != overwriteMode {
                gtk_entry_set_overwrite_mode(widget?.cast(), overwriteMode.cBool)
            }
            if let placeholderText, updateProperties, (storage.previousState as? Self)?.placeholderText != placeholderText {
                gtk_entry_set_placeholder_text(widget?.cast(), placeholderText)
            }
            if let progressFraction, updateProperties, (storage.previousState as? Self)?.progressFraction != progressFraction {
                gtk_entry_set_progress_fraction(widget?.cast(), progressFraction)
            }
            if let progressPulseStep, updateProperties, (storage.previousState as? Self)?.progressPulseStep != progressPulseStep {
                gtk_entry_set_progress_pulse_step(widget?.cast(), progressPulseStep)
            }
            if let text, updateProperties {
                EditableTextBinding.pushToGTKIfNeeded(storage: storage, text: text)
            }
            if let visibility, updateProperties, (storage.previousState as? Self)?.visibility != visibility {
                gtk_entry_set_visibility(widget?.cast(), visibility.cBool)
            }
            if let widthChars, updateProperties, (storage.previousState as? Self)?.widthChars != widthChars {
                gtk_editable_set_width_chars(widget, widthChars.cInt)
            }
            if let xalign, updateProperties, (storage.previousState as? Self)?.xalign != xalign {
                gtk_editable_set_alignment(widget, xalign)
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

    /// The current position of the insertion cursor in chars.
    public func cursorPosition(_ cursorPosition: Int?) -> Self {
        modify { $0.cursorPosition = cursorPosition }
    }

    /// Whether the entry contents can be edited.
    public func editable(_ editable: Bool? = true) -> Self {
        modify { $0.editable = editable }
    }

    /// Indicates whether editing on the cell has been canceled.
    public func editingCanceled(_ editingCanceled: Bool? = true) -> Self {
        modify { $0.editingCanceled = editingCanceled }
    }

    /// Whether to suggest Emoji replacements for :-delimited names
    /// like `:heart:`.
    public func enableEmojiCompletion(_ enableEmojiCompletion: Bool? = true) -> Self {
        modify { $0.enableEmojiCompletion = enableEmojiCompletion }
    }

    /// If undo/redo should be enabled for the editable.
    public func enableUndo(_ enableUndo: Bool? = true) -> Self {
        modify { $0.enableUndo = enableUndo }
    }

    /// A menu model whose contents will be appended to the context menu.
    public func extraMenu(@ViewBuilder _ extraMenu: () -> Body) -> Self {
        modify { $0.extraMenu = extraMenu() }
    }

    /// Whether the entry should draw a frame.
    public func hasFrame(_ hasFrame: Bool? = true) -> Self {
        modify { $0.hasFrame = hasFrame }
    }

    /// Which IM (input method) module should be used for this entry.
    /// 
    /// See `Gtk.IMContext`.
    /// 
    /// Setting this to a non-%NULL value overrides the system-wide IM
    /// module setting. See the GtkSettings ``gtkImModule(_:)``
    /// property.
    public func imModule(_ imModule: String?) -> Self {
        modify { $0.imModule = imModule }
    }

    /// The character to use when masking entry contents (“password mode”).
    public func invisibleCharacter(_ invisibleCharacter: UInt?) -> Self {
        modify { $0.invisibleCharacter = invisibleCharacter }
    }

    /// Whether the invisible char has been set for the `GtkEntry`.
    public func invisibleCharacterSet(_ invisibleCharacterSet: Bool? = true) -> Self {
        modify { $0.invisibleCharacterSet = invisibleCharacterSet }
    }

    /// Maximum number of characters for this entry.
    public func maxLength(_ maxLength: Int?) -> Self {
        modify { $0.maxLength = maxLength }
    }

    /// The desired maximum width of the entry, in characters.
    public func maxWidthChars(_ maxWidthChars: Int?) -> Self {
        modify { $0.maxWidthChars = maxWidthChars }
    }

    /// Text for an item in the context menu to activate the primary icon action.
    /// 
    /// When the primary icon is activatable and this property has been set, a new entry
    /// in the context menu of this GtkEntry will appear with this text. Selecting that
    /// menu entry will result in the primary icon being activated, exactly in the same way
    /// as it would be activated from a mouse click.
    /// 
    /// This simplifies adding accessibility support to applications using activatable
    /// icons. The activatable icons aren't focusable when navigating the interface with
    /// the keyboard This is why Gtk recommends to also add those actions in the context
    /// menu. This set of methods greatly simplifies this, by adding a menu item that, when
    /// enabled, calls the same callback than clicking on the icon.
    public func menuEntryIconPrimaryText(_ menuEntryIconPrimaryText: String?) -> Self {
        modify { $0.menuEntryIconPrimaryText = menuEntryIconPrimaryText }
    }

    /// Text for an item in the context menu to activate the secondary icon action.
    /// 
    /// When the primary icon is activatable and this property has been set, a new entry
    /// in the context menu of this GtkEntry will appear with this text. Selecting that
    /// menu entry will result in the primary icon being activated, exactly in the same way
    /// as it would be activated from a mouse click.
    /// 
    /// This simplifies adding accessibility support to applications using activatable
    /// icons. The activatable icons aren't focusable when navigating the interface with
    /// the keyboard This is why Gtk recommends to also add those actions in the context
    /// menu. This set of methods greatly simplifies this, by adding a menu item that, when
    /// enabled, calls the same callback than clicking on the icon.
    public func menuEntryIconSecondaryText(_ menuEntryIconSecondaryText: String?) -> Self {
        modify { $0.menuEntryIconSecondaryText = menuEntryIconSecondaryText }
    }

    /// If text is overwritten when typing in the `GtkEntry`.
    public func overwriteMode(_ overwriteMode: Bool? = true) -> Self {
        modify { $0.overwriteMode = overwriteMode }
    }

    /// The text that will be displayed in the `GtkEntry` when it is empty
    /// and unfocused.
    public func placeholderText(_ placeholderText: String?) -> Self {
        modify { $0.placeholderText = placeholderText }
    }

    /// Whether the primary icon is activatable.
    /// 
    /// GTK emits the `Gtk.Entry::icon-press` and
    /// `Gtk.Entry::icon-release` signals only on sensitive,
    /// activatable icons.
    /// 
    /// Sensitive, but non-activatable icons can be used for purely
    /// informational purposes.
    public func primaryIconActivatable(_ primaryIconActivatable: Bool? = true) -> Self {
        modify { $0.primaryIconActivatable = primaryIconActivatable }
    }

    /// The icon name to use for the primary icon for the entry.
    public func primaryIconName(_ primaryIconName: String?) -> Self {
        modify { $0.primaryIconName = primaryIconName }
    }

    /// Whether the primary icon is sensitive.
    /// 
    /// An insensitive icon appears grayed out. GTK does not emit the
    /// `Gtk.Entry::icon-press` and `Gtk.Entry::icon-release`
    /// signals and does not allow DND from insensitive icons.
    /// 
    /// An icon should be set insensitive if the action that would trigger
    /// when clicked is currently not available.
    public func primaryIconSensitive(_ primaryIconSensitive: Bool? = true) -> Self {
        modify { $0.primaryIconSensitive = primaryIconSensitive }
    }

    /// The contents of the tooltip on the primary icon, with markup.
    /// 
    /// Also see `Gtk.Entry.set_icon_tooltip_markup`.
    public func primaryIconTooltipMarkup(_ primaryIconTooltipMarkup: String?) -> Self {
        modify { $0.primaryIconTooltipMarkup = primaryIconTooltipMarkup }
    }

    /// The contents of the tooltip on the primary icon.
    /// 
    /// Also see `Gtk.Entry.set_icon_tooltip_text`.
    public func primaryIconTooltipText(_ primaryIconTooltipText: String?) -> Self {
        modify { $0.primaryIconTooltipText = primaryIconTooltipText }
    }

    /// The current fraction of the task that's been completed.
    public func progressFraction(_ progressFraction: Double?) -> Self {
        modify { $0.progressFraction = progressFraction }
    }

    /// The fraction of total entry width to move the progress
    /// bouncing block for each pulse.
    /// 
    /// See `Gtk.Entry.progress_pulse`.
    public func progressPulseStep(_ progressPulseStep: Double?) -> Self {
        modify { $0.progressPulseStep = progressPulseStep }
    }

    /// Number of pixels of the entry scrolled off the screen to the left.
    public func scrollOffset(_ scrollOffset: Int?) -> Self {
        modify { $0.scrollOffset = scrollOffset }
    }

    /// Whether the secondary icon is activatable.
    /// 
    /// GTK emits the `Gtk.Entry::icon-press` and
    /// `Gtk.Entry::icon-release` signals only on sensitive,
    /// activatable icons.
    /// 
    /// Sensitive, but non-activatable icons can be used for purely
    /// informational purposes.
    public func secondaryIconActivatable(_ secondaryIconActivatable: Bool? = true) -> Self {
        modify { $0.secondaryIconActivatable = secondaryIconActivatable }
    }

    /// The icon name to use for the secondary icon for the entry.
    public func secondaryIconName(_ secondaryIconName: String?) -> Self {
        modify { $0.secondaryIconName = secondaryIconName }
    }

    /// Whether the secondary icon is sensitive.
    /// 
    /// An insensitive icon appears grayed out. GTK does not emit the
    /// `Gtk.Entry::icon-press[ and [signal@Gtk.Entry::icon-release`
    /// signals and does not allow DND from insensitive icons.
    /// 
    /// An icon should be set insensitive if the action that would trigger
    /// when clicked is currently not available.
    public func secondaryIconSensitive(_ secondaryIconSensitive: Bool? = true) -> Self {
        modify { $0.secondaryIconSensitive = secondaryIconSensitive }
    }

    /// The contents of the tooltip on the secondary icon, with markup.
    /// 
    /// Also see `Gtk.Entry.set_icon_tooltip_markup`.
    public func secondaryIconTooltipMarkup(_ secondaryIconTooltipMarkup: String?) -> Self {
        modify { $0.secondaryIconTooltipMarkup = secondaryIconTooltipMarkup }
    }

    /// The contents of the tooltip on the secondary icon.
    /// 
    /// Also see `Gtk.Entry.set_icon_tooltip_text`.
    public func secondaryIconTooltipText(_ secondaryIconTooltipText: String?) -> Self {
        modify { $0.secondaryIconTooltipText = secondaryIconTooltipText }
    }

    /// The position of the opposite end of the selection from the cursor in chars.
    public func selectionBound(_ selectionBound: Int?) -> Self {
        modify { $0.selectionBound = selectionBound }
    }

    /// Whether the entry will show an Emoji icon in the secondary icon position
    /// to open the Emoji chooser.
    public func showEmojiIcon(_ showEmojiIcon: Bool? = true) -> Self {
        modify { $0.showEmojiIcon = showEmojiIcon }
    }

    /// The contents of the entry.
    public func text(_ text: Binding<String>?) -> Self {
        modify { $0.text = text }
    }

    /// The length of the text in the `GtkEntry`.
    public func textLength(_ textLength: UInt?) -> Self {
        modify { $0.textLength = textLength }
    }

    /// When `true`, pasted multi-line text is truncated to the first line.
    public func truncateMultiline(_ truncateMultiline: Bool? = true) -> Self {
        modify { $0.truncateMultiline = truncateMultiline }
    }

    /// Whether the entry should show the “invisible char” instead of the
    /// actual text (“password mode”).
    public func visibility(_ visibility: Bool? = true) -> Self {
        modify { $0.visibility = visibility }
    }

    /// Number of characters to leave space for in the entry.
    public func widthChars(_ widthChars: Int?) -> Self {
        modify { $0.widthChars = widthChars }
    }

    /// The horizontal alignment, from 0 (left) to 1 (right).
    /// 
    /// Reversed for RTL layouts.
    public func xalign(_ xalign: Float?) -> Self {
        modify { $0.xalign = xalign }
    }

    /// Emitted when the entry is activated.
    /// 
    /// The keybindings for this signal are all forms of the Enter key.
    public func activate(_ activate: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.activate = activate
        return newSelf
    }

    /// Emitted at the end of a single user-visible operation on the
    /// contents.
    /// 
    /// E.g., a paste operation that replaces the contents of the
    /// selection will cause only one signal emission (even though it
    /// is implemented by first deleting the selection, then inserting
    /// the new content, and may cause multiple ::notify::text signals
    /// to be emitted).
    public func changed(_ changed: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.changed = changed
        return newSelf
    }

    /// Emitted when text is deleted from the widget by the user.
    /// 
    /// The default handler for this signal will normally be responsible for
    /// deleting the text, so by connecting to this signal and then stopping
    /// the signal with g_signal_stop_emission(), it is possible to modify the
    /// range of deleted text, or prevent it from being deleted entirely.
    /// 
    /// The @start_pos and @end_pos parameters are interpreted as for
    /// `Gtk.Editable.delete_text`.
    public func deleteText(_ deleteText: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.deleteText = deleteText
        return newSelf
    }

    /// This signal is a sign for the cell renderer to update its
    /// value from the @cell_editable.
    /// 
    /// Implementations of `GtkCellEditable` are responsible for
    /// emitting this signal when they are done editing, e.g.
    /// `GtkEntry` emits this signal when the user presses Enter. Typical things to
    /// do in a handler for ::editing-done are to capture the edited value,
    /// disconnect the @cell_editable from signals on the `GtkCellRenderer`, etc.
    /// 
    /// gtk_cell_editable_editing_done() is a convenience method
    /// for emitting `GtkCellEditable::editing-done`.
    public func editingDone(_ editingDone: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.editingDone = editingDone
        return newSelf
    }

    /// Emitted when an activatable icon is clicked.
    public func iconPress(_ iconPress: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.iconPress = iconPress
        return newSelf
    }

    /// Emitted on the button release from a mouse click
    /// over an activatable icon.
    public func iconRelease(_ iconRelease: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.iconRelease = iconRelease
        return newSelf
    }

    /// Emitted when text is inserted into the widget by the user.
    /// 
    /// The default handler for this signal will normally be responsible
    /// for inserting the text, so by connecting to this signal and then
    /// stopping the signal with g_signal_stop_emission(), it is possible
    /// to modify the inserted text, or prevent it from being inserted entirely.
    public func insertText(_ insertText: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.insertText = insertText
        return newSelf
    }

    /// This signal is meant to indicate that the cell is finished
    /// editing, and the @cell_editable widget is being removed and may
    /// subsequently be destroyed.
    /// 
    /// Implementations of `GtkCellEditable` are responsible for
    /// emitting this signal when they are done editing. It must
    /// be emitted after the `GtkCellEditable::editing-done` signal,
    /// to give the cell renderer a chance to update the cell's value
    /// before the widget is removed.
    /// 
    /// gtk_cell_editable_remove_widget() is a convenience method
    /// for emitting `GtkCellEditable::remove-widget`.
    public func removeWidget(_ removeWidget: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.removeWidget = removeWidget
        return newSelf
    }

}
