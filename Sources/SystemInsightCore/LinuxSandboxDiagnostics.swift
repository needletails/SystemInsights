import Foundation

#if os(Linux)
public enum LinuxSandboxDiagnostics: Sendable {
    public static func logStartupReport() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let hostRoot = FileManager.default.fileExists(atPath: "/run/host")
        let hostProc = FileManager.default.fileExists(atPath: "/run/host/proc/stat")
        let procDirectory = LinuxSandboxAdaptation.procDirectory
        let diskPath = LinuxSandboxAdaptation.diskUsagePath
        let cacheDirectory = CacheSecurityCoordinator.primaryCacheDirectory().path
        let flatpakID = ProcessInfo.processInfo.environment["FLATPAK_ID"] ?? "no"
        let cacheWritable = cacheDirectoryIsWritable()
        let diskUsage = probeDiskUsagePercent()
        let spawnAvailable = ["/usr/bin/flatpak-spawn", "/usr/libexec/flatpak-spawn"].contains {
            FileManager.default.isExecutableFile(atPath: $0)
        }

        let line = """
        [SystemInsights] sandbox flatpak=\(flatpakID) home=\(home) hostRoot=\(hostRoot) hostProc=\(hostProc) proc=\(procDirectory) diskPath=\(diskPath) diskUsage=\(diskUsage.map { String(format: "%.1f%%", $0) } ?? "n/a") cache=\(cacheDirectory) cacheWritable=\(cacheWritable) flatpakSpawn=\(spawnAvailable)

        """
        FileHandle.standardError.write(Data(line.utf8))
    }

    public static func probeDiskUsagePercent() -> Double? {
        let diskPath = LinuxSandboxAdaptation.diskUsagePath
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path

        if !(LinuxSandboxAdaptation.isFlatpak && diskPath == homePath),
           let usage = LinuxSandboxAdaptation.fileSystemUsagePercent(at: diskPath) {
            return usage
        }
        if LinuxSandboxAdaptation.isFlatpak, let usage = diskUsageFromDF() {
            return usage
        }
        if let usage = LinuxSandboxAdaptation.fileSystemUsagePercent(at: diskPath) {
            return usage
        }
        if diskPath != homePath {
            return LinuxSandboxAdaptation.fileSystemUsagePercent(at: homePath)
        }
        return nil
    }

    private static func cacheDirectoryIsWritable() -> Bool {
        let directory = CacheSecurityCoordinator.primaryCacheDirectory()
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: NSNumber(value: Int16(0o700))]
            )
            let testURL = directory.appendingPathComponent(".write-test-\(ProcessInfo.processInfo.processIdentifier)")
            try Data("ok".utf8).write(to: testURL, options: .atomic)
            try FileManager.default.removeItem(at: testURL)
            return true
        } catch {
            return false
        }
    }

    private static func diskUsageFromDF() -> Double? {
        let candidates = ["/bin/df", "/usr/bin/df"]
        guard let executable = LinuxSandboxAdaptation.firstExecutable(candidates) else {
            return nil
        }
        guard
            let output = CommandRunner.run(executable, arguments: ["-P", "/"], timeout: 4),
            output.exitCode == 0
        else {
            return nil
        }

        let lines = output.stdout.split(whereSeparator: \.isNewline)
        guard lines.count >= 2 else { return nil }
        let fields = lines[1].split(whereSeparator: \.isWhitespace)
        guard fields.count >= 5 else { return nil }
        let capacity = fields[4].replacingOccurrences(of: "%", with: "")
        guard let usage = Double(capacity) else { return nil }
        return LinuxSandboxAdaptation.isUsableDiskUsagePercent(usage) ? usage : nil
    }
}
#endif
