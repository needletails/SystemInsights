import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public struct CacheStore: Sendable {
    public let url: URL
    private let cacheDirectory: URL

    public init(url: URL) {
        cacheDirectory = url.deletingLastPathComponent()
        self.url = SnapshotCacheStorage.encryptedCacheURL(in: cacheDirectory)
    }

    public func write(_ snapshot: InsightSnapshot) throws {
        let snapshot = snapshot.clampedForPersistence()
        try SnapshotValidator.validate(snapshot)
        let fileManager = FileManager.default
        try fileManager.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: NSNumber(value: Int16(0o700))]
        )

        let plaintext = try Self.encodedData(for: snapshot)
        let protected = try SnapshotCacheStorage.protectPayload(plaintext, cacheDirectory: cacheDirectory)

        let temporaryURL = cacheDirectory.appendingPathComponent(".\(url.lastPathComponent).\(UUID().uuidString).tmp")
        let permissions = NSNumber(value: Int16(0o600))
        guard fileManager.createFile(
            atPath: temporaryURL.path,
            contents: nil,
            attributes: [.posixPermissions: permissions]
        ) else {
            throw CocoaError(.fileWriteUnknown)
        }
        defer { try? fileManager.removeItem(at: temporaryURL) }

        let handle = try FileHandle(forWritingTo: temporaryURL)
        defer { try? handle.close() }
        try handle.write(contentsOf: protected)
        try handle.synchronize()
        try handle.close()

        try atomicallyInstall(temporaryURL)
        try fileManager.setAttributes([.posixPermissions: permissions], ofItemAtPath: url.path)
    }

    public func read() throws -> InsightSnapshot {
        let plaintext = try readValidatedPlaintext()
        return try Self.decodedSnapshot(from: plaintext)
    }

    public static func encodedData(for snapshot: InsightSnapshot) throws -> Data {
        try SnapshotValidator.validate(snapshot)
        let data = try encoder.encode(snapshot)
        try SnapshotValidator.validateEncodedData(data)
        return data
    }

    public static func decodedSnapshot(from data: Data) throws -> InsightSnapshot {
        try validateEncodedData(data)
        let snapshot = try decoder.decode(InsightSnapshot.self, from: data)
        try SnapshotValidator.validate(snapshot)
        return snapshot
    }

    public static func validateEncodedData(_ data: Data) throws {
        try SnapshotValidator.validateEncodedData(data)
    }

    public static func readStoredData(from url: URL) throws -> Data {
        let directory = url.deletingLastPathComponent()
        var lastError: Error?
        for candidate in SnapshotCacheStorage.candidateReadURLs(in: directory) {
            guard FileManager.default.fileExists(atPath: candidate.path) else { continue }
            do {
                let stored = try readFileData(from: candidate)
                let plaintext = try SnapshotCacheStorage.exposePayload(stored, cacheDirectory: directory)
                try validateEncodedData(plaintext)
                return plaintext
            } catch {
                lastError = error
            }
        }
        if let lastError {
            throw lastError
        }
        throw CocoaError(.fileReadNoSuchFile)
    }

    public static func writeEncryptedSnapshot(_ snapshot: InsightSnapshot, to url: URL) throws {
        try CacheStore(url: url).write(snapshot)
    }

    public static func synchronizeEncryptionKeys(across cacheFileOrDirectoryURLs: [URL]) throws {
        let directories = cacheFileOrDirectoryURLs.map {
            $0.hasDirectoryPath || $0.pathExtension.isEmpty
                ? $0
                : $0.deletingLastPathComponent()
        }
        var seen: Set<String> = []
        let uniqueDirectories = directories.filter { seen.insert($0.path).inserted }
        guard let primary = uniqueDirectories.first else { return }
        if !SnapshotCachePasswordProtection.isProtectionEnabled(in: primary) {
            _ = try SnapshotCacheKeyStore.encryptionKey(forCacheDirectory: primary)
        }
        for directory in uniqueDirectories.dropFirst() {
            try SnapshotCacheKeyStore.synchronizeKey(from: primary, to: directory)
        }
    }

    public static var ubuntuDefaultURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/share/system-insights", isDirectory: true)
            .appendingPathComponent(SnapshotCacheStorage.encryptedFilename, isDirectory: false)
    }

    public static var macOSFallbackURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/SystemInsights", isDirectory: true)
            .appendingPathComponent(SnapshotCacheStorage.encryptedFilename, isDirectory: false)
    }

    private func readValidatedPlaintext() throws -> Data {
        try Self.readStoredData(from: url)
    }

    private static func readFileData(from url: URL) throws -> Data {
        #if canImport(Darwin)
        let fileDescriptor = Darwin.open(url.path, O_RDONLY)
        guard fileDescriptor >= 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        defer { Darwin.close(fileDescriptor) }

        var data = Data()
        let bufferSize = 64 * 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while true {
            let bytesRead = buffer.withUnsafeMutableBytes {
                Darwin.read(fileDescriptor, $0.baseAddress, bufferSize)
            }
            if bytesRead > 0 {
                data.append(buffer, count: bytesRead)
            } else if bytesRead == 0 {
                return data
            } else if errno != EINTR {
                throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
            }
        }
        #else
        return try Data(contentsOf: url)
        #endif
    }

    private func atomicallyInstall(_ temporaryURL: URL) throws {
        #if canImport(Darwin) || canImport(Glibc)
        let result = temporaryURL.path.withCString { source in
            url.path.withCString { destination in
                rename(source, destination)
            }
        }
        guard result == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        #else
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            _ = try fileManager.replaceItemAt(url, withItemAt: temporaryURL)
        } else {
            try fileManager.moveItem(at: temporaryURL, to: url)
        }
        #endif
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
