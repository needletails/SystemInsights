//
//  SearchEntry.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// A single-line text entry widget for use as a search entry.
/// 
/// The main API for interacting with a `GtkSearchEntry` as entry
/// is the `GtkEditable` interface.
/// 
/// 
/// 
/// It will show an inactive symbolic “find” icon when the search
/// entry is empty, and a symbolic “clear” icon when there is text.
/// Clicking on the “clear” icon will empty the search entry.
/// 
/// To make filtering appear more reactive, it is a good idea to
/// not react to every change in the entry text immediately, but
/// only after a short delay. To support this, `GtkSearchEntry`
/// emits the `Gtk.SearchEntry::search-changed` signal which
/// can be used instead of the `Gtk.Editable::changed` signal.
/// 
/// The `Gtk.SearchEntry::previous-match`,
/// `Gtk.SearchEntry::next-match` and
/// `Gtk.SearchEntry::stop-search` signals can be used to
/// implement moving between search results and ending the search.
/// 
/// Often, `GtkSearchEntry` will be fed events by means of being
/// placed inside a `Gtk.SearchBar`. If that is not the case,
/// you can use `Gtk.SearchEntry.set_key_capture_widget` to
/// let it capture key input from another widget.
/// 
/// `GtkSearchEntry` provides only minimal API and should be used with
/// the `Gtk.Editable` API.
/// 
/// 
public struct SearchEntry: AdwaitaWidget {

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
    /// Whether to activate the default widget when Enter is pressed.
    var activatesDefault: Bool?
    /// The current position of the insertion cursor in chars.
    var cursorPosition: Int?
    /// Whether the entry contents can be edited.
    var editable: Bool?
    /// If undo/redo should be enabled for the editable.
    var enableUndo: Bool?
    /// The desired maximum width of the entry, in characters.
    var maxWidthChars: Int?
    /// The text that will be displayed in the `GtkSearchEntry`
    /// when it is empty and unfocused.
    var placeholderText: String?
    /// The delay in milliseconds from last keypress to the search
    /// changed signal.
    var searchDelay: UInt?
    /// The position of the opposite end of the selection from the cursor in chars.
    var selectionBound: Int?
    /// The contents of the entry.
    var text: Binding<String>?
    /// Number of characters to leave space for in the entry.
    var widthChars: Int?
    /// The horizontal alignment, from 0 (left) to 1 (right).
    /// 
    /// Reversed for RTL layouts.
    var xalign: Float?
    /// Emitted when the entry is activated.
    /// 
    /// The keybindings for this signal are all forms of the <kbd>Enter</kbd> key.
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
    /// Emitted when text is inserted into the widget by the user.
    /// 
    /// The default handler for this signal will normally be responsible
    /// for inserting the text, so by connecting to this signal and then
    /// stopping the signal with g_signal_stop_emission(), it is possible
    /// to modify the inserted text, or prevent it from being inserted entirely.
    var insertText: (() -> Void)?
    /// Emitted when the user initiates a move to the next match
    /// for the current search string.
    /// 
    /// This is a [keybinding signal](class.SignalAction.html).
    /// 
    /// Applications should connect to it, to implement moving
    /// between matches.
    /// 
    /// The default bindings for this signal is <kbd>Ctrl</kbd>+<kbd>g</kbd>.
    var nextMatch: (() -> Void)?
    /// Emitted when the user initiates a move to the previous match
    /// for the current search string.
    /// 
    /// This is a [keybinding signal](class.SignalAction.html).
    /// 
    /// Applications should connect to it, to implement moving
    /// between matches.
    /// 
    /// The default bindings for this signal is
    /// <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>g</kbd>.
    var previousMatch: (() -> Void)?
    /// Emitted with a delay. The length of the delay can be
    /// changed with the ``searchDelay(_:)``
    /// property.
    var searchChanged: (() -> Void)?
    /// Emitted when the user initiated a search on the entry.
    var searchStarted: (() -> Void)?
    /// Emitted when the user stops a search via keyboard input.
    /// 
    /// This is a [keybinding signal](class.SignalAction.html).
    /// 
    /// Applications should connect to it, to implement hiding
    /// the search entry in this case.
    /// 
    /// The default bindings for this signal is <kbd>Escape</kbd>.
    var stopSearch: (() -> Void)?

    /// Initialize `SearchEntry`.
    public init() {
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(gtk_search_entry_new()?.opaque())
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
        if let insertText {
            storage.connectSignal(name: "insert-text", argCount: 3) {
                insertText()
            }
        }
        if let nextMatch {
            storage.connectSignal(name: "next-match", argCount: 0) {
                nextMatch()
            }
        }
        if let previousMatch {
            storage.connectSignal(name: "previous-match", argCount: 0) {
                previousMatch()
            }
        }
        if let searchChanged {
            storage.connectSignal(name: "search-changed", argCount: 0) {
                searchChanged()
            }
        }
        if let searchStarted {
            storage.connectSignal(name: "search-started", argCount: 0) {
                searchStarted()
            }
        }
        if let stopSearch {
            storage.connectSignal(name: "stop-search", argCount: 0) {
                stopSearch()
            }
        }
        storage.modify { widget in

        storage.notify(name: "text") {
            let newValue = String(cString: gtk_editable_get_text(storage.opaquePointer))
if let text, newValue != text.wrappedValue {
    text.wrappedValue = newValue
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
            if let maxWidthChars, updateProperties, (storage.previousState as? Self)?.maxWidthChars != maxWidthChars {
                gtk_editable_set_max_width_chars(widget, maxWidthChars.cInt)
            }
            if let placeholderText, updateProperties, (storage.previousState as? Self)?.placeholderText != placeholderText {
                gtk_search_entry_set_placeholder_text(widget, placeholderText)
            }
            if let searchDelay, updateProperties, (storage.previousState as? Self)?.searchDelay != searchDelay {
                gtk_search_entry_set_search_delay(widget, searchDelay.cInt)
            }
            if let text, updateProperties, (String(cString: gtk_editable_get_text(storage.opaquePointer))) != text.wrappedValue {
                gtk_editable_set_text(storage.opaquePointer, text.wrappedValue)
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

    /// Whether to activate the default widget when Enter is pressed.
    public func activatesDefault(_ activatesDefault: Bool? = true) -> Self {
        modify { $0.activatesDefault = activatesDefault }
    }

    /// The current position of the insertion cursor in chars.
    public func cursorPosition(_ cursorPosition: Int?) -> Self {
        modify { $0.cursorPosition = cursorPosition }
    }

    /// Whether the entry contents can be edited.
    public func editable(_ editable: Bool? = true) -> Self {
        modify { $0.editable = editable }
    }

    /// If undo/redo should be enabled for the editable.
    public func enableUndo(_ enableUndo: Bool? = true) -> Self {
        modify { $0.enableUndo = enableUndo }
    }

    /// The desired maximum width of the entry, in characters.
    public func maxWidthChars(_ maxWidthChars: Int?) -> Self {
        modify { $0.maxWidthChars = maxWidthChars }
    }

    /// The text that will be displayed in the `GtkSearchEntry`
    /// when it is empty and unfocused.
    public func placeholderText(_ placeholderText: String?) -> Self {
        modify { $0.placeholderText = placeholderText }
    }

    /// The delay in milliseconds from last keypress to the search
    /// changed signal.
    public func searchDelay(_ searchDelay: UInt?) -> Self {
        modify { $0.searchDelay = searchDelay }
    }

    /// The position of the opposite end of the selection from the cursor in chars.
    public func selectionBound(_ selectionBound: Int?) -> Self {
        modify { $0.selectionBound = selectionBound }
    }

    /// The contents of the entry.
    public func text(_ text: Binding<String>?) -> Self {
        modify { $0.text = text }
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
    /// The keybindings for this signal are all forms of the <kbd>Enter</kbd> key.
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

    /// Emitted when the user initiates a move to the next match
    /// for the current search string.
    /// 
    /// This is a [keybinding signal](class.SignalAction.html).
    /// 
    /// Applications should connect to it, to implement moving
    /// between matches.
    /// 
    /// The default bindings for this signal is <kbd>Ctrl</kbd>+<kbd>g</kbd>.
    public func nextMatch(_ nextMatch: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.nextMatch = nextMatch
        return newSelf
    }

    /// Emitted when the user initiates a move to the previous match
    /// for the current search string.
    /// 
    /// This is a [keybinding signal](class.SignalAction.html).
    /// 
    /// Applications should connect to it, to implement moving
    /// between matches.
    /// 
    /// The default bindings for this signal is
    /// <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>g</kbd>.
    public func previousMatch(_ previousMatch: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.previousMatch = previousMatch
        return newSelf
    }

    /// Emitted with a delay. The length of the delay can be
    /// changed with the ``searchDelay(_:)``
    /// property.
    public func searchChanged(_ searchChanged: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.searchChanged = searchChanged
        return newSelf
    }

    /// Emitted when the user initiated a search on the entry.
    public func searchStarted(_ searchStarted: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.searchStarted = searchStarted
        return newSelf
    }

    /// Emitted when the user stops a search via keyboard input.
    /// 
    /// This is a [keybinding signal](class.SignalAction.html).
    /// 
    /// Applications should connect to it, to implement hiding
    /// the search entry in this case.
    /// 
    /// The default bindings for this signal is <kbd>Escape</kbd>.
    public func stopSearch(_ stopSearch: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.stopSearch = stopSearch
        return newSelf
    }

}
