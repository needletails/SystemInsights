import Adwaita

/// Header bar for full-screen security flows (unlock / password setup).
struct SecurityScreenToolbar: View {
    let subtitle: String
    let title: String
    let showsCancel: Bool
    let onCancel: () -> Void

    var view: Body {
        HeaderBar.start { }
            .end {
                if showsCancel {
                    Button("Cancel") {
                        UIViewDeferral.run { onCancel() }
                    }
                    .flat()
                    .style("operations-security-cancel")
                }
            }
            .showStartTitleButtons(true)
            .showEndTitleButtons(false)
            .headerBarTitle {
                WindowTitle(subtitle: subtitle, title: title)
            }
    }
}
