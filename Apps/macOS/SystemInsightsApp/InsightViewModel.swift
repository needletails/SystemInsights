import Foundation
import Observation
import ServiceManagement
import SwiftUI
import SystemInsightCore
import WidgetKit

struct NetworkTerminalSample: Identifiable {
    let id = UUID()
    let timestamp: Date
    let metrics: NetworkMetrics
}

@MainActor
@Observable
final class InsightViewModel {
    private static let maximumConnectionLogEntries = 250
    private static let foregroundSocketPollInterval = Duration.milliseconds(750)
    private static let backgroundSocketPollInterval = Duration.seconds(6)
    private static let widgetActivityPublishDelay = Duration.seconds(5)
    private static let widgetTelemetryPublishInterval: TimeInterval = 30

    private(set) var snapshot: InsightSnapshot?
    private(set) var liveNetworkSamples: [NetworkTerminalSample] = []
    private(set) var visibleSockets: [VisibleSocket] = []
    private(set) var socketActivityLog: [NetworkActivityEvent] = []
    private(set) var lastSocketSampleAt: Date?
    private(set) var isRefreshing = false
    private(set) var launchesAtLogin = SMAppService.mainApp.status == .enabled
    private(set) var errorMessage: String?
    private(set) var isPasswordProtectionEnabled = CacheSecurityCoordinator.isPasswordProtectionEnabled()
    private(set) var isUnlocked = false
    private(set) var isSecurityBusy = false
    private(set) var securityErrorMessage: String?
    private(set) var showsPasswordSetup = false
    private(set) var passwordSetupMode: CachePasswordSetupView.PasswordSetupMode = .enable

    @ObservationIgnored private var automaticRefreshTask: Task<Void, Never>?
    @ObservationIgnored private var didBootstrap = false
    @ObservationIgnored private var telemetryRefreshTask: Task<Void, Never>?
    @ObservationIgnored private var collectionTask: Task<Void, Never>?
    @ObservationIgnored private var networkMonitoringTask: Task<Void, Never>?
    @ObservationIgnored private var liveNetworkTask: Task<Void, Never>?
    @ObservationIgnored private var connectionMonitoringTask: Task<Void, Never>?
    @ObservationIgnored private var networkActivityPublishTask: Task<Void, Never>?
    @ObservationIgnored private var previousSockets: [String: VisibleSocket]?
    @ObservationIgnored private var lastSocketFingerprint: UInt64?
    @ObservationIgnored private var liveNetworkSubscriberCount = 0
    @ObservationIgnored private var liveNetworkStopGeneration: UInt64 = 0
    @ObservationIgnored private var holdsLiveNetworkSession = false
    @ObservationIgnored private var lastWidgetPublishAt: Date?

    init() {
        if isPasswordProtectionEnabled {
            _ = CacheSecurityCoordinator.hydrateStoredSessionIfAvailable()
        }
        isUnlocked = !isPasswordProtectionEnabled || CacheSecurityCoordinator.isUnlocked()
        showsPasswordSetup = !isPasswordProtectionEnabled && !didBootstrap
        if isUnlocked {
            bootstrapAfterUnlock()
        }
    }

    var requiresUnlock: Bool {
        isPasswordProtectionEnabled && !isUnlocked
    }

    func unlock(password: String) {
        isSecurityBusy = true
        securityErrorMessage = nil
        defer { isSecurityBusy = false }

        do {
            try CacheSecurityCoordinator.unlock(password: password)
            isUnlocked = true
            showsPasswordSetup = false
            completeUnlockSession()
        } catch SnapshotCacheLockError.invalidPassword {
            securityErrorMessage = "Incorrect password."
        } catch {
            securityErrorMessage = error.localizedDescription
        }
    }

    func enablePasswordProtection(password: String) {
        isSecurityBusy = true
        securityErrorMessage = nil
        defer { isSecurityBusy = false }

        do {
            try CacheSecurityCoordinator.enablePasswordProtection(password)
            isPasswordProtectionEnabled = true
            isUnlocked = true
            showsPasswordSetup = false
            completeUnlockSession()
            try reencryptExistingCaches()
        } catch {
            securityErrorMessage = "Password must be at least 8 characters and match confirmation."
            if password.count >= 8 {
                securityErrorMessage = error.localizedDescription
            }
        }
    }

    func changePassword(current: String, new: String) {
        isSecurityBusy = true
        securityErrorMessage = nil
        defer { isSecurityBusy = false }

        do {
            try CacheSecurityCoordinator.changePassword(from: current, to: new)
            securityErrorMessage = nil
            showsPasswordSetup = false
            try reencryptExistingCaches()
        } catch SnapshotCacheLockError.invalidPassword {
            securityErrorMessage = "Current password is incorrect."
        } catch {
            securityErrorMessage = error.localizedDescription
        }
    }

    func presentPasswordSetup(mode: CachePasswordSetupView.PasswordSetupMode = .enable) {
        passwordSetupMode = mode
        showsPasswordSetup = true
        securityErrorMessage = nil
    }

    func dismissPasswordSetup() {
        showsPasswordSetup = false
        if !isPasswordProtectionEnabled && !didBootstrap {
            bootstrapAfterUnlock()
        }
    }

    func lock() {
        CacheSecurityCoordinator.lock()
        isUnlocked = false
        snapshot = nil
        cancelBackgroundWork()
    }

    private func bootstrapAfterUnlock() {
        guard !didBootstrap else { return }
        didBootstrap = true
        snapshot = SharedWidgetConfiguration.readSnapshot()
        refresh()
        resumeSessionAfterUnlock()
    }

    private func completeUnlockSession() {
        if !didBootstrap {
            bootstrapAfterUnlock()
            return
        }
        if snapshot == nil {
            snapshot = SharedWidgetConfiguration.readSnapshot()
        }
        refresh()
        resumeSessionAfterUnlock()
    }

    private func resumeSessionAfterUnlock() {
        startBackgroundWork()
        holdLiveNetworkMonitoringForSession()
    }

    private func startBackgroundWork() {
        automaticRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(10 * 60))
                } catch {
                    return
                }
                self?.refresh()
            }
        }
        telemetryRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(5))
                } catch {
                    return
                }
                await self?.refreshTelemetry()
            }
        }
        networkMonitoringTask = Task { [weak self] in
            await NetworkSamplingService.shared.startPathMonitoring { [weak self] in
                await MainActor.run {
                    self?.refresh()
                }
            }
        }
        restartConnectionMonitoring()
    }

    private func cancelBackgroundWork() {
        automaticRefreshTask?.cancel()
        automaticRefreshTask = nil
        telemetryRefreshTask?.cancel()
        telemetryRefreshTask = nil
        collectionTask?.cancel()
        collectionTask = nil
        networkMonitoringTask?.cancel()
        networkMonitoringTask = nil
        liveNetworkTask?.cancel()
        liveNetworkTask = nil
        liveNetworkSubscriberCount = 0
        holdsLiveNetworkSession = false
        liveNetworkStopGeneration &+= 1
        connectionMonitoringTask?.cancel()
        connectionMonitoringTask = nil
        networkActivityPublishTask?.cancel()
        networkActivityPublishTask = nil
        Task {
            await NetworkSamplingService.shared.stopPathMonitoring()
        }
    }

    /// Keeps live throughput sampling active for the unlocked session (views add extra subscribers on top).
    private func holdLiveNetworkMonitoringForSession() {
        guard isUnlocked else { return }
        holdsLiveNetworkSession = true
        restartConnectionMonitoring()
        ensureLiveNetworkSamplingTask()
    }

    private func ensureLiveNetworkSamplingTask() {
        if let liveNetworkTask, !liveNetworkTask.isCancelled {
            return
        }
        liveNetworkTask = nil
        liveNetworkTask = Task { [weak self] in
            defer { Task { @MainActor in self?.liveNetworkTask = nil } }
            while !Task.isCancelled {
                do {
                    let status = self?.networkStatusForLiveSample ?? .unavailable
                    let establishedCount = self?.visibleSockets.filter { $0.state == .established }.count
                    let metrics = try await NetworkSamplingService.shared.liveNetworkMetrics(
                        preserving: status,
                        establishedTCPCount: establishedCount
                    )
                    try Task.checkCancellation()
                    self?.liveNetworkSamples.append(NetworkTerminalSample(timestamp: Date(), metrics: metrics))
                    if let count = self?.liveNetworkSamples.count, count > 24 {
                        self?.liveNetworkSamples.removeFirst(count - 24)
                    }
                    try await Task.sleep(for: .milliseconds(500))
                } catch is CancellationError {
                    return
                } catch {
                    try? await Task.sleep(for: .seconds(1))
                }
            }
        }
    }

    private func reencryptExistingCaches() throws {
        for url in SharedWidgetConfiguration.cacheURLs {
            guard let snapshot = try? CacheStore(url: url).read() else { continue }
            try CacheStore(url: url).write(snapshot)
        }
    }

    deinit {
        automaticRefreshTask?.cancel()
        telemetryRefreshTask?.cancel()
        collectionTask?.cancel()
        networkMonitoringTask?.cancel()
        liveNetworkTask?.cancel()
        connectionMonitoringTask?.cancel()
        networkActivityPublishTask?.cancel()
        Task {
            await NetworkSamplingService.shared.stopPathMonitoring()
        }
    }

    var menuBarSymbol: String {
        switch snapshot?.rating {
        case .good: return "checkmark.shield"
        case .warning: return "exclamationmark.shield"
        case .critical: return "xmark.shield"
        case nil: return "gauge.with.dots.needle.33percent"
        }
    }

    func refresh() {
        guard isUnlocked else { return }
        guard !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil

        collectionTask = Task { [weak self] in
            guard let self else { return }
            defer { isRefreshing = false }
            do {
                let collectedSnapshot = try await InsightEngine().snapshot()
                try Task.checkCancellation()
                let snapshot = withCurrentNetworkActivity(collectedSnapshot)
                guard !Task.isCancelled else { return }
                self.snapshot = snapshot
                try publishToWidget(snapshot)
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func refreshTelemetry() async {
        guard isUnlocked else { return }
        guard snapshot != nil, !isRefreshing else { return }
        do {
            let metrics = try await SystemMetricCollector().collect()
            try Task.checkCancellation()
            guard let currentSnapshot = snapshot, !isRefreshing else { return }

            let scorer = InsightScorer()
            let issues = scorer.issues(for: metrics, findings: currentSnapshot.securityFindings)
            let score = scorer.score(for: issues)
            let recommendations = issues.compactMap(\.recommendation).reduce(into: [String]()) { result, recommendation in
                if !result.contains(recommendation) {
                    result.append(recommendation)
                }
            }
            let updatedSnapshot = InsightSnapshot(
                generatedAt: Date(),
                host: currentSnapshot.host,
                metrics: metrics,
                networkActivity: Array(socketActivityLog.prefix(8)),
                securityFindings: currentSnapshot.securityFindings,
                securityEvents: currentSnapshot.securityEvents,
                issues: issues,
                score: score,
                rating: scorer.rating(for: score, issues: issues),
                recommendations: recommendations,
                topIssue: issues.first
            )
            snapshot = updatedSnapshot
            if shouldPublishTelemetrySnapshot(previous: currentSnapshot, current: updatedSnapshot) {
                try publishToWidget(updatedSnapshot)
            }
        } catch is CancellationError {
            return
        } catch {
            errorMessage = "Live telemetry refresh failed: \(error.localizedDescription)"
        }
    }

    func startLiveNetworkMonitoring() {
        liveNetworkStopGeneration &+= 1
        let shouldAccelerateSocketPolling = liveNetworkSubscriberCount == 0
        liveNetworkSubscriberCount += 1
        if shouldAccelerateSocketPolling {
            restartConnectionMonitoring()
        }
        ensureLiveNetworkSamplingTask()
    }

    func stopLiveNetworkMonitoring() {
        liveNetworkSubscriberCount = max(0, liveNetworkSubscriberCount - 1)
        let remainingSubscribers = liveNetworkSubscriberCount
        let stopGeneration = liveNetworkStopGeneration
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard let self else { return }
            guard stopGeneration == liveNetworkStopGeneration else { return }
            guard liveNetworkSubscriberCount == remainingSubscribers else { return }
            guard remainingSubscribers == 0, !holdsLiveNetworkSession else { return }
            liveNetworkTask?.cancel()
            liveNetworkTask = nil
            restartConnectionMonitoring()
        }
    }

    private var networkStatusForLiveSample: NetworkMetrics {
        let status = snapshot?.metrics.network ?? .unavailable
        return NetworkMetrics(
            interfaceName: status.interfaceName,
            receivedBytesPerSecond: 0,
            sentBytesPerSecond: 0,
            activeTCPConnections: visibleSockets.filter { $0.state == .established }.count,
            vpn: status.vpn
        )
    }

    private func restartConnectionMonitoring() {
        connectionMonitoringTask?.cancel()
        connectionMonitoringTask = Task { [weak self] in
            while !Task.isCancelled {
                let sockets = await SystemMetricCollector().collectVisibleSockets()
                guard !Task.isCancelled else { return }
                self?.lastSocketSampleAt = Date()
                self?.recordVisibleSockets(sockets)

                let interval = (self?.liveNetworkSubscriberCount ?? 0) > 0
                    ? Self.foregroundSocketPollInterval
                    : Self.backgroundSocketPollInterval
                do {
                    try await Task.sleep(for: interval)
                } catch {
                    return
                }
            }
        }
    }

    private func recordVisibleSockets(_ connections: [VisibleSocket]) {
        let fingerprint = VisibleSocketSampling.fingerprint(connections)
        if fingerprint != lastSocketFingerprint {
            lastSocketFingerprint = fingerprint
            SocketConsoleDiagnostics.logRefresh(
                source: "connection-monitor",
                connections: connections,
                fingerprint: fingerprint,
                appliedToUI: true
            )
        }

        let now = Date()
        let current = Dictionary(uniqueKeysWithValues: connections.map { ($0.id, $0) })
        defer {
            if visibleSockets != connections {
                visibleSockets = connections
            }
            previousSockets = current
        }

        guard let previousSockets else {
            socketActivityLog = connections.prefix(8).map {
                NetworkActivityEvent(timestamp: now, action: $0.state == .listening ? .listening : .observed, connection: $0)
            }
            scheduleNetworkActivityPublish()
            return
        }

        let appeared = current.keys
            .filter { previousSockets[$0] == nil }
            .compactMap { current[$0] }
            .map {
                NetworkActivityEvent(timestamp: now, action: $0.state == .listening ? .listening : .opened, connection: $0)
            }
        let disappeared = previousSockets.keys
            .filter { current[$0] == nil }
            .compactMap { previousSockets[$0] }
            .map {
                NetworkActivityEvent(timestamp: now, action: $0.state == .listening ? .stoppedListening : .closed, connection: $0)
            }
        let newEvents = appeared + disappeared
        guard !newEvents.isEmpty else { return }
        socketActivityLog.insert(contentsOf: newEvents, at: 0)
        if socketActivityLog.count > Self.maximumConnectionLogEntries {
            socketActivityLog.removeLast(socketActivityLog.count - Self.maximumConnectionLogEntries)
        }
        scheduleNetworkActivityPublish()
    }

    private func scheduleNetworkActivityPublish() {
        guard networkActivityPublishTask == nil else { return }
        networkActivityPublishTask = Task { [weak self] in
            do {
                try await Task.sleep(for: Self.widgetActivityPublishDelay)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            self?.networkActivityPublishTask = nil
            self?.publishNetworkActivity()
        }
    }

    private func publishNetworkActivity() {
        guard let snapshot else { return }
        let updatedSnapshot = withCurrentNetworkActivity(snapshot)
        guard updatedSnapshot.networkActivity != snapshot.networkActivity else { return }
        do {
            self.snapshot = updatedSnapshot
            try publishToWidget(updatedSnapshot)
        } catch {
            errorMessage = "Network activity publish failed: \(error.localizedDescription)"
        }
    }

    private func shouldPublishTelemetrySnapshot(previous: InsightSnapshot, current: InsightSnapshot) -> Bool {
        guard previous.rating == current.rating, previous.topIssue?.id == current.topIssue?.id else {
            return true
        }
        guard let lastWidgetPublishAt else { return true }
        return Date().timeIntervalSince(lastWidgetPublishAt) >= Self.widgetTelemetryPublishInterval
    }

    private func publishToWidget(_ snapshot: InsightSnapshot) throws {
        guard isUnlocked else { return }
        try SharedWidgetConfiguration.writeSnapshot(snapshot)
        lastWidgetPublishAt = Date()
        WidgetCenter.shared.reloadTimelines(ofKind: SharedWidgetConfiguration.kind)
    }

    private func withCurrentNetworkActivity(_ snapshot: InsightSnapshot) -> InsightSnapshot {
        InsightSnapshot(
            schemaVersion: snapshot.schemaVersion,
            generatedAt: snapshot.generatedAt,
            host: snapshot.host,
            metrics: snapshot.metrics,
            networkActivity: Array(socketActivityLog.prefix(8)),
            securityFindings: snapshot.securityFindings,
            securityEvents: snapshot.securityEvents,
            issues: snapshot.issues,
            score: snapshot.score,
            rating: snapshot.rating,
            recommendations: snapshot.recommendations,
            topIssue: snapshot.topIssue
        )
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchesAtLogin = SMAppService.mainApp.status == .enabled
        } catch {
            errorMessage = "Unable to update login-item setting: \(error.localizedDescription)"
            launchesAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
