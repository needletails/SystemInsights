//
//  ListBox.swift
//  Adwaita
//
//  Created by auto-generation on 04.02.26.
//

import CAdw
import LevenshteinTransformations

/// Shows a vertical list.
/// 
/// 
/// 
/// A `GtkListBox` only contains `GtkListBoxRow` children. These rows can
/// by dynamically sorted and filtered, and headers can be added dynamically
/// depending on the row content. It also allows keyboard and mouse navigation
/// and selection like a typical list.
/// 
/// Using `GtkListBox` is often an alternative to `GtkTreeView`, especially
/// when the list contents has a more complicated layout than what is allowed
/// by a `GtkCellRenderer`, or when the contents is interactive (i.e. has a
/// button in it).
/// 
/// Although a `GtkListBox` must have only `GtkListBoxRow` children, you can
/// add any kind of widget to it via `Gtk.ListBox.prepend`,
/// `Gtk.ListBox.append` and `Gtk.ListBox.insert` and a
/// `GtkListBoxRow` widget will automatically be inserted between the list
/// and the widget.
/// 
/// `GtkListBoxRows` can be marked as activatable or selectable. If a row is
/// activatable, `Gtk.ListBox::row-activated` will be emitted for it when
/// the user tries to activate it. If it is selectable, the row will be marked
/// as selected when the user tries to select it.
/// 
/// 
public struct ListBox<Element, Identifier>: AdwaitaWidget where Identifier: Equatable {

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

    /// Whether to accept unpaired release events.
    var acceptUnpairedRelease: Bool?
    /// The accessible role of the given `GtkAccessible` implementation.
    /// 
    /// The accessible role cannot be changed once set.
    var accessibleRole: String?
    /// Determines whether children can be activated with a single
    /// click, or require a double-click.
    var activateOnSingleClick: Bool?
    /// Whether to show separators between rows.
    var showSeparators: Bool?
    /// Emitted when the cursor row is activated.
    var activateCursorRow: (() -> Void)?
    /// Emitted when the user initiates a cursor movement.
    /// 
    /// The default bindings for this signal come in two variants, the variant with
    /// the Shift modifier extends the selection, the variant without the Shift
    /// modifier does not. There are too many key combinations to list them all
    /// here.
    /// 
    /// - <kbd>←</kbd>, <kbd>→</kbd>, <kbd>↑</kbd>, <kbd>↓</kbd>
    /// move by individual children
    /// - <kbd>Home</kbd>, <kbd>End</kbd> move to the ends of the box
    /// - <kbd>PgUp</kbd>, <kbd>PgDn</kbd> move vertically by pages
    var moveCursor: (() -> Void)?
    /// Emitted when a row has been activated by the user.
    var rowActivated: (() -> Void)?
    /// Emitted when a new row is selected, or (with a %NULL @row)
    /// when the selection is cleared.
    /// 
    /// When the @box is using %GTK_SELECTION_MULTIPLE, this signal will not
    /// give you the full picture of selection changes, and you should use
    /// the `Gtk.ListBox::selected-rows-changed` signal instead.
    var rowSelected: (() -> Void)?
    /// Emitted to select all children of the box, if the selection
    /// mode permits it.
    /// 
    /// This is a [keybinding signal](class.SignalAction.html).
    /// 
    /// The default binding for this signal is <kbd>Ctrl</kbd>-<kbd>a</kbd>.
    var selectAll: (() -> Void)?
    /// Emitted when the set of selected rows changes.
    var selectedRowsChanged: (() -> Void)?
    /// Emitted when the cursor row is toggled.
    /// 
    /// The default bindings for this signal is <kbd>Ctrl</kbd>+<kbd>␣</kbd>.
    var toggleCursorRow: (() -> Void)?
    /// Emitted to unselect all children of the box, if the selection
    /// mode permits it.
    /// 
    /// This is a [keybinding signal](class.SignalAction.html).
    /// 
    /// The default binding for this signal is
    /// <kbd>Ctrl</kbd>-<kbd>Shift</kbd>-<kbd>a</kbd>.
    var unselectAll: (() -> Void)?
    /// The dynamic widget elements.
    var elements: [Element]
    /// The dynamic widget content.
    var content: (Element) -> Body
    /// The dynamic widget identifier key path.
    var id: KeyPath<Element, Identifier>

    /// Initialize `ListBox`.
    public init(_ elements: [Element], id: KeyPath<Element, Identifier>, @ViewBuilder content: @escaping (Element) -> Body) {
        self.elements = elements
        self.content = content
        self.id = id
    }

    /// The view storage.
    /// - Parameters:
    ///     - modifiers: Modify views before being updated.
    ///     - type: The view render data type.
    /// - Returns: The view storage.
    public func container<Data>(data: WidgetData, type: Data.Type) -> ViewStorage where Data: ViewRenderData {
        let storage = ViewStorage(gtk_list_box_new()?.opaque())
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
        if let activateCursorRow {
            storage.connectSignal(name: "activate-cursor-row", argCount: 0) {
                activateCursorRow()
            }
        }
        if let moveCursor {
            storage.connectSignal(name: "move-cursor", argCount: 4) {
                moveCursor()
            }
        }
        if let rowActivated {
            storage.connectSignal(name: "row-activated", argCount: 1) {
                rowActivated()
            }
        }
        if let rowSelected {
            storage.connectSignal(name: "row-selected", argCount: 1) {
                rowSelected()
            }
        }
        if let selectAll {
            storage.connectSignal(name: "select-all", argCount: 0) {
                selectAll()
            }
        }
        if let selectedRowsChanged {
            storage.connectSignal(name: "selected-rows-changed", argCount: 0) {
                selectedRowsChanged()
            }
        }
        if let toggleCursorRow {
            storage.connectSignal(name: "toggle-cursor-row", argCount: 0) {
                toggleCursorRow()
            }
        }
        if let unselectAll {
            storage.connectSignal(name: "unselect-all", argCount: 0) {
                unselectAll()
            }
        }
        storage.modify { widget in

            if let activateOnSingleClick, updateProperties, (storage.previousState as? Self)?.activateOnSingleClick != activateOnSingleClick {
                gtk_list_box_set_activate_on_single_click(widget, activateOnSingleClick.cBool)
            }
            if let showSeparators, updateProperties, (storage.previousState as? Self)?.showSeparators != showSeparators {
                gtk_list_box_set_show_separators(widget, showSeparators.cBool)
            }

            var contentStorage: [ViewStorage] = storage.content[.mainContent] ?? []
            let old = storage.fields["element"] as? [Element] ?? []
            old.transform(
                to: elements,
                id: id,
                functions: .init { index in
                    gtk_list_box_remove(widget, gtk_list_box_get_row_at_index(widget, index.cInt)?.cast())
                    contentStorage.remove(at: index)
                } insert: { index, element in
                    let child = content(element).storage(data: data, type: type)
                    gtk_list_box_insert(widget, child.opaquePointer?.cast(), index.cInt)
                    contentStorage.insert(child, at: index)
                }
            )
            storage.fields["element"] = elements
            storage.content[.mainContent] = contentStorage
            for (index, element) in elements.enumerated() {
                content(element).updateStorage(contentStorage[index], data: data, updateProperties: updateProperties, type: type)
            }

        }
        for function in updateFunctions {
            function(storage, data, updateProperties)
        }
        if updateProperties {
            storage.previousState = self
        }
    }

    /// Whether to accept unpaired release events.
    public func acceptUnpairedRelease(_ acceptUnpairedRelease: Bool? = true) -> Self {
        modify { $0.acceptUnpairedRelease = acceptUnpairedRelease }
    }

    /// The accessible role of the given `GtkAccessible` implementation.
    /// 
    /// The accessible role cannot be changed once set.
    public func accessibleRole(_ accessibleRole: String?) -> Self {
        modify { $0.accessibleRole = accessibleRole }
    }

    /// Determines whether children can be activated with a single
    /// click, or require a double-click.
    public func activateOnSingleClick(_ activateOnSingleClick: Bool? = true) -> Self {
        modify { $0.activateOnSingleClick = activateOnSingleClick }
    }

    /// Whether to show separators between rows.
    public func showSeparators(_ showSeparators: Bool? = true) -> Self {
        modify { $0.showSeparators = showSeparators }
    }

    /// Emitted when the cursor row is activated.
    public func activateCursorRow(_ activateCursorRow: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.activateCursorRow = activateCursorRow
        return newSelf
    }

    /// Emitted when the user initiates a cursor movement.
    /// 
    /// The default bindings for this signal come in two variants, the variant with
    /// the Shift modifier extends the selection, the variant without the Shift
    /// modifier does not. There are too many key combinations to list them all
    /// here.
    /// 
    /// - <kbd>←</kbd>, <kbd>→</kbd>, <kbd>↑</kbd>, <kbd>↓</kbd>
    /// move by individual children
    /// - <kbd>Home</kbd>, <kbd>End</kbd> move to the ends of the box
    /// - <kbd>PgUp</kbd>, <kbd>PgDn</kbd> move vertically by pages
    public func moveCursor(_ moveCursor: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.moveCursor = moveCursor
        return newSelf
    }

    /// Emitted when a row has been activated by the user.
    public func rowActivated(_ rowActivated: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.rowActivated = rowActivated
        return newSelf
    }

    /// Emitted when a new row is selected, or (with a %NULL @row)
    /// when the selection is cleared.
    /// 
    /// When the @box is using %GTK_SELECTION_MULTIPLE, this signal will not
    /// give you the full picture of selection changes, and you should use
    /// the `Gtk.ListBox::selected-rows-changed` signal instead.
    public func rowSelected(_ rowSelected: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.rowSelected = rowSelected
        return newSelf
    }

    /// Emitted to select all children of the box, if the selection
    /// mode permits it.
    /// 
    /// This is a [keybinding signal](class.SignalAction.html).
    /// 
    /// The default binding for this signal is <kbd>Ctrl</kbd>-<kbd>a</kbd>.
    public func selectAll(_ selectAll: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.selectAll = selectAll
        return newSelf
    }

    /// Emitted when the set of selected rows changes.
    public func selectedRowsChanged(_ selectedRowsChanged: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.selectedRowsChanged = selectedRowsChanged
        return newSelf
    }

    /// Emitted when the cursor row is toggled.
    /// 
    /// The default bindings for this signal is <kbd>Ctrl</kbd>+<kbd>␣</kbd>.
    public func toggleCursorRow(_ toggleCursorRow: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.toggleCursorRow = toggleCursorRow
        return newSelf
    }

    /// Emitted to unselect all children of the box, if the selection
    /// mode permits it.
    /// 
    /// This is a [keybinding signal](class.SignalAction.html).
    /// 
    /// The default binding for this signal is
    /// <kbd>Ctrl</kbd>-<kbd>Shift</kbd>-<kbd>a</kbd>.
    public func unselectAll(_ unselectAll: @escaping () -> Void) -> Self {
        var newSelf = self
        newSelf.unselectAll = unselectAll
        return newSelf
    }

}

extension ListBox where Element: Identifiable, Identifier == Element.ID {

    /// Initialize `ListBox`.
    public init(_ elements: [Element], @ViewBuilder content: @escaping (Element) -> Body) {
        self.elements = elements
        self.content = content
        self.id = \.id
    }

}
