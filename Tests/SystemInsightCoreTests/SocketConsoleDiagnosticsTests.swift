import SystemInsightCore
import XCTest

final class SocketConsoleDiagnosticsTests: XCTestCase {
    func testEnvironmentVariableEnablesLogging() {
        let key = SocketConsoleDiagnostics.environmentVariable
        let prior = ProcessInfo.processInfo.environment[key]
        setenv(key, "1", 1)
        defer {
            if let prior {
                setenv(key, prior, 1)
            } else {
                unsetenv(key)
            }
        }
        XCTAssertTrue(SocketConsoleDiagnostics.isEnabled)
    }
}
