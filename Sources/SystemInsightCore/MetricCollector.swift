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
        let counters = interface.flatMap { linuxNetworkCounters(for: $0) }
        async let latency = InternetLatencyProbe.shared.sample(maxAge: .seconds(5))
        let rates = await LinuxNetworkRateTracker.shared.rates(
            interface: interface,
            received: counters?.received,
            sent: counters?.sent
        )
        if let interface, let counters {
            Self.logLinuxNetworkProofOnce(
                interface: interface,
                receivedTotal: counters.received,
                sentTotal: counters.sent,
                receivedRate: rates.received,
                sentRate: rates.sent
            )
        }
        return NetworkMetrics(
            interfaceName: interface,
            receivedBytesPerSecond: rates.received,
            sentBytesPerSecond: rates.sent,
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
        return linuxCollectVisibleSocketsUnified().filter { $0.transport == .tcp }
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
        return linuxCollectVisibleSocketsUnified()
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
        if let fromRoute = linuxDefaultInterfaceFromRoute() {
            return fromRoute
        }
        return linuxDefaultInterfaceFromNetDev()
    }

    private func linuxDefaultInterfaceFromRoute() -> String? {
        guard let contents = LinuxSandboxAdaptation.networkProcFileContents("net/route") else {
            return nil
        }
        return contents.split(whereSeparator: \.isNewline).dropFirst().compactMap { (line: Substring) -> String? in
            let fields = line.split(whereSeparator: \.isWhitespace)
            guard fields.count > 3, fields[1] == "00000000" else { return nil }
            return String(fields[0])
        }.first
    }

    private func linuxDefaultInterfaceFromNetDev() -> String? {
        guard let contents = LinuxSandboxAdaptation.networkProcFileContents("net/dev") else {
            return nil
        }
        var best: (name: String, traffic: Double)?
        for line in contents.split(whereSeparator: \.isNewline).dropFirst() {
            let sides = line.split(separator: ":", maxSplits: 1)
            guard sides.count == 2 else { continue }
            let name = sides[0].trimmingCharacters(in: .whitespaces)
            guard name != "lo" else { continue }
            let values = sides[1].split(whereSeparator: \.isWhitespace).compactMap { Double($0) }
            guard values.count > 8 else { continue }
            let traffic = values[0] + values[8]
            if best == nil || traffic > best!.traffic {
                best = (name, traffic)
            }
        }
        return best?.name
    }

    private func linuxNetworkCounters(for interface: String) -> (received: Double, sent: Double)? {
        guard let contents = LinuxSandboxAdaptation.networkProcFileContents("net/dev") else {
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
            guard let contents = LinuxSandboxAdaptation.networkProcFileContents(path) else { return count }
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

    private func linuxCollectVisibleSocketsUnified() -> [VisibleSocket] {
        if LinuxSandboxAdaptation.isFlatpak {
            let viaSS = linuxCollectVisibleSocketsViaSS()
            if !viaSS.isEmpty {
                Self.linuxLogSocketProbe("flatpak host ss returned \(viaSS.count) sockets")
                return viaSS
            }
            let viaProc = linuxCollectVisibleSocketsViaProc(owners: [:])
            Self.linuxLogSocketProbe("flatpak proc returned \(viaProc.count) sockets (ss empty)")
            return viaProc
        }

        var merged: [String: VisibleSocket] = [:]
        let owners = linuxBuildSocketInodeOwnerMap()

        for socket in linuxCollectVisibleSocketsViaSS() {
            merged[socket.id] = socket
        }
        if !merged.isEmpty {
            Self.linuxLogSocketProbe("merged inventory \(merged.count) sockets")
            return merged.values.sorted {
                if $0.transport != $1.transport { return $0.transport == .tcp }
                return $0.localEndpoint < $1.localEndpoint
            }
            .prefix(NetworkSamplingLimits.maxVisibleSockets)
            .map { $0 }
        }

        let viaProc = linuxCollectVisibleSocketsViaProc(owners: owners)
        Self.linuxLogSocketProbe("proc fallback returned \(viaProc.count) sockets (inode map=\(owners.count))")
        return viaProc
    }

    private func linuxCollectVisibleSocketsViaSS() -> [VisibleSocket] {
        guard let executable = LinuxSandboxAdaptation.firstExecutable([
            "/usr/sbin/ss", "/usr/bin/ss", "/bin/ss"
        ]) else {
            Self.linuxLogSocketProbe("ss executable not found")
            return []
        }
        let tcpOutput = CommandRunner.run(
            executable,
            arguments: ["-H", "-t", "-n", "-a", "-p"],
            timeout: 3
        )
        let udpOutput = CommandRunner.run(
            executable,
            arguments: ["-H", "-u", "-n", "-a", "-p"],
            timeout: 3
        )
        if tcpOutput == nil && udpOutput == nil {
            Self.linuxLogSocketProbe("ss produced no output")
            return []
        }
        let tcpText = tcpOutput?.stdout ?? ""
        let udpText = udpOutput?.stdout ?? ""
        if tcpText.isEmpty && udpText.isEmpty {
            if tcpOutput?.exitCode != 0 || udpOutput?.exitCode != 0 {
                Self.linuxLogSocketProbe(
                    "ss exit tcp=\(tcpOutput?.exitCode ?? -1) udp=\(udpOutput?.exitCode ?? -1) stderr=\(tcpOutput?.stderr.prefix(120) ?? udpOutput?.stderr.prefix(120) ?? "")"
                )
            }
            return []
        }
        if tcpOutput?.exitCode != 0 || udpOutput?.exitCode != 0 {
            Self.linuxLogSocketProbe(
                "ss partial tcp=\(tcpOutput?.exitCode ?? -1) udp=\(udpOutput?.exitCode ?? -1) lines=\(tcpText.split(whereSeparator: \.isNewline).count)+\(udpText.split(whereSeparator: \.isNewline).count)"
            )
        }
        return Self.parseLinuxVisibleSockets(tcpText: tcpText, udpText: udpText)
    }

    private func linuxCollectVisibleTCPViaSS() -> [VisibleSocket]? {
        guard let executable = LinuxSandboxAdaptation.firstExecutable([
            "/usr/sbin/ss", "/usr/bin/ss", "/bin/ss"
        ]) else {
            return nil
        }
        guard let output = CommandRunner.run(
            executable,
            arguments: ["-H", "-t", "-n", "-a", "-p"],
            timeout: 3
        ), output.exitCode == 0 else {
            return nil
        }
        let parsed = Self.parseLinuxVisibleTCPConnections(output.stdout)
        return parsed.isEmpty ? nil : parsed
    }

    private func linuxCollectVisibleSocketsViaProc(owners: [UInt64: (pid: Int, processName: String)] = [:]) -> [VisibleSocket] {
        let tcp = LinuxSandboxAdaptation.networkProcFileContents("net/tcp") ?? ""
        let tcp6 = LinuxSandboxAdaptation.networkProcFileContents("net/tcp6") ?? ""
        let udp = LinuxSandboxAdaptation.networkProcFileContents("net/udp") ?? ""
        let udp6 = LinuxSandboxAdaptation.networkProcFileContents("net/udp6") ?? ""
        return Self.parseLinuxVisibleSocketsFromProc(
            tcpText: tcp,
            tcp6Text: tcp6,
            udpText: udp,
            udp6Text: udp6,
            owners: owners
        )
    }

    private func linuxCollectVisibleTCPViaProc() -> [VisibleSocket] {
        let owners = linuxBuildSocketInodeOwnerMap()
        let tcp = LinuxSandboxAdaptation.procFileContents("net/tcp") ?? ""
        let tcp6 = LinuxSandboxAdaptation.procFileContents("net/tcp6") ?? ""
        return Self.parseLinuxVisibleSocketsFromProc(
            tcpText: tcp,
            tcp6Text: tcp6,
            udpText: "",
            udp6Text: "",
            owners: owners
        )
        .filter { $0.transport == .tcp }
    }

    private func linuxBuildSocketInodeOwnerMap() -> [UInt64: (pid: Int, processName: String)] {
        #if os(Linux)
        if LinuxSandboxAdaptation.isFlatpak {
            return [:]
        }
        if let cached = LinuxSocketInodeCache.shared.cachedIfFresh() {
            return cached
        }
        #endif

        var map: [UInt64: (pid: Int, processName: String)] = [:]
        let procRoot = LinuxSandboxAdaptation.procDirectory
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: procRoot) else {
            return map
        }

        var scanned = 0
        for entry in entries {
            guard let pid = Int(entry), pid > 0 else { continue }
            scanned += 1
            if scanned > 512 { break }
            let commPath = "\(procRoot)/\(pid)/comm"
            let comm = ((try? String(contentsOfFile: commPath, encoding: .utf8))?
                .trimmingCharacters(in: .whitespacesAndNewlines))
                .flatMap { $0.isEmpty ? nil : $0 }
            let processName = ExecutablePathResolver.path(forPID: pid) ?? comm ?? "unknown"
            let fdRoot = "\(procRoot)/\(pid)/fd"
            guard let fds = try? FileManager.default.contentsOfDirectory(atPath: fdRoot) else { continue }
            for fd in fds {
                guard let link = LinuxSandboxAdaptation.readProcSymlink("\(pid)/fd/\(fd)"),
                      link.hasPrefix("socket:[") else {
                    continue
                }
                let inodeText = link.dropFirst("socket:[".count).dropLast()
                guard let inode = UInt64(inodeText) else { continue }
                map[inode] = (pid, processName)
            }
        }

        #if os(Linux)
        LinuxSocketInodeCache.shared.store(map)
        #endif
        return map
    }

    private static func linuxLogSocketProbe(_ message: String) {
        let line = "[SystemInsights] socket probe: \(message)\n"
        FileHandle.standardError.write(Data(line.utf8))
    }

    private static var loggedLinuxNetworkProof = false

    private static func logLinuxNetworkProofOnce(
        interface: String,
        receivedTotal: Double,
        sentTotal: Double,
        receivedRate: Double,
        sentRate: Double
    ) {
        guard !loggedLinuxNetworkProof else { return }
        loggedLinuxNetworkProof = true
        let scale = LinuxNetworkProof.counterScale(receivedByteTotal: receivedTotal).rawValue
        let line = """
        [SystemInsights] network proof: iface=\(interface) rx_total=\(Int(receivedTotal)) tx_total=\(Int(sentTotal)) scale=\(scale) rate_rx=\(Int(receivedRate)) rate_tx=\(Int(sentRate)) source=networkProcFileContents

        """
        FileHandle.standardError.write(Data(line.utf8))
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

    static func parseLinuxVisibleSocketsFromProc(
        tcpText: String,
        tcp6Text: String,
        udpText: String,
        udp6Text: String,
        owners: [UInt64: (pid: Int, processName: String)] = [:]
    ) -> [VisibleSocket] {
        var connections: [String: VisibleSocket] = [:]

        func ownership(for fields: [String]) -> (processName: String, pid: Int) {
            guard fields.count > 9, let inode = UInt64(fields[9]), let owner = owners[inode] else {
                return ("unattributed", 0)
            }
            return (owner.processName, owner.pid)
        }

        func appendTCP(from text: String, ipv6: Bool) {
            for line in text.split(whereSeparator: \.isNewline).dropFirst().map(String.init) {
                let fields = line.split(whereSeparator: \.isWhitespace).map(String.init)
                guard fields.count > 3 else { continue }
                let state: VisibleSocketState
                switch fields[3].uppercased() {
                case "01": state = .established
                case "0A": state = .listening
                default: continue
                }
                guard let local = parseProcNetEndpoint(fields[1], ipv6: ipv6) else { continue }
                let remote = parseProcNetEndpoint(fields[2], ipv6: ipv6)
                let remoteEndpoint: String?
                if state == .established, let remote, !isWildcardPeer(remote) {
                    remoteEndpoint = remote
                } else {
                    remoteEndpoint = nil
                }
                let owner = ownership(for: fields)
                let connection = VisibleSocket(
                    processName: owner.processName,
                    pid: owner.pid,
                    localEndpoint: local,
                    remoteEndpoint: remoteEndpoint,
                    state: state
                )
                connections[connection.id] = connection
            }
        }

        func appendUDP(from text: String, ipv6: Bool) {
            for line in text.split(whereSeparator: \.isNewline).dropFirst().map(String.init) {
                let fields = line.split(whereSeparator: \.isWhitespace).map(String.init)
                guard fields.count > 3 else { continue }
                guard let local = parseProcNetEndpoint(fields[1], ipv6: ipv6) else { continue }
                let remote = parseProcNetEndpoint(fields[2], ipv6: ipv6)
                let remoteEndpoint = remote.flatMap { isWildcardPeer($0) ? nil : $0 }
                let owner = ownership(for: fields)
                let socket = VisibleSocket(
                    transport: .udp,
                    processName: owner.processName,
                    pid: owner.pid,
                    localEndpoint: local,
                    remoteEndpoint: remoteEndpoint,
                    state: .datagram
                )
                connections[socket.id] = socket
            }
        }

        appendTCP(from: tcpText, ipv6: false)
        appendTCP(from: tcp6Text, ipv6: true)
        appendUDP(from: udpText, ipv6: false)
        appendUDP(from: udp6Text, ipv6: true)

        return connections.values.sorted {
            if $0.transport != $1.transport {
                return $0.transport == .tcp
            }
            if $0.state != $1.state {
                return $0.state == .established || ($0.state == .listening && $1.state == .datagram)
            }
            return $0.localEndpoint < $1.localEndpoint
        }
        .prefix(NetworkSamplingLimits.maxVisibleSockets)
        .map { $0 }
    }

    private static func parseProcNetEndpoint(_ value: String, ipv6: Bool) -> String? {
        let parts = value.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2, let port = UInt16(parts[1], radix: 16) else { return nil }
        let addrHex = parts[0]
        if ipv6 {
            guard addrHex.count == 32 else { return nil }
            var segments: [String] = []
            var index = addrHex.startIndex
            for _ in 0..<4 {
                let wordEnd = addrHex.index(index, offsetBy: 8)
                let word = String(addrHex[index..<wordEnd])
                var wordIndex = word.startIndex
                var bytes: [String] = []
                for _ in 0..<4 {
                    let byteEnd = word.index(wordIndex, offsetBy: 2)
                    bytes.append(String(word[wordIndex..<byteEnd]))
                    wordIndex = byteEnd
                }
                segments.append(contentsOf: bytes.reversed())
                index = wordEnd
            }
            return "[\(segments.joined(separator: ":"))]:\(port)"
        }
        guard addrHex.count == 8 else { return nil }
        var bytes: [UInt8] = []
        var index = addrHex.startIndex
        for _ in 0..<4 {
            let next = addrHex.index(index, offsetBy: 2)
            guard let byte = UInt8(addrHex[index..<next], radix: 16) else { return nil }
            bytes.append(byte)
            index = next
        }
        return "\(bytes[3]).\(bytes[2]).\(bytes[1]).\(bytes[0]):\(port)"
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

#if os(Linux)
private enum LinuxSocketInodeCache {
    static let shared = LinuxSocketInodeCacheStorage()
}

private final class LinuxSocketInodeCacheStorage: @unchecked Sendable {
    private let lock = NSLock()
    private var cached: [UInt64: (pid: Int, processName: String)]?
    private var cachedAt = Date.distantPast
    private let ttl: TimeInterval = 5

    func cachedIfFresh() -> [UInt64: (pid: Int, processName: String)]? {
        lock.lock()
        defer { lock.unlock() }
        guard let cached, Date().timeIntervalSince(cachedAt) < ttl else { return nil }
        return cached
    }

    func store(_ map: [UInt64: (pid: Int, processName: String)]) {
        lock.lock()
        cached = map
        cachedAt = Date()
        lock.unlock()
    }
}

private actor LinuxNetworkRateTracker {
    static let shared = LinuxNetworkRateTracker()

    private struct Sample {
        var interface: String
        var received: Double
        var sent: Double
        var sampledAt: ContinuousClock.Instant
        var smoothedReceived: Double
        var smoothedSent: Double
    }

    private var sample: Sample?

    func rates(
        interface: String?,
        received: Double?,
        sent: Double?
    ) -> (received: Double, sent: Double) {
        guard let interface, let received, let sent else { return (0, 0) }
        let now = ContinuousClock.now

        guard let prior = sample, prior.interface == interface else {
            sample = Sample(
                interface: interface,
                received: received,
                sent: sent,
                sampledAt: now,
                smoothedReceived: 0,
                smoothedSent: 0
            )
            return (0, 0)
        }

        let interval = max(durationSeconds(from: prior.sampledAt, to: now), 0.5)
        let rawReceived = byteRate(
            from: prior.received,
            to: received,
            interval: interval,
            fallback: prior.smoothedReceived
        )
        let rawSent = byteRate(
            from: prior.sent,
            to: sent,
            interval: interval,
            fallback: prior.smoothedSent
        )
        let alpha = 0.35
        let smoothedReceived = alpha * rawReceived + (1 - alpha) * prior.smoothedReceived
        let smoothedSent = alpha * rawSent + (1 - alpha) * prior.smoothedSent
        sample = Sample(
            interface: interface,
            received: received,
            sent: sent,
            sampledAt: now,
            smoothedReceived: smoothedReceived,
            smoothedSent: smoothedSent
        )
        return (smoothedReceived, smoothedSent)
    }

    private func durationSeconds(from start: ContinuousClock.Instant, to end: ContinuousClock.Instant) -> Double {
        let elapsed = start.duration(to: end).components
        return max(Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18, 0.001)
    }

    private func byteRate(from first: Double, to second: Double, interval: TimeInterval, fallback: Double) -> Double {
        guard second >= first else { return fallback }
        return ((second - first) / interval).rounded()
    }
}
#endif

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
