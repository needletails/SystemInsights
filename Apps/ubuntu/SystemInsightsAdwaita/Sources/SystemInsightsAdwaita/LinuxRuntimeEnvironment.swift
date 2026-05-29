import Foundation

#if os(Linux)
import Glibc

enum LinuxRuntimeEnvironment {
    static func configureBeforeAppLaunch() {
        guard let flatpakID = ProcessInfo.processInfo.environment["FLATPAK_ID"], !flatpakID.isEmpty else {
            return
        }
        configureFlatpakRenderer()
    }

    private static func configureFlatpakRenderer() {
        if isGPUOverrideEnabled() {
            DashboardCollectDiagnostics.log(
                "renderer mode=gpu gsk=\(environmentValue("GSK_RENDERER")) gdkDisable=\(environmentValue("GDK_DISABLE")) dri=\(renderDeviceSummary)"
            )
            return
        }

        let requestedRenderer = ProcessInfo.processInfo.environment["SYSTEM_INSIGHTS_GSK_RENDERER"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let renderer = requestedRenderer?.isEmpty == false ? requestedRenderer! : "cairo"
        _ = setenv("GSK_RENDERER", renderer, 1)
        mergeGDKDisable(["gl", "egl", "vulkan"])
        DashboardCollectDiagnostics.log(
            "renderer mode=software gsk=\(renderer) gdkDisable=\(environmentValue("GDK_DISABLE")) dri=\(renderDeviceSummary)"
        )
    }

    private static func isGPUOverrideEnabled() -> Bool {
        let value = ProcessInfo.processInfo.environment["SYSTEM_INSIGHTS_ALLOW_GPU_RENDERER"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return value == "1" || value == "true" || value == "yes"
    }

    private static func mergeGDKDisable(_ requiredValues: [String]) {
        let existing = ProcessInfo.processInfo.environment["GDK_DISABLE"] ?? ""
        let values = existing
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var merged = values
        for value in requiredValues where !merged.contains(value) {
            merged.append(value)
        }
        _ = setenv("GDK_DISABLE", merged.joined(separator: ","), 1)
    }

    private static var renderDeviceSummary: String {
        let directory = "/dev/dri"
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: directory) else {
            return "none"
        }
        let devices = entries
            .filter { $0.hasPrefix("renderD") }
            .sorted()
            .map { entry in
                let readable = FileManager.default.isReadableFile(atPath: "\(directory)/\(entry)")
                return "\(entry):\(readable ? "readable" : "blocked")"
            }
        return devices.isEmpty ? "none" : devices.joined(separator: ",")
    }

    private static func environmentValue(_ key: String) -> String {
        if let value = getenv(key), let text = String(validatingUTF8: value), !text.isEmpty {
            return text
        }
        return "unset"
    }
}
#else
enum LinuxRuntimeEnvironment {
    static func configureBeforeAppLaunch() {}
}
#endif
