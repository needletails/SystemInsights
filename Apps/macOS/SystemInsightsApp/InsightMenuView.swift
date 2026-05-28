import AppKit
import SwiftUI
import SystemInsightCore

struct InsightMenuView: View {
    let model: InsightViewModel
    let updater: UpdaterController
    let openDashboard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if model.requiresUnlock {
                CacheUnlockView(model: model)
                Divider()
            } else if model.showsPasswordSetup {
                CachePasswordSetupView(model: model, mode: model.passwordSetupMode)
                Divider()
            }

            if let snapshot = model.snapshot {
                header(for: snapshot)
                metrics(for: snapshot)
                connectivity(for: snapshot)
                NetworkTerminalView(
                    samples: model.liveNetworkSamples,
                    visibleSockets: model.visibleSockets,
                    socketActivityLog: model.socketActivityLog,
                    lastSocketSampleAt: model.lastSocketSampleAt
                )
                topProcesses(for: snapshot)

                if let issue = snapshot.topIssue {
                    Divider()
                    Label(issue.title, systemImage: symbol(for: issue.severity))
                        .font(.headline)
                        .foregroundStyle(color(for: issue.severity))
                    Text(issue.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let action = issue.recommendation {
                        Text(action)
                            .font(.caption)
                    }
                }

                securityActivity(for: snapshot)
            } else {
                ContentUnavailableView(
                    "No Snapshot Yet",
                    systemImage: "gauge.with.dots.needle.33percent",
                    description: Text("Refresh to collect the first health snapshot.")
                )
            }

            if let error = model.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Open Dashboard") {
                    openDashboard()
                }

                Button("Refresh Now") {
                    model.refresh()
                }
                .disabled(model.isRefreshing)

                if model.isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                }

                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }

            Toggle("Launch at Login", isOn: Binding(
                get: { model.launchesAtLogin },
                set: { model.setLaunchAtLogin($0) }
            ))
            .font(.caption)

            if model.isUnlocked {
                if model.isPasswordProtectionEnabled {
                    Button("Change Cache Password...") {
                        model.presentPasswordSetup(mode: .change)
                    }
                    .font(.caption)

                    Button("Lock Cache") {
                        model.lock()
                    }
                    .font(.caption)
                } else {
                    Button("Protect Cache with Password...") {
                        model.presentPasswordSetup(mode: .enable)
                    }
                    .font(.caption)
                }
            }

            Button("Check for Updates...") {
                updater.checkForUpdates()
            }
            .disabled(!updater.isConfigured)
        }
        .padding(16)
        .frame(width: 420)
        .onAppear {
            if model.isUnlocked {
                model.startLiveNetworkMonitoring()
            }
        }
        .onDisappear {
            model.stopLiveNetworkMonitoring()
        }
    }

    private func header(for snapshot: InsightSnapshot) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(snapshot.score)/100")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(color(for: snapshot.rating))
            VStack(alignment: .leading, spacing: 1) {
                Text("HEALTH")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(snapshot.rating.rawValue)
                    .font(.headline)
                    .foregroundStyle(color(for: snapshot.rating))
            }
            Spacer()
            Text("Sampled \(snapshot.generatedAt.formatted(date: .omitted, time: .standard))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func metrics(for snapshot: InsightSnapshot) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                MetricTile(title: "CPU", value: "\(Int(snapshot.metrics.cpuLoadPercent))%")
                MetricTile(title: "Memory", value: "\(Int(snapshot.metrics.memoryPressurePercent))%")
                MetricTile(title: "Disk", value: "\(Int(snapshot.metrics.diskUsagePercent))%")
            }
            HStack(spacing: 10) {
                MetricTile(title: "Down", value: formattedRate(snapshot.metrics.network.receivedBytesPerSecond))
                MetricTile(title: "Up", value: formattedRate(snapshot.metrics.network.sentBytesPerSecond))
                MetricTile(title: "Latency", value: formattedLatency(snapshot.metrics.network.latencyMilliseconds))
            }
        }
    }

    private func connectivity(for snapshot: InsightSnapshot) -> some View {
        let vpn = snapshot.metrics.network.vpn
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label("VPN: \(vpn.state.rawValue)", systemImage: vpnSymbol(for: vpn.state))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(vpnColor(for: vpn.state))
                Spacer()
                if let interface = snapshot.metrics.network.interfaceName {
                    Text(interface)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            Text(vpn.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(10)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func topProcesses(for snapshot: InsightSnapshot) -> some View {
        if !snapshot.metrics.topProcesses.isEmpty {
            Text("TOP CPU PROCESSES")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(Array(snapshot.metrics.topProcesses.prefix(3))) { process in
                HStack {
                    Text(processDisplayName(process.name))
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    Text("\(Int(process.cpuPercent))% CPU")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func securityActivity(for snapshot: InsightSnapshot) -> some View {
        Divider()
        Text("SECURITY ACTIVITY")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

        if snapshot.securityEvents.isEmpty {
            Text("No security activity was available in this snapshot.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            ForEach(Array(snapshot.securityEvents.prefix(3))) { event in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(color(for: event.severity))
                        .frame(width: 7, height: 7)
                        .padding(.top, 5)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.source)
                            .font(.caption.weight(.semibold))
                        Text(event.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
    }

    private func formattedRate(_ bytesPerSecond: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .decimal
        formatter.includesUnit = true
        return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
    }

    private func formattedLatency(_ milliseconds: Double?) -> String {
        guard let milliseconds else { return "-- ms" }
        return "\(Int(milliseconds.rounded())) ms"
    }

    private func processDisplayName(_ path: String) -> String {
        let name = URL(fileURLWithPath: path).lastPathComponent
        return name.isEmpty ? path : name
    }

    private func vpnSymbol(for state: VPNConnectionState) -> String {
        switch state {
        case .connected: return "lock.shield.fill"
        case .tunnelDetected: return "network.badge.shield.half.filled"
        case .notDetected: return "lock.slash"
        case .unavailable: return "questionmark.circle"
        }
    }

    private func vpnColor(for state: VPNConnectionState) -> Color {
        switch state {
        case .connected: return .green
        case .tunnelDetected: return .blue
        case .notDetected: return .secondary
        case .unavailable: return .secondary
        }
    }

    private func color(for rating: HealthRating) -> Color {
        switch rating {
        case .good: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }

    private func color(for severity: InsightSeverity) -> Color {
        switch severity {
        case .informational: return .secondary
        case .warning: return .orange
        case .critical: return .red
        }
    }

    private func symbol(for severity: InsightSeverity) -> String {
        switch severity {
        case .informational: return "info.circle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}

private struct NetworkTerminalView: View {
    let samples: [NetworkTerminalSample]
    let visibleSockets: [VisibleSocket]
    let socketActivityLog: [NetworkActivityEvent]
    let lastSocketSampleAt: Date?

    private var latest: NetworkTerminalSample? {
        samples.last
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("LIVE NETWORK CONSOLE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(0.4)
                Spacer()
                MenuConsoleStatus(lastSocketSampleAt: lastSocketSampleAt)
                Text(latest?.metrics.interfaceName ?? "--")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 11)
            .padding(.top, 10)
            .padding(.bottom, 8)

            HStack(spacing: 6) {
                Text("$")
                    .foregroundStyle(.green)
                Text("/usr/sbin/lsof  TCP + UDP SOCKETS  |  poll <1 s")
                    .foregroundStyle(.white.opacity(0.56))
            }
            .font(.system(size: 9, design: .monospaced))
            .padding(.horizontal, 11)
            .padding(.bottom, 9)

            if let latest {
                HStack(spacing: 18) {
                    terminalValue("RX", value: formattedRate(latest.metrics.receivedBytesPerSecond), color: .green)
                    terminalValue("TX", value: formattedRate(latest.metrics.sentBytesPerSecond), color: .cyan)
                    terminalValue("LAT", value: formattedLatency(latest.metrics.latencyMilliseconds), color: .orange)
                }
                .padding(.horizontal, 11)
                .padding(.bottom, 8)

                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.black.opacity(0.26))
                    NetworkTrace(samples: samples, keyPath: \.receivedBytesPerSecond, color: .green)
                    NetworkTrace(samples: samples, keyPath: \.sentBytesPerSecond, color: .cyan)
                }
                .frame(height: 34)
                .padding(.horizontal, 11)
                .padding(.bottom, 10)

                HStack {
                    Text("TIME       EVENT   IP    PROCESS  SERVICE       ENDPOINT")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.36))
                    Spacer()
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.035))

                ForEach(Array(socketActivityLog.prefix(4))) { entry in
                    connectionRow(entry)
                }

                HStack {
                    Text("service names are port hints | direction not inferred")
                    Spacer()
                    Text("\(establishedCount) established | \(listenerCount) listen | \(udpCount) UDP")
                }
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.38))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
            } else {
                Text("Waiting for first network sample...")
                    .font(.caption.monospaced())
                    .foregroundStyle(.white.opacity(0.56))
                    .padding(.horizontal, 11)
                    .padding(.bottom, 12)
            }
        }
        .foregroundStyle(.white.opacity(0.9))
        .background(Color(red: 0.035, green: 0.045, blue: 0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func terminalValue(_ name: String, value: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Text(name)
                .foregroundStyle(color.opacity(0.78))
            Text(value)
                .foregroundStyle(.white.opacity(0.9))
        }
        .font(.caption.monospacedDigit().monospaced())
    }

    private func formattedRate(_ bytesPerSecond: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .decimal
        formatter.includesUnit = true
        return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
    }

    private func formattedLatency(_ milliseconds: Double?) -> String {
        guard let milliseconds else { return "-- ms" }
        return "\(Int(milliseconds.rounded())) ms"
    }

    private var establishedCount: Int {
        visibleSockets.filter { $0.state == .established }.count
    }

    private var listenerCount: Int {
        visibleSockets.filter { $0.state == .listening }.count
    }

    private var udpCount: Int {
        visibleSockets.filter { $0.transport == .udp }.count
    }

    private func connectionRow(_ entry: NetworkActivityEvent) -> some View {
        HStack(spacing: 6) {
            Text(entry.timestamp.formatted(date: .omitted, time: .standard))
                .foregroundStyle(.white.opacity(0.4))
            Text(actionLabel(entry.action))
                .foregroundStyle(actionColor(entry.action))
                .frame(width: 42, alignment: .leading)
            Text(entry.transport.rawValue)
                .foregroundStyle(entry.transport == .tcp ? .cyan : .orange)
                .frame(width: 26, alignment: .leading)
            Text(entry.processName)
                .foregroundStyle(.white.opacity(0.86))
                .frame(width: 54, alignment: .leading)
            Text(entry.serviceHint.label)
                .foregroundStyle(serviceColor(entry.serviceHint.confidence))
                .frame(width: 74, alignment: .leading)
                .lineLimit(1)
            Text(endpointDescription(entry))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.system(size: 9, design: .monospaced))
        .padding(.horizontal, 11)
        .padding(.vertical, 4)
    }

    private func endpointDescription(_ entry: NetworkActivityEvent) -> String {
        if let remote = entry.remoteEndpoint {
            return "\(entry.localEndpoint) -> \(remote)"
        }
        return entry.localEndpoint
    }

    private func actionLabel(_ action: NetworkActivityAction) -> String {
        action.rawValue
    }

    private func actionColor(_ action: NetworkActivityAction) -> Color {
        switch action {
        case .observed: return .green
        case .opened: return .cyan
        case .closed: return .yellow
        case .listening: return .mint
        case .stoppedListening: return .orange
        }
    }

    private func serviceColor(_ confidence: SocketServiceConfidence) -> Color {
        switch confidence {
        case .portMapped: return .mint
        case .heuristic: return .yellow
        case .unclassified: return .white.opacity(0.38)
        }
    }
}

private struct MenuConsoleStatus: View {
    let lastSocketSampleAt: Date?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let age = lastSocketSampleAt.map { max(0, Int(context.date.timeIntervalSince($0))) }
            let isLive = age.map { $0 < 5 } ?? false

            HStack(spacing: 5) {
                Circle()
                    .fill(isLive ? .green : .orange)
                    .frame(width: 6, height: 6)
                Text(age.map { isLive ? "LIVE \($0)s" : "STALE \($0)s" } ?? "WAITING")
            }
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundStyle(isLive ? .green : .orange)
        }
    }
}

private struct NetworkTrace: View {
    let samples: [NetworkTerminalSample]
    let keyPath: KeyPath<NetworkMetrics, Double>
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let values = samples.map { $0.metrics[keyPath: keyPath] }
            let ceiling = max(values.max() ?? 0, 1)

            Path { path in
                for (index, value) in values.enumerated() {
                    let x = values.count < 2
                        ? proxy.size.width
                        : proxy.size.width * CGFloat(index) / CGFloat(values.count - 1)
                    let y = proxy.size.height * (1 - CGFloat(value / ceiling))
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color.opacity(0.85), style: StrokeStyle(lineWidth: 1.4, lineJoin: .round))
        }
    }
}

private struct MetricTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
    }
}
