import Foundation
import Observation
import SwiftUI

#if canImport(Sparkle)
import Sparkle
#endif

@MainActor
@Observable
final class UpdaterController {
    let isConfigured: Bool

    #if canImport(Sparkle)
    private let controller: SPUStandardUpdaterController?
    #endif

    init() {
        let feedURL = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String ?? ""
        let publicKey = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? ""
        isConfigured = feedURL.hasPrefix("https://")
            && !feedURL.contains("example.com")
            && !publicKey.hasPrefix("CONFIGURE_")
            && !publicKey.isEmpty

        #if canImport(Sparkle)
        controller = isConfigured
            ? SPUStandardUpdaterController(
                startingUpdater: true,
                updaterDelegate: nil,
                userDriverDelegate: nil
            )
            : nil
        #endif
    }

    func checkForUpdates() {
        #if canImport(Sparkle)
        controller?.checkForUpdates(nil)
        #endif
    }
}
