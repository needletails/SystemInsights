import SystemInsightCore
import XCTest

final class SocketServiceClassifierTests: XCTestCase {
    func testPortParsingIPv4AndWildcard() {
        XCTAssertEqual(SocketServiceClassifier.portNumber(from: "203.0.113.5:443"), 443)
        XCTAssertEqual(SocketServiceClassifier.portNumber(from: "*:5353"), 5353)
    }

    func testPortParsingIPv6AndHex() {
        XCTAssertEqual(SocketServiceClassifier.portNumber(from: "[2001:db8::1]:6697"), 6697)
        XCTAssertEqual(SocketServiceClassifier.portNumber(from: "0100007F:1538"), 5432)
        XCTAssertEqual(
            SocketServiceClassifier.portNumber(from: "00000000000000000000000000000001:01BB"),
            443
        )
    }

    func testEstablishedTCPToPort443ClassifiesAsHTTPS() {
        let socket = VisibleSocket(
            processName: "Safari",
            pid: 4242,
            localEndpoint: "172.16.0.2:59568",
            remoteEndpoint: "185.70.42.70:443",
            state: .established
        )
        XCTAssertEqual(socket.serviceHint.label, "HTTPS/TLS")
        XCTAssertEqual(socket.serviceHint.confidence, .portMapped)
    }

    #if os(macOS)
    func testLiveVisibleSocketsIncludeClassifiedServices() async {
        let sockets = await SystemMetricCollector().collectVisibleSockets()
        guard !sockets.isEmpty else { return }

        let classified = sockets.filter { $0.serviceHint.confidence != .unclassified }
        XCTAssertGreaterThan(
            classified.count,
            0,
            "Expected port-mapped or heuristic services in live sample"
        )
    }
    #endif

    func testPortParsingServiceNames() {
        XCTAssertEqual(SocketServiceClassifier.portNumber(from: "*:irc"), 6667)
        XCTAssertEqual(SocketServiceClassifier.portNumber(from: "10.0.0.4:https"), 443)
    }

    func testSocketServiceHintsPreferWellKnownPeerPort() {
        let web = VisibleSocket(
            processName: "browser",
            pid: 42,
            localEndpoint: "10.0.0.4:51000",
            remoteEndpoint: "203.0.113.5:443",
            state: .established
        )
        XCTAssertEqual(web.serviceHint.label, "HTTPS/TLS")
        XCTAssertEqual(web.serviceHint.confidence, .portMapped)
    }

    func testIRCAndRTPHeuristics() {
        let irc = VisibleSocket(
            processName: "chat",
            pid: 1,
            localEndpoint: "10.0.0.4:51001",
            remoteEndpoint: "198.51.100.2:6697",
            state: .established
        )
        XCTAssertEqual(irc.serviceHint.label, "IRC")
        XCTAssertEqual(irc.serviceHint.confidence, .portMapped)

        let ircListen = VisibleSocket(
            processName: "chatd",
            pid: 2,
            localEndpoint: "0.0.0.0:6697",
            remoteEndpoint: nil,
            state: .listening
        )
        XCTAssertEqual(ircListen.serviceHint.label, "IRC")

        let rtpStatic = VisibleSocket(
            transport: .udp,
            processName: "player",
            pid: 3,
            localEndpoint: "10.0.0.4:51002",
            remoteEndpoint: "203.0.113.6:5004",
            state: .datagram
        )
        XCTAssertEqual(rtpStatic.serviceHint.label, "RTP/RTCP")

        let rtpHighPort = VisibleSocket(
            transport: .udp,
            processName: "meeting",
            pid: 4,
            localEndpoint: "10.0.0.4:51003",
            remoteEndpoint: "203.0.113.7:24128",
            state: .datagram
        )
        XCTAssertEqual(rtpHighPort.serviceHint.label, "UNCLASSIFIED")
    }

    func testIRCClientsOnPort443UseProcessIdentity() {
        let cases: [(processName: String, pid: Int)] = [
            ("limechat", 99),
            ("Nudge", 4242),
            ("/Applications/Nudge.app/Contents/MacOS/Nudge", 4243),
        ]
        for item in cases {
            let socket = VisibleSocket(
                processName: item.processName,
                pid: item.pid,
                localEndpoint: "192.168.1.10:51234",
                remoteEndpoint: "irc.example.com:443",
                state: .established
            )
            XCTAssertEqual(socket.serviceHint.label, "IRC/TLS", item.processName)
            XCTAssertEqual(socket.serviceHint.confidence, .portMapped, item.processName)
        }
    }

    func testPortParsingZoneScopedIPv6() {
        XCTAssertEqual(SocketServiceClassifier.portNumber(from: "fe80::1%en0:443"), 443)
    }

    func testUnclassifiedEphemeralUDP() {
        let unknown = VisibleSocket(
            transport: .udp,
            processName: "unknown",
            pid: 5,
            localEndpoint: "10.0.0.4:51004",
            remoteEndpoint: "203.0.113.8:39999",
            state: .datagram
        )
        XCTAssertEqual(unknown.serviceHint.label, "UNCLASSIFIED")
    }

    func testADBListenPort5037() {
        let adb = VisibleSocket(
            processName: "adb",
            pid: 6,
            localEndpoint: "127.0.0.1:5037",
            remoteEndpoint: nil,
            state: .listening
        )
        XCTAssertEqual(adb.serviceHint.label, "ADB")
    }

    func testCoreDeviceServiceEphemeralPort() {
        let link = VisibleSocket(
            processName: "CoreDeviceService",
            pid: 7,
            localEndpoint: "[fd53:2624:dd25::2]:54659",
            remoteEndpoint: "[fd53:2624:dd25::1]:64352",
            state: .established
        )
        XCTAssertEqual(link.serviceHint.label, "APPLE-DEVICE")
    }

    func testControlCenterAirPlayListenPorts() {
        let cc = VisibleSocket(
            processName: "ControlCenter",
            pid: 8,
            localEndpoint: "*:5000",
            remoteEndpoint: nil,
            state: .listening
        )
        XCTAssertEqual(cc.serviceHint.label, "AIRPLAY")
    }
}
