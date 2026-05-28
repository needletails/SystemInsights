import Foundation
import XCTest
@testable import SystemInsightCore

final class InsightEngineTests: XCTestCase {
    func testMockSnapshotScoresIssuesAndRecommendations() async throws {
        let snapshot = try await InsightEngine.mock().snapshot(
            at: Date(timeIntervalSince1970: 1_700_000_000),
            host: HostIdentity(hostName: "test", platform: "test", operatingSystem: "test")
        )

        XCTAssertEqual(snapshot.schemaVersion, 3)
        XCTAssertEqual(snapshot.score, 70)
        XCTAssertEqual(snapshot.rating, .critical)
        XCTAssertEqual(snapshot.topIssue?.id, "firewall.disabled")
        XCTAssertEqual(snapshot.metrics.network.vpn.state, .connected)
        XCTAssertEqual(snapshot.metrics.network.latencyMilliseconds, 28)
        XCTAssertEqual(snapshot.securityEvents.first?.source, "macOS Security Log")
        XCTAssertTrue(snapshot.recommendations.contains("Enable the firewall."))
        XCTAssertTrue(snapshot.recommendations.contains("Close video-renderer if it is no longer needed."))
    }

    func testHealthyMetricsProduceGoodScore() async throws {
        let engine = InsightEngine(
            metricCollector: MockMetricCollector(metrics: PerformanceMetrics(
                cpuLoadPercent: 10,
                memoryPressurePercent: 20,
                diskUsagePercent: 30,
                topProcesses: []
            )),
            securityChecker: MockSecurityChecker(findings: [])
        )

        let snapshot = try await engine.snapshot()
        XCTAssertEqual(snapshot.score, 100)
        XCTAssertEqual(snapshot.rating, .good)
        XCTAssertNil(snapshot.topIssue)
    }

    func testInformationalFindingDoesNotLowerHealthScore() async throws {
        let engine = InsightEngine(
            metricCollector: MockMetricCollector(metrics: PerformanceMetrics(
                cpuLoadPercent: 10,
                memoryPressurePercent: 20,
                diskUsagePercent: 30,
                topProcesses: []
            )),
            securityChecker: MockSecurityChecker(findings: [
                SecurityFinding(
                    id: "firewall.disabled",
                    title: "macOS Application Firewall is off",
                    detail: "An optional protection is not active.",
                    severity: .informational
                )
            ])
        )

        let snapshot = try await engine.snapshot()
        XCTAssertEqual(snapshot.score, 100)
        XCTAssertEqual(snapshot.rating, .good)
        XCTAssertEqual(snapshot.topIssue?.id, "firewall.disabled")
    }

    func testSingleCriticalIssueCannotBeLabeledGood() async throws {
        let engine = InsightEngine(
            metricCollector: MockMetricCollector(metrics: PerformanceMetrics(
                cpuLoadPercent: 10,
                memoryPressurePercent: 20,
                diskUsagePercent: 30,
                topProcesses: []
            )),
            securityChecker: MockSecurityChecker()
        )

        let snapshot = try await engine.snapshot()
        XCTAssertEqual(snapshot.score, 80)
        XCTAssertEqual(snapshot.rating, .critical)
    }

    func testCacheRoundTripPreservesSnapshot() async throws {
        let snapshot = try await InsightEngine.mock().snapshot(
            at: Date(timeIntervalSince1970: 1_700_000_000),
            host: HostIdentity(hostName: "test", platform: "test", operatingSystem: "test")
        )
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = CacheStore(url: directory.appendingPathComponent("latest.json"))
        defer { try? FileManager.default.removeItem(at: directory) }

        try store.write(snapshot)
        try store.write(snapshot)

        XCTAssertEqual(try store.read(), snapshot)
        let permissions = try FileManager.default.attributesOfItem(atPath: store.url.path)[.posixPermissions] as? NSNumber
        XCTAssertEqual(permissions?.intValue ?? 0, 0o600)
    }

    func testCommandRunnerStopsSlowProbeAtTimeout() {
        let startedAt = Date()

        XCTAssertNil(CommandRunner.run("/bin/sleep", arguments: ["2"], timeout: 0.05))
        XCTAssertLessThan(Date().timeIntervalSince(startedAt), 1)
    }

    func testVersionOneCacheDecodesWithNewTelemetryDefaults() throws {
        let json = """
        {
          "schemaVersion": 1,
          "generatedAt": "2023-11-14T22:13:20Z",
          "host": { "hostName": "test", "platform": "test", "operatingSystem": "test" },
          "metrics": {
            "cpuLoadPercent": 12,
            "memoryPressurePercent": 24,
            "diskUsagePercent": 36,
            "topProcesses": []
          },
          "securityFindings": [],
          "issues": [],
          "score": 100,
          "rating": "Good",
          "recommendations": [],
          "topIssue": null
        }
        """
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = CacheStore(url: directory.appendingPathComponent(SnapshotCacheStorage.encryptedFilename))
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let plaintext = Data(json.utf8)
        let protected = try SnapshotCacheStorage.protectPayload(plaintext, cacheDirectory: directory)
        try protected.write(to: store.url, options: .atomic)

        let snapshot = try store.read()
        XCTAssertEqual(snapshot.schemaVersion, 1)
        XCTAssertEqual(snapshot.metrics.network, .unavailable)
        XCTAssertEqual(snapshot.networkActivity, [])
        XCTAssertEqual(snapshot.securityEvents, [])
    }

    func testCacheRoundTripPreservesNetworkActivity() throws {
        let connection = VisibleSocket(
            processName: "browser",
            pid: 42,
            localEndpoint: "172.16.0.2:62000",
            remoteEndpoint: "203.0.113.10:443",
            state: .established
        )
        let snapshot = InsightSnapshot(
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            host: HostIdentity(hostName: "test", platform: "test", operatingSystem: "test"),
            metrics: .init(cpuLoadPercent: 1, memoryPressurePercent: 2, diskUsagePercent: 3, topProcesses: []),
            networkActivity: [.init(timestamp: Date(timeIntervalSince1970: 1_700_000_001), action: .opened, connection: connection)],
            securityFindings: [],
            issues: [],
            score: 100,
            rating: .good,
            recommendations: [],
            topIssue: nil
        )
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = CacheStore(url: url)
        defer { try? FileManager.default.removeItem(at: url) }

        try store.write(snapshot)

        XCTAssertEqual(try store.read().networkActivity, snapshot.networkActivity)
    }

    func testLegacyNetworkActivityWithoutTransportDefaultsToTCP() throws {
        let json = """
        {
          "timestamp": "2023-11-14T22:13:20Z",
          "action": "OPEN",
          "processName": "browser",
          "pid": 42,
          "localEndpoint": "172.16.0.2:62000",
          "remoteEndpoint": "203.0.113.10:443"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let event = try decoder.decode(NetworkActivityEvent.self, from: Data(json.utf8))

        XCTAssertEqual(event.transport, .tcp)
    }

    func testLegacyNetworkMetricsWithoutLatencyStillDecode() throws {
        let json = """
        {
          "interfaceName": "en0",
          "receivedBytesPerSecond": 100,
          "sentBytesPerSecond": 50,
          "activeTCPConnections": 2,
          "vpn": {
            "state": "Not Detected",
            "activeInterfaces": [],
            "detail": "No tunnel."
          }
        }
        """

        let network = try JSONDecoder().decode(NetworkMetrics.self, from: Data(json.utf8))

        XCTAssertNil(network.latencyMilliseconds)
    }

    func testParsesLinuxVisibleTCPConnectionRecords() {
        let output = """
        ESTAB  0 0 10.0.0.4:48122 93.184.216.34:443 users:(("firefox",pid=2240,fd=91))
        LISTEN 0 4096 127.0.0.1:5432 0.0.0.0:* users:(("postgres",pid=1422,fd=7))
        ESTAB  0 0 10.0.0.4:54000 198.51.100.20:443
        """

        let connections = SystemMetricCollector.parseLinuxVisibleTCPConnections(output)

        XCTAssertEqual(connections.count, 3)
        XCTAssertEqual(connections[0].processName, "firefox")
        XCTAssertEqual(connections[0].remoteEndpoint, "93.184.216.34:443")
        XCTAssertEqual(connections[0].serviceHint.label, "HTTPS/TLS")
        XCTAssertEqual(connections[1].processName, "unattributed")
        XCTAssertEqual(connections[2].state, .listening)
        XCTAssertNil(connections[2].remoteEndpoint)
        XCTAssertEqual(connections[2].serviceHint.label, "POSTGRES")
    }

    func testParsesLinuxHexEndpointPortsForServiceHints() {
        let output = """
        ESTAB  0 0 0100007F:1538 0100007F:1538 users:(("postgres",pid=1422,fd=7))
        """

        let connections = SystemMetricCollector.parseLinuxVisibleTCPConnections(output)
        XCTAssertEqual(connections.count, 1)
        XCTAssertEqual(connections[0].serviceHint.label, "POSTGRES")
    }

    func testParsesLinuxVisibleUDPSocketRecords() {
        let output = """
        UNCONN 0 0 0.0.0.0:5353 0.0.0.0:* users:(("avahi-daemon",pid=721,fd=14))
        ESTAB  0 0 10.0.0.4:42420 1.1.1.1:53 users:(("resolver",pid=812,fd=8))
        """

        let sockets = SystemMetricCollector.parseLinuxVisibleUDPSockets(output)

        XCTAssertEqual(sockets.count, 2)
        XCTAssertEqual(sockets[0].transport, .udp)
        XCTAssertEqual(sockets[0].state, .datagram)
        XCTAssertNil(sockets[0].remoteEndpoint)
        XCTAssertEqual(sockets[1].remoteEndpoint, "1.1.1.1:53")
    }

    #if os(macOS)
    func testRoutedTunnelWinsOverDisconnectedConfiguredVPN() {
        let vpn = SystemMetricCollector.resolveMacOSVPNConnectivity(
            connectionText: "* (Disconnected) VPN \"Singapore China\" [VPN:provider]",
            routedTunnelInterfaces: ["utun9"]
        )

        XCTAssertEqual(vpn.state, .tunnelDetected)
        XCTAssertEqual(vpn.activeInterfaces, ["utun9"])
    }

    func testParsesVisibleTCPConnectionJournalRecords() {
        let output = """
        p1197
        cDuckDuckGo
        f47
        PTCP
        n172.16.0.2:64189->52.250.42.157:443
        TST=ESTABLISHED
        p1422
        cpostgres
        f7
        PTCP
        n127.0.0.1:5432
        TST=LISTEN
        """

        let connections = SystemMetricCollector.parseMacOSVisibleTCPConnections(output)

        XCTAssertEqual(connections.count, 2)
        XCTAssertEqual(connections[0].processName, "DuckDuckGo")
        XCTAssertEqual(connections[0].state, .established)
        XCTAssertEqual(connections[0].remoteEndpoint, "52.250.42.157:443")
        XCTAssertEqual(connections[0].serviceHint.label, "HTTPS/TLS")
        XCTAssertEqual(connections[1].state, .listening)
        XCTAssertNil(connections[1].remoteEndpoint)
        XCTAssertEqual(connections[1].serviceHint.label, "POSTGRES")
    }

    func testParsesVisibleUDPSocketRecords() {
        let output = """
        p9117
        cCodex
        f89
        PUDP
        n172.16.0.2:58371->172.64.146.98:443
        p1422
        cmDNSResponder
        f7
        PUDP
        n*:5353
        """

        let sockets = SystemMetricCollector.parseMacOSVisibleSockets(output)

        XCTAssertEqual(sockets.count, 2)
        XCTAssertEqual(sockets[0].transport, .udp)
        XCTAssertEqual(sockets[0].state, .datagram)
        XCTAssertEqual(sockets[0].remoteEndpoint, "172.64.146.98:443")
        XCTAssertEqual(sockets[1].localEndpoint, "*:5353")
        XCTAssertEqual(sockets[0].serviceHint.label, "QUIC/HTTP3")
        XCTAssertEqual(sockets[1].serviceHint.label, "mDNS")
    }
    #endif
}
