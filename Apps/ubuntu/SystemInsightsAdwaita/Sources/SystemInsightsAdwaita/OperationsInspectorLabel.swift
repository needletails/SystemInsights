import Adwaita
import CAdw

extension AnyView {
    /// Multi-line inspector values (endpoints, evidence, process paths) instead of single-line ellipsize.
    func inspectorLabelWrap(selectable: Bool = true) -> AnyView {
        inspect { storage, updateProperties in
            guard updateProperties, let label = storage.opaquePointer else { return }
            gtk_label_set_wrap(label, 1)
            gtk_label_set_ellipsize(label, PANGO_ELLIPSIZE_NONE)
            gtk_label_set_xalign(label, 0)
            if selectable {
                gtk_label_set_selectable(label, 1)
            }
        }
    }
}
