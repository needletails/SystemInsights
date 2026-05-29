import Foundation

enum LinuxSandboxAdaptation {
    /// True when running inside a Flatpak sandbox (`FLATPAK_ID` is set).
    static var isFlatpak: Bool {
        #if os(Linux)
        guard let id = ProcessInfo.processInfo.environment["FLATPAK_ID"], !id.isEmpty else {
            return false
        }
        return true
        #else
        return false
        #endif
    }

    /// Host `/proc` when `host-os` exposes it at `/run/host/proc`, otherwise sandbox `/proc`.
    static var procDirectory: String {
        #if os(Linux)
        if FileManager.default.fileExists(atPath: "/run/host/proc/stat") {
            return "/run/host/proc"
        }
        return "/proc"
        #else
        return "/proc"
        #endif
    }

    /// Prefer host root disk usage when available inside Flatpak.
    static var diskUsagePath: String {
        #if os(Linux)
        if FileManager.default.fileExists(atPath: "/run/host") {
            return "/run/host"
        }
        return NSHomeDirectory()
        #else
        return NSHomeDirectory()
        #endif
    }

    static var sysClassNetDirectory: String {
        #if os(Linux)
        if FileManager.default.fileExists(atPath: "/run/host/sys/class/net") {
            return "/run/host/sys/class/net"
        }
        return "/sys/class/net"
        #else
        return "/sys/class/net"
        #endif
    }

    /// Resolve an executable path, preferring the host copy under `/run/host` when present.
    static func resolveExecutable(_ executable: String) -> String {
        #if os(Linux)
        if executable.hasPrefix("/run/host/") {
            return executable
        }
        let hostCandidate = "/run/host\(executable)"
        if FileManager.default.isExecutableFile(atPath: hostCandidate) {
            return hostCandidate
        }
        return executable
        #else
        return executable
        #endif
    }

    /// When sandboxed, run the command on the host via `flatpak-spawn --host`.
    static func commandInvocation(
        executable: String,
        arguments: [String]
    ) -> (executable: String, arguments: [String]) {
        #if os(Linux)
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
        #else
        return (executable, arguments)
        #endif
    }
}
