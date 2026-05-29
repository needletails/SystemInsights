import XCTest
@testable import SystemInsightCore

final class LinuxSandboxAdaptationTests: XCTestCase {
    func testHostExecutablePathStripsFlatpakHostMountPrefix() {
        XCTAssertEqual(
            LinuxSandboxAdaptation.hostExecutablePath(for: "/run/host/usr/bin/ss"),
            "/usr/bin/ss"
        )
        XCTAssertEqual(
            LinuxSandboxAdaptation.hostExecutablePath(for: "/run/host/bin/df"),
            "/bin/df"
        )
    }

    func testHostExecutablePathLeavesNormalPathsAlone() {
        XCTAssertEqual(
            LinuxSandboxAdaptation.hostExecutablePath(for: "/usr/bin/ss"),
            "/usr/bin/ss"
        )
    }

    func testDiskUsageValidationRejectsBogusFlatpakMountValues() {
        XCTAssertFalse(LinuxSandboxAdaptation.isUsableDiskUsagePercent(0))
        XCTAssertFalse(LinuxSandboxAdaptation.isUsableDiskUsagePercent(-1))
        XCTAssertFalse(LinuxSandboxAdaptation.isUsableDiskUsagePercent(101))
        XCTAssertFalse(LinuxSandboxAdaptation.isUsableDiskUsagePercent(.nan))
        XCTAssertTrue(LinuxSandboxAdaptation.isUsableDiskUsagePercent(42))
    }
}
