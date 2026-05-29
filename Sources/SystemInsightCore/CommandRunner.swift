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
        let resolvedTimeout = LinuxSandboxAdaptation.isFlatpak ? min(timeout, 4) : timeout
        #else
        let resolvedExecutable = executable
        let resolvedArguments = arguments
        let resolvedTimeout = timeout
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

        let deadline = Date().addingTimeInterval(resolvedTimeout)
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

    static func procFileContents(_ relativePath: String) -> String? {
        let trimmed = relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let hostMountedPath = "/run/host/proc/\(trimmed)"
        if FileManager.default.fileExists(atPath: hostMountedPath),
           let contents = try? String(contentsOfFile: hostMountedPath, encoding: .utf8) {
            return contents
        }

        #if os(Linux)
        if isFlatpak, let contents = flatpakHostTextFile("/proc/\(trimmed)") {
            return contents
        }
        #endif

        let sandboxPath = "/proc/\(trimmed)"
        return try? String(contentsOfFile: sandboxPath, encoding: .utf8)
    }

    private static func flatpakHostTextFile(_ path: String) -> String? {
        #if os(Linux)
        guard isFlatpak, let cat = firstExecutable(["/bin/cat", "/usr/bin/cat"]) else {
            return nil
        }
        guard let output = CommandRunner.run(cat, arguments: [path], timeout: 2),
              output.exitCode == 0 else {
            return nil
        }
        return output.stdout
        #else
        return nil
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

    /// First candidate path that exists and is executable (host path under Flatpak when available).
    static func firstExecutable(_ candidates: [String]) -> String? {
        #if os(Linux)
        for candidate in candidates {
            let resolved = resolveExecutable(candidate)
            if FileManager.default.isExecutableFile(atPath: resolved) {
                return resolved
            }
        }
        return nil
        #else
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
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
        return (spawn, ["--host", hostExecutablePath(for: resolved)] + arguments)
        #else
        return (executable, arguments)
        #endif
    }

    static func hostExecutablePath(for resolvedExecutable: String) -> String {
        let hostPrefix = "/run/host"
        guard resolvedExecutable.hasPrefix("\(hostPrefix)/") else {
            return resolvedExecutable
        }
        let stripped = resolvedExecutable.dropFirst(hostPrefix.count)
        return stripped.isEmpty ? "/" : String(stripped)
    }

    static func fileSystemUsagePercent(at path: String) -> Double? {
        guard
            let attributes = try? FileManager.default.attributesOfFileSystem(forPath: path),
            let size = (attributes[.systemSize] as? NSNumber)?.doubleValue,
            let free = (attributes[.systemFreeSize] as? NSNumber)?.doubleValue,
            size > 0
        else {
            return nil
        }
        let usage = ((size - free) / size * 100).rounded()
        return isUsableDiskUsagePercent(usage) ? usage : nil
    }

    static func isUsableDiskUsagePercent(_ usage: Double) -> Bool {
        usage.isFinite && usage > 0 && usage <= 100
    }
}
