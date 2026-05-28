import XCTest
@testable import SystemInsightCore

final class SnapshotCachePasswordTests: XCTestCase {
    func testPasswordWrapRoundTrip() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("system-insights-password-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try SnapshotCachePasswordProtection.setupPassword("test-password-1", in: directory)
        let unlocked = try SnapshotCachePasswordProtection.unlock(password: "test-password-1", in: directory)
        SnapshotCacheSession.installSyncKey(unlocked)

        let snapshot = try await InsightEngine.mock().snapshot(
            at: Date(timeIntervalSince1970: 1_700_000_000),
            host: HostIdentity(hostName: "test", platform: "test", operatingSystem: "test")
        )
        let store = CacheStore(url: directory.appendingPathComponent(SnapshotCacheStorage.encryptedFilename))
        try store.write(snapshot)

        SnapshotCacheSession.clearSyncKey()
        let reUnlocked = try SnapshotCachePasswordProtection.unlock(
            password: "test-password-1",
            in: directory
        )
        SnapshotCacheSession.installSyncKey(reUnlocked)
        let readBack = try CacheStore(url: store.url).read()
        XCTAssertEqual(readBack.score, snapshot.score)
    }

    func testWrongPasswordFails() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("system-insights-password-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try SnapshotCachePasswordProtection.setupPassword("correct-password", in: directory)
        XCTAssertThrowsError(
            try SnapshotCachePasswordProtection.unlock(password: "wrong-password", in: directory)
        ) { error in
            XCTAssertEqual(error as? SnapshotCacheLockError, .invalidPassword)
        }
    }
}
