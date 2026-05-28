import Foundation
import XCTest
@testable import SystemInsightCore

final class SnapshotValidationTests: XCTestCase {
    func testRejectsOversizedEncodedPayload() {
        let oversized = Data(repeating: 0x7b, count: SnapshotValidationLimits.maxEncodedBytes + 1)
        XCTAssertThrowsError(try SnapshotValidator.validateEncodedData(oversized)) { error in
            XCTAssertEqual(error as? SnapshotValidationError, .payloadTooLarge(maxBytes: SnapshotValidationLimits.maxEncodedBytes))
        }
    }

    func testRejectsUnsupportedSchemaVersion() async throws {
        let snapshot = try await InsightEngine.mock().snapshot()
        let invalid = InsightSnapshot(
            schemaVersion: 99,
            generatedAt: snapshot.generatedAt,
            host: snapshot.host,
            metrics: snapshot.metrics,
            networkActivity: snapshot.networkActivity,
            securityFindings: snapshot.securityFindings,
            securityEvents: snapshot.securityEvents,
            issues: snapshot.issues,
            score: snapshot.score,
            rating: snapshot.rating,
            recommendations: snapshot.recommendations,
            topIssue: snapshot.topIssue
        )

        XCTAssertThrowsError(try SnapshotValidator.validate(invalid)) { error in
            XCTAssertEqual(error as? SnapshotValidationError, .unsupportedSchemaVersion(99))
        }
    }

    func testCacheRoundTripRejectsTamperedPayload() async throws {
        let snapshot = try await InsightEngine.mock().snapshot()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("system-insights-validation-\(UUID().uuidString)", isDirectory: true)
        let url = directory.appendingPathComponent(SnapshotCacheStorage.encryptedFilename)
        defer { try? FileManager.default.removeItem(at: directory) }

        try CacheStore(url: url).write(snapshot)
        var data = try Data(contentsOf: url)
        guard data.count > SnapshotCacheCipher.magic.count + 20 else {
            return XCTFail("Encrypted payload was unexpectedly short")
        }
        data[SnapshotCacheCipher.magic.count + 10] ^= 0xFF
        try data.write(to: url)

        XCTAssertThrowsError(try CacheStore(url: url).read())
    }

    func testEncryptedCacheIsNotPlainJSON() async throws {
        let snapshot = try await InsightEngine.mock().snapshot(
            at: Date(timeIntervalSince1970: 1_700_000_000),
            host: HostIdentity(hostName: "test", platform: "test", operatingSystem: "test")
        )
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("system-insights-encryption-\(UUID().uuidString)", isDirectory: true)
        let url = directory.appendingPathComponent(SnapshotCacheStorage.encryptedFilename)
        defer { try? FileManager.default.removeItem(at: directory) }

        try CacheStore(url: url).write(snapshot)
        let stored = try Data(contentsOf: url)

        XCTAssertTrue(SnapshotCacheCipher.isEncrypted(stored))
        XCTAssertEqual(try CacheStore(url: url).read().score, snapshot.score)
        XCTAssertEqual(try CacheStore(url: url).read().host.hostName, "test")
    }

}
