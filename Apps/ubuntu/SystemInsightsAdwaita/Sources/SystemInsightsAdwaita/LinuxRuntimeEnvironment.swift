import Foundation

#if os(Linux)
import Glibc

enum LinuxRuntimeEnvironment {
    static func configureBeforeAppLaunch() {
        guard let flatpakID = ProcessInfo.processInfo.environment["FLATPAK_ID"], !flatpakID.isEmpty else {
            return
        }
        configureRendererFallbackIfNeeded()
    }

    private static func configureRendererFallbackIfNeeded() {
        guard ProcessInfo.processInfo.environment["GSK_RENDERER"] == nil else {
            return
        }
        guard !hasReadableDRIRenderDevice() else {
            return
        }
        _ = setenv("GSK_RENDERER", "cairo", 0)
        DashboardCollectDiagnostics.log("renderer fallback GSK_RENDERER=cairo reason=no-dri-device")
    }

    private static func hasReadableDRIRenderDevice() -> Bool {
        let directory = "/dev/dri"
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: directory) else {
            return false
        }
        return entries.contains { entry in
            entry.hasPrefix("renderD")
                && FileManager.default.isReadableFile(atPath: "\(directory)/\(entry)")
        }
    }
}
#endif
