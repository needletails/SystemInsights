import Foundation

#if os(Linux)
enum LinuxSandboxAdaptation {
    /// True when running inside a Flatpak sandbox (`FLATPAK_ID` is set).
    static var isFlatpak: Bool {
        guard let id = ProcessInfo.processInfo.environment["FLATPAK_ID"], !id.isEmpty else {
            return false
        }
        return true
    }

    /// Host `/proc` when `host-os` exposes it at `/run/host/proc`, otherwise sandbox `/proc`.
    static var procDirectory: String {
        if FileManager.default.fileExists(atPath: "/run/host/proc/stat") {
            return "/run/host/proc"
        }
        return "/proc"
    }

    /// Prefer host root disk usage when available inside Flatpak.
    static var diskUsagePath: String {
        if FileManager.default.fileExists(atPath: "/run/host") {
            return "/run/host"
        }
        return NSHomeDirectory()
    }

    static var sysClassNetDirectory: String {
        if FileManager.default.fileExists(atPath: "/run/host/sys/class/net") {
            return "/run/host/sys/class/net"
        }
        return "/sys/class/net"
    }

    /// Resolve an executable path, preferring the host copy under `/run/host` when present.
    static func resolveExecutable(_ executable: String) -> String {
        if executable.hasPrefix("/run/host/") {
            return executable
        }
        let hostCandidate = "/run/host\(executable)"
        if FileManager.default.isExecutableFile(atPath: hostCandidate) {
            return hostCandidate
        }
        return executable
    }

    /// When sandboxed, run the command on the host via `flatpak-spawn --host`.
    static func commandInvocation(
        executable: String,
        arguments: [String]
    ) -> (executable: String, arguments: [String]) {
        let resolved = resolveExecutable(executable)
        guard isFlatpak else {
            return (resolved, arguments)
        }

        let spawnCandidates = [
            "/usr/bin/flatpak-spawn",
            "/usr/libexec/flatpak-spawn"
        ]
        guard let spawn = spawnCandidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
            return (resolved, arguments)
        }
        return (spawn, ["--host", resolved] + arguments)
    }
}
#endif
