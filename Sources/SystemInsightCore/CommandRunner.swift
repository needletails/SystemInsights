import Foundation

struct CommandOutput {
    let exitCode: Int32
    let stdout: String
    let stderr: String

    var combinedText: String {
        [stdout, stderr].filter { !$0.isEmpty }.joined(separator: "\n")
    }
}

enum CommandRunner {
    private static func hardenedEnvironment() -> [String: String] {
        var environment: [String: String] = [
            "LC_ALL": "C",
            "LANG": "C",
            "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        ]
        #if os(macOS)
        environment["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/libexec"
        #endif
        if let home = ProcessInfo.processInfo.environment["HOME"], !home.isEmpty {
            environment["HOME"] = home
        }
        if let user = ProcessInfo.processInfo.environment["USER"], !user.isEmpty {
            environment["USER"] = user
        }
        if let logName = ProcessInfo.processInfo.environment["LOGNAME"], !logName.isEmpty {
            environment["LOGNAME"] = logName
        }
        return environment
    }

    static func run(
        _ executable: String,
        arguments: [String] = [],
        timeout: TimeInterval = 10
    ) -> CommandOutput? {
        #if os(Linux)
        let invocation = LinuxSandboxAdaptation.commandInvocation(
            executable: executable,
            arguments: arguments
        )
        let resolvedExecutable = invocation.executable
        let resolvedArguments = invocation.arguments
        #else
        let resolvedExecutable = executable
        let resolvedArguments = arguments
        #endif

        guard FileManager.default.isExecutableFile(atPath: resolvedExecutable) else {
            return nil
        }

        let standardOutput = Pipe()
        let standardError = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: resolvedExecutable)
        process.arguments = resolvedArguments
        process.standardOutput = standardOutput
        process.standardError = standardError
        process.environment = hardenedEnvironment()
        let outputBuffer = OutputBuffer()
        let errorBuffer = OutputBuffer()
        standardOutput.fileHandleForReading.readabilityHandler = { handle in
            outputBuffer.append(handle.availableData)
        }
        standardError.fileHandleForReading.readabilityHandler = { handle in
            errorBuffer.append(handle.availableData)
        }

        do {
            try process.run()
        } catch {
            standardOutput.fileHandleForReading.readabilityHandler = nil
            standardError.fileHandleForReading.readabilityHandler = nil
            return nil
        }

        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }

        guard !process.isRunning else {
            process.terminate()
            process.waitUntilExit()
            standardOutput.fileHandleForReading.readabilityHandler = nil
            standardError.fileHandleForReading.readabilityHandler = nil
            return nil
        }

        standardOutput.fileHandleForReading.readabilityHandler = nil
        standardError.fileHandleForReading.readabilityHandler = nil
        outputBuffer.append(standardOutput.fileHandleForReading.readDataToEndOfFile())
        errorBuffer.append(standardError.fileHandleForReading.readDataToEndOfFile())
        return CommandOutput(
            exitCode: process.terminationStatus,
            stdout: String(decoding: outputBuffer.data, as: UTF8.self),
            stderr: String(decoding: errorBuffer.data, as: UTF8.self)
        )
    }
}

private final class OutputBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var contents = Data()

    var data: Data {
        lock.lock()
        defer { lock.unlock() }
        return contents
    }

    func append(_ data: Data) {
        guard !data.isEmpty else { return }
        lock.lock()
        contents.append(data)
        lock.unlock()
    }
}

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

    /// Map absolute host paths for Flatpak `host-os` mounts.
    static func hostPath(_ path: String) -> String {
        #if os(Linux)
        guard path.hasPrefix("/"), !path.hasPrefix("/run/host/") else {
            return path
        }
        let hostCandidate = "/run/host\(path)"
        if FileManager.default.fileExists(atPath: hostCandidate) {
            return hostCandidate
        }
        return path
        #else
        return path
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
