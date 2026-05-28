import SystemInsightCore
import XCTest

final class PanelPresentationTests: XCTestCase {
    func testMakePanelPresentationFromSnapshot() async throws {
        let snapshot = try await InsightEngine.mock().snapshot()
        let panel = PanelPresentation.make(from: snapshot)

        XCTAssertFalse(panel.indicatorLabel.isEmpty)
        XCTAssertEqual(panel.ratingStyle, snapshot.rating.rawValue.lowercased())
        XCTAssertTrue(panel.statusLine.contains("\(snapshot.score)/100"))
        XCTAssertTrue(panel.metricsLine.contains("CPU"))
        XCTAssertEqual(panel.protocolNoticeLine, PanelPresentation.protocolNotice)
    }

    func testLockedPresentation() {
        let panel = PanelPresentation.locked()
        XCTAssertEqual(panel.indicatorLabel, "Speed --")
        XCTAssertTrue(panel.statusLine.contains("locked"))
    }
}
