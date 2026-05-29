import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if os(macOS)
import Darwin
import SystemConfiguration
#endif

public protocol MetricCollecting: Sendable {
    func collect() async throws -> PerformanceMetrics
}

public enum MetricCollectionError: Error {
    case unsupportedPlatform
}

private actor InternetLatencyProbe {
    static let shared = InternetLatencyProbe()

    private let endpoint = URL(string: "https://cp.cloudflare.com/generate_204")!
    private var cached: (sampledAt: ContinuousClock.Instant, milliseconds: Double?)?
    private var inFlight: Task<Double?, Never>?

    func sample(maxAge: Duration) async -> Double? {
        guard CollectionPreferences.isInternetLatencyProbeEnabled else {
            return nil
        }
        let clock = ContinuousClock()
        if let cached, cached.sampledAt.duration(to: clock.now) < maxAge {
            return cached.milliseconds
        }
        if let inFlight {
            return await inFlight.value
        }

        let endpoint = endpoint
        let task = Task { await Self.measure(endpoint: endpoint) }
        inFlight = task
        let milliseconds = await task.value
        cached = (clock.now, milliseconds)
        inFlight = nil
        return milliseconds
    }

    private nonisolated static func measure(endpoint: URL) async -> Double? {
        #if os(Linux)
        return measureLinuxWithCurl(endpoint: endpoint)
        #else
        var request = URLRequest(url: endpoint)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 2
        request.setValue("SystemInsights/0.1 latency-probe", forHTTPHeaderField: "User-Agent")

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 2
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: configuration)
        let clock = ContinuousClock()
        let startedAt = clock.now
        do {
            let (_, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse, (200..<400).contains(response.statusCode) else {
                return nil
            }
            let elapsed = startedAt.duration(to: clock.now).components
            let seconds = Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
            return (seconds * 1_000).rounded()
        } catch {
            return nil
        }
        #endif
    }

    #if os(Linux)
    /// swift-corelibs-foundation ``URLSession`` can crash on deinit (`_MultiHandle` retain bug) inside Flatpak/GTK.
    private nonisolated static func measureLinuxWithCurl(endpoint: URL) -> Double? {
        guard let curl = LinuxSandboxAdaptation.firstExecutable([
            "/usr/bin/curl",
            "/bin/curl"
        ]) else {
            return nil
        }

        guard let output = CommandRunner.run(
            curl,
            arguments: [
                "--silent",
                "--fail",
                "--location",
                "--output", "/dev/null",
                "--write-out", "%{time_total}",
                "--max-time", "2",
                "--user-agent", "SystemInsights/0.1 latency-probe",
                endpoint.absoluteString
            ],
            timeout: 3
        ), output.exitCode == 0 else {
            return nil
        }

        let trimmed = output.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let seconds = Double(trimmed), seconds > 0 else { return nil }
        return (seconds * 1_000).rounded()
    }
    #endif
}

public struct SystemMetricCollector: MetricCollecting {
    public init() {}

    public func collect() async throws -> PerformanceMetrics {
        #if os(macOS)
        async let cpuLoadPercent = macOSCPULoad()
        async let network = collectNetworkMetrics()
        return PerformanceMetrics(
            cpuLoadPercent: try await cpuLoadPercent,
            memoryPressurePercent: macOSMemoryPressure(),
            diskUsagePercent: diskUsage(),
            network: try await network,
            topProcesses: topProcesses(arguments: ["-Ao", "pid=,pcpu=,pmem=,comm=", "-r"])
        )
        #elseif os(Linux)
        async let cpuLoadPercent = linuxCPULoad()
        async let network = collectNetworkMetrics()
        return PerformanceMetrics(
            cpuLoadPercent: try await cpuLoadPercent,
            memoryPressurePercent: linuxMemoryPressure(),
            diskUsagePercent: diskUsage(),
            network: try await network,
            topProcesses: topProcesses(arguments: ["-eo", "pid=,pcpu=,pmem=,comm=", "--sort=-pcpu"])
        )
        #else
        throw MetricCollectionError.unsupportedPlatform
        #endif
    }

    public func collectNetworkMetrics() async throws -> NetworkMetrics {
        #if os(macOS)
        return try await macOSNetworkMetrics()
        #elseif os(Linux)
        return try await linuxNetworkMetrics()
        #else
        throw MetricCollectionError.unsupportedPlatform
        #endif
    }

    public func collectLiveNetworkMetrics(preserving status: NetworkMetrics = .unavailable) async throws -> NetworkMetrics {
        try await collectLiveNetworkMetrics(
            inputs: LiveNetworkSampleInputs(preserving: status)
        )
    }

    public func collectLiveNetworkMetrics(inputs: LiveNetworkSampleInputs) async throws -> NetworkMetrics {
        let activeTCP = inputs.establishedTCPCount ?? inputs.preserving.activeTCPConnections
        let vpn: VPNConnectivity
        if inputs.refreshVPN {
            #if os(macOS)
            vpn = await macOSVPNConnectivity()
            #elseif os(Linux)
            vpn = linuxVPNConnectivity()
            #else
            vpn = inputs.preserving.vpn
            #endif
            await NetworkPathObservationService.shared.noteVPNRefreshed()
        } else {
            vpn = inputs.preserving.vpn
        }

        #if os(macOS)
        let interface = macOSDefaultInterface() ?? macOSActiveInterface()
        let first = interface.flatMap(macOSNetworkCounters)
        async let latency = InternetLatencyProbe.shared.sample(maxAge: .seconds(5))
        let clock = ContinuousClock()
        let startedAt = clock.now
        try await Task.sleep(for: .milliseconds(250))
        let elapsed = startedAt.duration(to: clock.now).components
        let interval = max(Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18, 0.001)
        let second = interface.flatMap(macOSNetworkCounters)
        return NetworkMetrics(
            interfaceName: interface,
            receivedBytesPerSecond: byteRate(from: first?.received, to: second?.received, interval: interval),
            sentBytesPerSecond: byteRate(from: first?.sent, to: second?.sent, interval: interval),
            latencyMilliseconds: await latency,
            activeTCPConnections: activeTCP,
            vpn: vpn
        )
        #elseif os(Linux)
        let interface = linuxDefaultInterface()
        let first = interface.flatMap(linuxNetworkCounters)
        async let latency = InternetLatencyProbe.shared.sample(maxAge: .seconds(5))
        let clock = ContinuousClock()
        let startedAt = clock.now
        try await Task.sleep(for: .milliseconds(250))
        let elapsed = startedAt.duration(to: clock.now).components
        let interval = max(Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18, 0.001)
        let second = interface.flatMap(linuxNetworkCounters)
        return NetworkMetrics(
            interfaceName: interface,
            receivedBytesPerSecond: byteRate(from: first?.received, to: second?.received, interval: interval),
            sentBytesPerSecond: byteRate(from: first?.sent, to: second?.sent, interval: interval),
            latencyMilliseconds: await latency,
            activeTCPConnections: activeTCP,
            vpn: vpn
        )
        #else
        throw MetricCollectionError.unsupportedPlatform
        #endif
    }

    public func collectVisibleTCPConnections() async -> [VisibleSocket] {
        #if os(macOS)
        guard let output = CommandRunner.run(
            "/usr/sbin/lsof",
            arguments: ["-nP", "-a", "-iTCP", "-sTCP:ESTABLISHED,LISTEN", "-FpcfnPT"],
            timeout: 2
        ), output.exitCode == 0 else {
            return []
        }
        return Self.parseMacOSVisibleTCPConnections(output.stdout)
        #elseif os(Linux)
        let executable = LinuxSandboxAdaptation.firstExecutable([
            "/usr/sbin/ss", "/usr/bin/ss", "/bin/ss"
        ])
        guard let executable,
              let output = CommandRunner.run(
                executable,
                arguments: ["-H", "-t", "-n", "-a", "-p"],
                timeout: 2
              ), output.exitCode == 0 else {
            return []
        }
        return Self.parseLinuxVisibleTCPConnections(output.stdout)
        #else
        return []
        #endif
    }

    public func collectVisibleSockets() async -> [VisibleSocket] {
        #if os(macOS)
        guard let output = CommandRunner.run(
            "/usr/sbin/lsof",
            arguments: ["-nP", "-iTCP", "-sTCP:ESTABLISHED,LISTEN", "-iUDP", "-FpcfnPT"],
            timeout: 2
        ), output.exitCode == 0 else {
            return []
        }
        return Self.parseMacOSVisibleSockets(output.stdout)
        #elseif os(Linux)
        let executable = LinuxSandboxAdaptation.firstExecutable([
            "/usr/sbin/ss", "/usr/bin/ss", "/bin/ss"
        ])
        guard let executable else { return [] }
        let tcpOutput = CommandRunner.run(
            executable,
            arguments: ["-H", "-t", "-n", "-a", "-p"],
            timeout: 2
        )
        let udpOutput = CommandRunner.run(
            executable,
            arguments: ["-H", "-u", "-n", "-a", "-p"],
            timeout: 2
        )
        return Self.parseLinuxVisibleSockets(
            tcpText: tcpOutput?.exitCode == 0 ? tcpOutput?.stdout ?? "" : "",
            udpText: udpOutput?.exitCode == 0 ? udpOutput?.stdout ?? "" : ""
        )
        #else
        return await collectVisibleTCPConnections()
        #endif
    }

    private func diskUsage() -> Double {
        #if os(Linux)
        if let usage = LinuxSandboxDiagnostics.probeDiskUsagePercent() {
            return usage
        }
        return 0
        #else
        let path = NSHomeDirectory()
        guard
            let attributes = try? FileManager.default.attributesOfFileSystem(forPath: path),
            let size = (attributes[.systemSize] as? NSNumber)?.doubleValue,
            let free = (attributes[.systemFreeSize] as? NSNumber)?.doubleValue,
            size > 0
        else {
            return 0
        }

        return percentage((size - free) / size)
        #endif
    }

    private func topProcesses(arguments: [String]) -> [ProcessMetric] {
        guard let output = CommandRunner.run("/bin/ps", arguments: arguments) else {
            return []
        }

        return output.stdout
            .split(whereSeparator: \.isNewline)
            .compactMap { line -> ProcessMetric? in
                let fields = line.split(maxSplits: 3, omittingEmptySubsequences: true) { $0.isWhitespace }
                guard
                    fields.count == 4,
                    let pid = Int(fields[0]),
                    pid != Int(ProcessInfo.processInfo.processIdentifier),
                    let cpu = Double(fields[1]),
                    let memory = Double(fields[2])
                else {
                    return nil
                }

                return ProcessMetric(
                    pid: pid,
                    name: String(fields[3]),
                    cpuPercent: cpu,
                    memoryPercent: memory
                )
            }
            .prefix(5)
            .map { $0 }
    }

    #if os(macOS)
    private func macOSCPULoad() async throws -> Double {
        guard let first = macOSCPUCounters() else { return 0 }
        try await Task.sleep(for: .milliseconds(150))
        guard let second = macOSCPUCounters() else { return 0 }

        let totalDelta = second.total - first.total
        let idleDelta = second.idle - first.idle
        return totalDelta > 0 ? percentage((totalDelta - idleDelta) / totalDelta) : 0
    }

    private func macOSCPUCounters() -> (total: Double, idle: Double)? {
        var processorCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &info,
            &infoCount
        )
        guard result == KERN_SUCCESS, let info else { return nil }
        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(UInt(bitPattern: info)),
                vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.stride)
            )
        }

        var total: UInt64 = 0
        var idle: UInt64 = 0
        for processor in 0..<Int(processorCount) {
            let base = processor * Int(CPU_STATE_MAX)
            for state in 0..<Int(CPU_STATE_MAX) {
                total += UInt64(info[base + state])
            }
            idle += UInt64(info[base + Int(CPU_STATE_IDLE)])
        }
        return (Double(total), Double(idle))
    }

    private func macOSMemoryPressure() -> Double {
        var statistics = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )
        let result = withUnsafeMutablePointer(to: &statistics) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPointer, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }

        var pageSize: vm_size_t = 0
        guard host_page_size(mach_host_self(), &pageSize) == KERN_SUCCESS else {
            return 0
        }

        let usedPages = Double(
            statistics.active_count + statistics.wire_count + statistics.compressor_page_count
        )
        let totalBytes = Double(ProcessInfo.processInfo.physicalMemory)
        return totalBytes > 0 ? percentage((usedPages * Double(pageSize)) / totalBytes) : 0
    }

    private func macOSNetworkMetrics() async throws -> NetworkMetrics {
        await NetworkPathObservationService.shared.ensureRunning()
        let interface = macOSDefaultInterface() ?? macOSActiveInterface()
        let first = interface.flatMap(macOSNetworkCounters)
        async let vpn = macOSVPNConnectivity()
        async let latency = InternetLatencyProbe.shared.sample(maxAge: .seconds(30))
        let clock = ContinuousClock()
        let startedAt = clock.now
        try await Task.sleep(for: .milliseconds(250))
        let elapsed = startedAt.duration(to: clock.now).components
        let interval = max(Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18, 0.001)
        let second = interface.flatMap(macOSNetworkCounters)
        let vpnValue = await vpn
        await NetworkPathObservationService.shared.noteVPNRefreshed()

        return NetworkMetrics(
            interfaceName: interface,
            receivedBytesPerSecond: byteRate(from: first?.received, to: second?.received, interval: interval),
            sentBytesPerSecond: byteRate(from: first?.sent, to: second?.sent, interval: interval),
            latencyMilliseconds: await latency,
            activeTCPConnections: macOSActiveTCPConnections(),
            vpn: vpnValue
        )
    }

    private func macOSDefaultInterface() -> String? {
        guard let store = SCDynamicStoreCreate(nil, "SystemInsights" as CFString, nil, nil) else {
            return nil
        }
        let keys = ["State:/Network/Global/IPv4", "State:/Network/Global/IPv6"]
        for key in keys {
            guard
                let value = SCDynamicStoreCopyValue(store, key as CFString) as? [String: Any],
                let interface = value[kSCDynamicStorePropNetPrimaryInterface as String] as? String
            else {
                continue
            }
            return interface
        }
        return nil
    }

    private func macOSActiveInterface() -> String? {
        var addresses: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addresses) == 0, let firstAddress = addresses else { return nil }
        defer { freeifaddrs(firstAddress) }

        var candidates: [(name: String, traffic: UInt64)] = []
        var current: UnsafeMutablePointer<ifaddrs>? = firstAddress
        while let address = current {
            defer { current = address.pointee.ifa_next }
            let flags = Int32(address.pointee.ifa_flags)
            guard
                flags & IFF_UP != 0,
                flags & IFF_RUNNING != 0,
                let socketAddress = address.pointee.ifa_addr,
                Int32(socketAddress.pointee.sa_family) == AF_LINK,
                let data = address.pointee.ifa_data
            else {
                continue
            }

            let name = String(cString: address.pointee.ifa_name)
            guard
                name != "lo0",
                !name.hasPrefix("utun"),
                !name.hasPrefix("awdl"),
                !name.hasPrefix("llw")
            else {
                continue
            }

            let counters = data.assumingMemoryBound(to: if_data.self).pointee
            candidates.append((name, UInt64(counters.ifi_ibytes) + UInt64(counters.ifi_obytes)))
        }
        return candidates.max(by: { $0.traffic < $1.traffic })?.name
    }

    private func macOSNetworkCounters(for interface: String) -> (received: Double, sent: Double)? {
        var addresses: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addresses) == 0, let firstAddress = addresses else { return nil }
        defer { freeifaddrs(firstAddress) }

        var current: UnsafeMutablePointer<ifaddrs>? = firstAddress
        while let address = current {
            defer { current = address.pointee.ifa_next }
            guard
                String(cString: address.pointee.ifa_name) == interface,
                let data = address.pointee.ifa_data
            else {
                continue
            }
            let counters = data.assumingMemoryBound(to: if_data.self).pointee
            return (Double(counters.ifi_ibytes), Double(counters.ifi_obytes))
        }
        return nil
    }

    private func macOSActiveTCPConnections() -> Int {
        guard let output = CommandRunner.run("/usr/sbin/netstat", arguments: ["-an", "-p", "tcp"]) else {
            return 0
        }
        return output.stdout.split(whereSeparator: \.isNewline)
            .filter { $0.contains("ESTABLISHED") }
            .count
    }

    private func macOSVPNConnectivity() async -> VPNConnectivity {
        await NetworkPathObservationService.shared.ensureRunning()
        let connectionText = CommandRunner.run("/usr/sbin/scutil", arguments: ["--nc", "list"])?.stdout
        let routedTunnelInterfaces = await NetworkPathObservationService.shared.routedTunnelInterfaces()
        return Self.resolveMacOSVPNConnectivity(
            connectionText: connectionText,
            routedTunnelInterfaces: routedTunnelInterfaces
        )
    }

    static func resolveMacOSVPNConnectivity(
        connectionText: String?,
        routedTunnelInterfaces: [String]
    ) -> VPNConnectivity {
        if let line = connectionText?
            .split(whereSeparator: \.isNewline)
            .first(where: { $0.contains("(Connected)") }) {
            return VPNConnectivity(
                state: .connected,
                serviceName: quotedValue(in: String(line)),
                activeInterfaces: Array(routedTunnelInterfaces.prefix(4)),
                detail: "A configured macOS VPN service reports a connected state."
            )
        }

        if !routedTunnelInterfaces.isEmpty {
            return VPNConnectivity(
                state: .tunnelDetected,
                activeInterfaces: Array(routedTunnelInterfaces.prefix(4)),
                detail: "The active network path uses \(routedTunnelInterfaces.joined(separator: ", ")); this is typically a VPN or privacy tunnel."
            )
        }

        if let line = connectionText?
            .split(whereSeparator: \.isNewline)
            .first(where: { $0.contains("[VPN:") }),
           let name = quotedValue(in: String(line)) {
            return VPNConnectivity(
                state: .notDetected,
                serviceName: name,
                detail: "Configured VPN \"\(name)\" reports that it is not connected."
            )
        }

        if connectionText != nil {
            return VPNConnectivity(
                state: .notDetected,
                detail: "No connected VPN service or routed tunnel was detected."
            )
        }
        return .unavailable
    }

    private static func quotedValue(in text: String) -> String? {
        guard let first = text.firstIndex(of: "\""),
              let last = text.lastIndex(of: "\""),
              first < last else {
            return nil
        }
        return String(text[text.index(after: first)..<last])
    }

    static func parseMacOSVisibleSockets(_ text: String) -> [VisibleSocket] {
        var processName = ""
        var pid: Int?
        var endpoint: String?
        var transport: NetworkTransport?
        var state: VisibleSocketState?
        var connections: [String: VisibleSocket] = [:]

        func appendPendingConnection() {
            guard connections.count < NetworkSamplingLimits.maxVisibleSockets else { return }
            guard let pid, !processName.isEmpty, let endpoint, let transport, let state else { return }
            let arrow = endpoint.range(of: "->")
            let local: String
            let remote: String?
            if let arrow {
                local = String(endpoint[..<arrow.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                remote = String(endpoint[arrow.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                local = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
                remote = nil
            }
            let connection = VisibleSocket(
                transport: transport,
                processName: processName,
                pid: pid,
                localEndpoint: local,
                remoteEndpoint: remote?.isEmpty == true ? nil : remote,
                state: state
            )
            connections[connection.id] = connection
        }

        for line in text.split(whereSeparator: \.isNewline).map(String.init) {
            if line.hasPrefix("p") {
                appendPendingConnection()
                endpoint = nil
                transport = nil
                state = nil
                pid = Int(line.dropFirst())
                processName = ""
            } else if line.hasPrefix("c") {
                processName = String(line.dropFirst())
            } else if line.hasPrefix("f") {
                appendPendingConnection()
                endpoint = nil
                transport = nil
                state = nil
            } else if line == "PTCP" {
                transport = .tcp
            } else if line == "PUDP" {
                transport = .udp
                state = .datagram
            } else if line.hasPrefix("n") {
                endpoint = String(line.dropFirst())
            } else if line == "TST=ESTABLISHED" {
                state = .established
            } else if line == "TST=LISTEN" {
                state = .listening
            }
        }
        appendPendingConnection()

        return connections.values.sorted {
            if $0.transport != $1.transport {
                return $0.transport == .tcp
            }
            if $0.state != $1.state {
                return $0.state == .established || ($0.state == .listening && $1.state == .datagram)
            }
            if $0.processName != $1.processName {
                return $0.processName < $1.processName
            }
            return $0.localEndpoint < $1.localEndpoint
        }
        .prefix(NetworkSamplingLimits.maxVisibleSockets)
        .map { $0 }
    }

    static func parseMacOSVisibleTCPConnections(_ text: String) -> [VisibleSocket] {
        parseMacOSVisibleSockets(text).filter { $0.transport == .tcp }
    }
    #endif

    #if os(Linux)
    private func linuxCPULoad() async throws -> Double {
        guard let first = linuxCPUCounters() else { return 0 }
        try await Task.sleep(for: .milliseconds(150))
        guard let second = linuxCPUCounters() else { return 0 }

        let totalDelta = second.total - first.total
        let idleDelta = second.idle - first.idle
        return totalDelta > 0 ? percentage((totalDelta - idleDelta) / totalDelta) : 0
    }

    private func linuxCPUCounters() -> (total: Double, idle: Double)? {
        guard
            let contents = LinuxSandboxAdaptation.procFileContents("stat"),
            let cpuLine = contents.split(whereSeparator: \.isNewline).first
        else {
            return nil
        }

        let counters = cpuLine.split(whereSeparator: \.isWhitespace).dropFirst().compactMap { Double($0) }
        guard counters.count >= 5 else { return nil }
        return (counters.reduce(0, +), counters[3] + counters[4])
    }

    private func linuxMemoryPressure() -> Double {
        guard let contents = LinuxSandboxAdaptation.procFileContents("meminfo") else {
            return 0
        }

        var values: [String: Double] = [:]
        contents.split(whereSeparator: \.isNewline).forEach { line in
            let fields = line.split(separator: ":", maxSplits: 1)
            guard fields.count == 2 else { return }
            values[String(fields[0])] = firstNumber(in: String(fields[1])) ?? 0
        }

        guard let total = values["MemTotal"], let available = values["MemAvailable"], total > 0 else {
            return 0
        }
        return percentage((total - available) / total)
    }

    private func linuxNetworkMetrics() async throws -> NetworkMetrics {
        let interface = linuxDefaultInterface()
        let first = interface.flatMap(linuxNetworkCounters)
        async let latency = InternetLatencyProbe.shared.sample(maxAge: .seconds(30))
        let clock = ContinuousClock()
        let startedAt = clock.now
        try await Task.sleep(for: .milliseconds(250))
        let elapsed = startedAt.duration(to: clock.now).components
        let interval = max(Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18, 0.001)
        let second = interface.flatMap(linuxNetworkCounters)

        return NetworkMetrics(
            interfaceName: interface,
            receivedBytesPerSecond: byteRate(from: first?.received, to: second?.received, interval: interval),
            sentBytesPerSecond: byteRate(from: first?.sent, to: second?.sent, interval: interval),
            latencyMilliseconds: await latency,
            activeTCPConnections: linuxActiveTCPConnections(),
            vpn: linuxVPNConnectivity()
        )
    }

    private func linuxDefaultInterface() -> String? {
        guard let contents = LinuxSandboxAdaptation.procFileContents("net/route") else {
            return nil
        }
        return contents.split(whereSeparator: \.isNewline).dropFirst().compactMap { (line: Substring) -> String? in
            let fields = line.split(whereSeparator: \.isWhitespace)
            guard fields.count > 3, fields[1] == "00000000" else { return nil }
            return String(fields[0])
        }.first
    }

    private func linuxNetworkCounters(for interface: String) -> (received: Double, sent: Double)? {
        guard let contents = LinuxSandboxAdaptation.procFileContents("net/dev") else {
            return nil
        }
        for line in contents.split(whereSeparator: \.isNewline) {
            let sides = line.split(separator: ":", maxSplits: 1)
            guard sides.count == 2,
                  sides[0].trimmingCharacters(in: .whitespaces) == interface else {
                continue
            }
            let values = sides[1].split(whereSeparator: \.isWhitespace).compactMap { Double($0) }
            guard values.count > 8 else { return nil }
            return (values[0], values[8])
        }
        return nil
    }

    private func linuxActiveTCPConnections() -> Int {
        ["net/tcp", "net/tcp6"].reduce(0) { count, path in
            guard let contents = LinuxSandboxAdaptation.procFileContents(path) else { return count }
            let established = contents.split(whereSeparator: \.isNewline).dropFirst().filter { line in
                let fields = line.split(whereSeparator: \.isWhitespace)
                return fields.count > 3 && fields[3] == "01"
            }.count
            return count + established
        }
    }

    private func linuxVPNConnectivity() -> VPNConnectivity {
        let netDirectory = LinuxSandboxAdaptation.sysClassNetDirectory
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: netDirectory) else {
            return .unavailable
        }

        let interfaces = names.filter { name in
            let isTunnel = ["tun", "tap", "wg", "ppp", "tailscale", "nordlynx"].contains { name.hasPrefix($0) }
            let statePath = "\(netDirectory)/\(name)/operstate"
            let state = try? String(contentsOfFile: statePath, encoding: .utf8)
            return isTunnel && state?.trimmingCharacters(in: .whitespacesAndNewlines) != "down"
        }
        if !interfaces.isEmpty {
            return VPNConnectivity(
                state: .tunnelDetected,
                activeInterfaces: interfaces.sorted(),
                detail: "Active Linux tunnel interfaces were detected; verify the intended VPN service."
            )
        }
        return VPNConnectivity(
            state: .notDetected,
            detail: "No active Linux tunnel interface was detected."
        )
    }
    #endif

    private func percentages(in text: String) -> [Double] {
        guard let expression = try? NSRegularExpression(pattern: #"([0-9]+(?:\.[0-9]+)?)%"#) else {
            return []
        }
        let range = NSRange(text.startIndex..., in: text)
        return expression.matches(in: text, range: range).compactMap { match in
            guard let range = Range(match.range(at: 1), in: text) else { return nil }
            return Double(text[range])
        }
    }

    private func firstNumber(in text: String) -> Double? {
        guard let expression = try? NSRegularExpression(pattern: #"[0-9]+(?:\.[0-9]+)?"#) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = expression.firstMatch(in: text, range: range),
              let valueRange = Range(match.range, in: text) else {
            return nil
        }
        return Double(text[valueRange])
    }

    private func percentage(_ ratio: Double) -> Double {
        let value = max(0, min(100, ratio * 100))
        return (value * 10).rounded() / 10
    }

    private func byteRate(from first: Double?, to second: Double?, interval: TimeInterval) -> Double {
        guard let first, let second, second >= first else { return 0 }
        return ((second - first) / interval).rounded()
    }

    static func parseLinuxVisibleTCPConnections(_ text: String) -> [VisibleSocket] {
        var connections: [String: VisibleSocket] = [:]

        for line in text.split(whereSeparator: \.isNewline).map(String.init) {
            let fields = line.split(whereSeparator: \.isWhitespace).map(String.init)
            guard fields.count >= 5 else { continue }

            let state: VisibleSocketState
            switch fields[0].uppercased() {
            case "ESTAB", "ESTABLISHED": state = .established
            case "LISTEN": state = .listening
            default: continue
            }

            let ownership = linuxSocketOwnership(in: line)
            let connection = VisibleSocket(
                processName: ownership.processName,
                pid: ownership.pid,
                localEndpoint: fields[3],
                remoteEndpoint: state == .established ? fields[4] : nil,
                state: state
            )
            connections[connection.id] = connection
        }

        return connections.values.sorted {
            if $0.state != $1.state {
                return $0.state == .established
            }
            if $0.processName != $1.processName {
                return $0.processName < $1.processName
            }
            return $0.localEndpoint < $1.localEndpoint
        }
    }

    static func parseLinuxVisibleUDPSockets(_ text: String) -> [VisibleSocket] {
        var sockets: [String: VisibleSocket] = [:]

        for line in text.split(whereSeparator: \.isNewline).map(String.init) {
            let fields = line.split(whereSeparator: \.isWhitespace).map(String.init)
            guard fields.count >= 5 else { continue }

            let ownership = linuxSocketOwnership(in: line)
            let peer = fields[4]
            let socket = VisibleSocket(
                transport: .udp,
                processName: ownership.processName,
                pid: ownership.pid,
                localEndpoint: fields[3],
                remoteEndpoint: isWildcardPeer(peer) ? nil : peer,
                state: .datagram
            )
            sockets[socket.id] = socket
        }

        return sockets.values.sorted {
            if $0.processName != $1.processName {
                return $0.processName < $1.processName
            }
            return $0.localEndpoint < $1.localEndpoint
        }
    }

    static func parseLinuxVisibleSockets(tcpText: String, udpText: String) -> [VisibleSocket] {
        parseLinuxVisibleTCPConnections(tcpText) + parseLinuxVisibleUDPSockets(udpText)
    }

    private static func isWildcardPeer(_ endpoint: String) -> Bool {
        endpoint == "*:*" || endpoint.hasSuffix(":*") || endpoint == "0.0.0.0:0" || endpoint == "[::]:0"
    }

    private static func linuxSocketOwnership(in line: String) -> (processName: String, pid: Int) {
        guard let expression = try? NSRegularExpression(pattern: #"\(\("([^"]+)",pid=([0-9]+)"#) else {
            return ("unattributed", 0)
        }
        let range = NSRange(line.startIndex..., in: line)
        guard let match = expression.firstMatch(in: line, range: range),
              let nameRange = Range(match.range(at: 1), in: line),
              let pidRange = Range(match.range(at: 2), in: line),
              let pid = Int(line[pidRange]) else {
            return ("unattributed", 0)
        }
        return (String(line[nameRange]), pid)
    }

}

public struct MockMetricCollector: MetricCollecting {
    private let metrics: PerformanceMetrics

    public init(metrics: PerformanceMetrics = PerformanceMetrics(
        cpuLoadPercent: 82.0,
        memoryPressurePercent: 71.0,
        diskUsagePercent: 64.0,
        network: NetworkMetrics(
            interfaceName: "en0",
            receivedBytesPerSecond: 1_420_000,
            sentBytesPerSecond: 248_000,
            latencyMilliseconds: 28,
            activeTCPConnections: 14,
            vpn: VPNConnectivity(
                state: .connected,
                serviceName: "Work VPN",
                activeInterfaces: ["utun4"],
                detail: "A configured VPN connection is active."
            )
        ),
        topProcesses: [
            ProcessMetric(pid: 101, name: "video-renderer", cpuPercent: 81, memoryPercent: 18),
            ProcessMetric(pid: 102, name: "browser", cpuPercent: 24, memoryPercent: 11)
        ]
    )) {
        self.metrics = metrics
    }

    public func collect() async throws -> PerformanceMetrics {
        metrics
    }
}
