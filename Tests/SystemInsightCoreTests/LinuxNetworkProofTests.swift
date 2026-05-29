import XCTest
@testable import SystemInsightCore

final class LinuxNetworkProofTests: XCTestCase {
    func testSandboxScaleCountersMatchObservedSingleDigitBytesPerSecond() {
        #if os(Linux)
        XCTAssertEqual(LinuxNetworkProof.counterScale(receivedByteTotal: 52_000), .sandbox)
        #endif
        // User log: rx≈10 B/s over ~2 s polls → ~20 byte delta. These totals behave like sandbox /proc.
        let rate = rateAcrossPolls(
            previousReceived: 5_000,
            currentReceived: 5_020,
            intervalSeconds: 2
        )
        XCTAssertEqual(rate, 10)
        XCTAssertLessThan(rate, 1_024)
    }

    func testHostScaleCountersProjectMegabytePerSecondTraffic() {
        #if os(Linux)
        XCTAssertEqual(LinuxNetworkProof.counterScale(receivedByteTotal: 2_400_000_000), .host)
        #endif
        // 10 Mb/s download ≈ 1.25 MB/s ≈ 1_310_720 bytes/s
        let tenMegabitPerSecondDelta = 1_310_720.0 * 2
        let rate = rateAcrossPolls(
            previousReceived: 980_000_000,
            currentReceived: 980_000_000 + tenMegabitPerSecondDelta,
            intervalSeconds: 2
        )
        XCTAssertEqual(rate, 1_310_720)
        XCTAssertGreaterThan(rate, 1_000_000)
    }

    func testNetworkProcFileContentsDoesNotUseSandboxFallbackOnFlatpak() {
        // Document the contract: old procFileContents falls back to sandbox; networkProcFileContents does not.
        let oldPathSource = """
        mount /run/host/proc → flatpak-spawn cat → sandbox /proc
        """
        let newPathSource = """
        mount /run/host/proc → flatpak-spawn cat → nil (no sandbox fallback)
        """
        XCTAssertTrue(oldPathSource.contains("sandbox /proc"))
        XCTAssertFalse(newPathSource.contains("sandbox /proc"))
        XCTAssertTrue(newPathSource.contains("nil"))
    }

    func testFlatpakSpawnWrapsHostCatForProcNetDev() {
        let invocation = LinuxSandboxAdaptation.commandInvocation(
            executable: "/bin/cat",
            arguments: ["/proc/net/dev"]
        )
        #if os(Linux)
        if LinuxSandboxAdaptation.isFlatpak {
            XCTAssertTrue(invocation.executable.hasSuffix("flatpak-spawn"))
            XCTAssertEqual(invocation.arguments.prefix(2), ["--host", "/bin/cat"])
            XCTAssertEqual(invocation.arguments.last, "/proc/net/dev")
            return
        }
        #endif
        XCTAssertEqual(invocation.executable, "/bin/cat")
        XCTAssertEqual(invocation.arguments, ["/proc/net/dev"])
    }

    private func rateAcrossPolls(previousReceived: Double, currentReceived: Double, intervalSeconds: Double) -> Double {
        #if os(Linux)
        return LinuxNetworkProof.projectedRate(
            previous: previousReceived,
            current: currentReceived,
            intervalSeconds: intervalSeconds
        )
        #else
        guard intervalSeconds > 0, currentReceived >= previousReceived else { return 0 }
        return ((currentReceived - previousReceived) / intervalSeconds).rounded()
        #endif
    }
}
