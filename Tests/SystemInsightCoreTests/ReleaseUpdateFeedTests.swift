import SystemInsightCore
import XCTest

final class ReleaseUpdateFeedTests: XCTestCase {
    func testVersionComparison() {
        XCTAssertTrue(ReleaseUpdateFeed(version: "0.2.0", downloadURL: "https://example.com").isNewer(than: "0.1.0"))
        XCTAssertFalse(ReleaseUpdateFeed(version: "0.1.0", downloadURL: "https://example.com").isNewer(than: "0.1.0"))
        XCTAssertFalse(ReleaseUpdateFeed(version: "0.1.0", downloadURL: "https://example.com").isNewer(than: "0.2.0"))
    }
}
