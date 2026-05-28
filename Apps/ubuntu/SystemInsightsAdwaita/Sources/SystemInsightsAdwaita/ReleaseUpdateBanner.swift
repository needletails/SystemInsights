import Adwaita
import Foundation
import SystemInsightCore

#if os(macOS)
import AppKit
#endif

@MainActor
enum ReleaseUpdateCoordinator {
    static func checkForUpdate() async -> ReleaseUpdatePresentation? {
        guard let feedURL = AppUpdateSettings.feedURL,
              let result = await ReleaseUpdateChecker.availableUpdate(
                  feedURL: feedURL,
                  installedVersion: AppUpdateSettings.installedVersion,
                  platform: .current
              ) else {
            return nil
        }
        return ReleaseUpdatePresentation(
            version: result.feed.version,
            downloadURL: result.downloadURL,
            releaseNotes: result.feed.releaseNotes
        )
    }
}

struct ReleaseUpdatePresentation: Equatable, Sendable {
    let version: String
    let downloadURL: URL
    let releaseNotes: String?
}

struct ReleaseUpdateBanner: View {
    let presentation: ReleaseUpdatePresentation
    let onDismiss: () -> Void

    var view: Body {
        VStack {
            Text(bannerMessage)
                .halign(.start)
                .style("operations-update-banner-message")
            HStack(spacing: 12) {
                Button("Download") {
                    UIViewDeferral.run { openDownloadPage() }
                }
                .pill()
                .suggested()
                Button("Dismiss") {
                    UIViewDeferral.run { onDismiss() }
                }
                .pill()
                .flat()
            }
            .halign(.start)
        }
        .padding()
        .style("operations-update-banner")
    }

    private var bannerMessage: String {
        if let releaseNotes = presentation.releaseNotes, !releaseNotes.isEmpty {
            return "Update available: System Insights \(presentation.version). \(releaseNotes)"
        }
        return "Update available: System Insights \(presentation.version). Download the new build from the website."
    }

    private func openDownloadPage() {
        #if os(macOS)
        NSWorkspace.shared.open(presentation.downloadURL)
        #else
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xdg-open")
        process.arguments = [presentation.downloadURL.absoluteString]
        try? process.run()
        #endif
    }
}
