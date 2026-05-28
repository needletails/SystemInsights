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
        guard FileManager.default.isExecutableFile(atPath: executable) else {
            return nil
        }

        let standardOutput = Pipe()
        let standardError = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
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
