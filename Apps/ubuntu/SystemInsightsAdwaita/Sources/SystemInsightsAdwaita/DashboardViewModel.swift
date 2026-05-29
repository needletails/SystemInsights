import Adwaita
import Foundation
import SystemInsightCore

/// Process-wide dashboard state. GTK recreates ``DashboardView``; this singleton keeps collect/bootstrap alive.
@MainActor
final class DashboardViewModel {
    static let shared = DashboardViewModel()

    /// Survives GTK recreating ``DashboardView``; read in the view body to trigger redraws.
    private(set) var viewRenderTick = 0
    let uiGeneration = DashboardRenderState()

    private(set) var didBootstrap = false
    private(set) var snapshot: InsightSnapshot?
    private(set) var isCollecting = false
    var statusMessage = ""
    var showStatusBanner = false

    private(set) var recentActivity: [NetworkActivityEvent] = []
    private(set) var liveNetwork: NetworkMetrics?
    private(set) var liveNetworkSamples: [NetworkMetrics] = []
    private(set) var visibleSockets: [VisibleSocket] = []
    private(set) var socketSearchIndex: [SocketConsoleFilter.IndexEntry] = []
    private(set) var lastSocketSampleAt: Date?
    private(set) var lastSocketFingerprint: UInt64?
    private(set) var previousConnections: [String: VisibleSocket]?

    private var delayedBootstrap: (() -> Void)?
    /// View registers this so Adwaita re-renders when singleton state changes.
    var onUIDidChange: (() -> Void)?
    var onCollectComplete: (() -> Void)?

    private let backgroundWork = DashboardBackgroundCoordinator()
    private(set) var isMonitoring = false
    private(set) var isRefreshingTelemetry = false
    private(set) var isRefreshingLiveNetwork = false
    private(set) var isRefreshingSockets = false

    private var lastGraphSampleAt: Date?

    private init() {}

    func resetForProcessLaunch() {
        didBootstrap = false
        isCollecting = false
    }

    func registerDelayedBootstrap(_ action: @escaping () -> Void) {
        delayedBootstrap = action
    }

    func requestDelayedBootstrap() {
        delayedBootstrap?()
        if !didBootstrap {
            DashboardCollectDiagnostics.log("delayed bootstrap: view not ready, retrying")
            Idle(delay: 400) {
                self.delayedBootstrap?()
                return false
            }
        }
    }

    private func notifyUI() {
        viewRenderTick += 1
        uiGeneration.bump()
        onUIDidChange?()
    }

    func touchUI() {
        notifyUI()
    }

    func applyLiveNetwork(_ network: NetworkMetrics) {
        var samples = liveNetworkSamples
        if shouldAppendLiveNetworkSample(network, samples: samples) {
            samples.append(network)
            lastGraphSampleAt = Date()
            if samples.count > NetworkSamplingLimits.maxLiveNetworkSamples {
                samples.removeFirst(samples.count - NetworkSamplingLimits.maxLiveNetworkSamples)
            }
        }
        liveNetwork = network
        liveNetworkSamples = samples
        notifyUI()
    }

    private func shouldAppendLiveNetworkSample(_ network: NetworkMetrics, samples: [NetworkMetrics]) -> Bool {
        let now = Date()
        if let lastGraphSampleAt, now.timeIntervalSince(lastGraphSampleAt) >= 2 {
            return true
        }
        guard let last = samples.last else { return true }
        let ratesChanged = abs(last.receivedBytesPerSecond - network.receivedBytesPerSecond) >= 256
            || abs(last.sentBytesPerSecond - network.sentBytesPerSecond) >= 256
        let contextChanged = last.interfaceName != network.interfaceName
            || last.activeTCPConnections != network.activeTCPConnections
            || last.vpn != network.vpn
            || last.latencyMilliseconds != network.latencyMilliseconds
        return ratesChanged || contextChanged
    }

    func clearDashboardData() {
        stopMonitoring()
        snapshot = nil
        recentActivity = []
        liveNetwork = nil
        liveNetworkSamples = []
        visibleSockets = []
        socketSearchIndex = []
        lastSocketSampleAt = nil
        lastSocketFingerprint = nil
        previousConnections = nil
        lastGraphSampleAt = nil
        isCollecting = false
        notifyUI()
    }

    func applySnapshot(_ loaded: InsightSnapshot) {
        snapshot = loaded
        recentActivity = Array(loaded.networkActivity.prefix(NetworkSamplingLimits.maxActivityEvents))
        liveNetwork = loaded.metrics.network
        liveNetworkSamples = [loaded.metrics.network]
        notifyUI()
    }

    func performLaunchBootstrap(security: inout DashboardSecurityState, screen: inout DashboardScreen) {
        if didBootstrap {
            DashboardCollectDiagnostics.log(
                "dashboard bootstrap skipped (didBootstrap=true snapshot=\(snapshot != nil) monitoring=\(isMonitoring))"
            )
            startMonitoringIfNeeded()
            return
        }
        didBootstrap = true
        DashboardCollectDiagnostics.log(
            "dashboard bootstrap (flatpak=\(ProcessInfo.processInfo.environment["FLATPAK_ID"] ?? "no"))"
        )
        prepareCacheSessionIfNeeded()
        security.refresh()
        screen = DashboardScreen.from(security: security)
        guard security.isUnlocked else {
            DashboardCollectDiagnostics.log("dashboard bootstrap: cache locked")
            return
        }
        DashboardCollectDiagnostics.log("bootstrap after unlock")
        reloadCachedSnapshot(security: security)
        if snapshot == nil {
            statusMessage = "No cached snapshot on disk. Collecting a fresh snapshot…"
            showStatusBanner = true
            notifyUI()
            startCollect()
        }
        startMonitoringIfNeeded()
    }

    func startMonitoringIfNeeded() {
        guard cacheIsUnlockedForCollect() else { return }
        if snapshot == nil, !isCollecting {
            startCollect()
        }
        guard !isMonitoring else { return }
        isMonitoring = true
        DashboardCollectDiagnostics.log("monitoring started")
        backgroundWork.start(
            canWork: { [weak self] in
                guard let self else { return false }
                return self.isMonitoring && self.cacheIsUnlockedForCollect()
            },
            onLiveNetworkRefresh: { await self.refreshLiveNetworkAsync() },
            onSocketRefresh: { await self.refreshSocketTableAsync() },
            onTelemetryRefresh: { await self.refreshTelemetryAsync() },
            onSnapshotCollect: { await self.collectSnapshotAsync() }
        )
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        backgroundWork.stop()
        DashboardCollectDiagnostics.log("monitoring stopped")
    }

    private func refreshTelemetryAsync() async {
        let context = await DashboardGTKBridge.runOnMain { () -> (Bool, InsightSnapshot?, [NetworkActivityEvent]) in
            guard self.cacheIsUnlockedForCollect(), !self.isRefreshingTelemetry, let snap = self.snapshot else {
                return (false, nil, [])
            }
            self.isRefreshingTelemetry = true
            return (true, snap, self.recentActivity)
        }
        guard context.0, let currentSnapshot = context.1 else { return }
        defer {
            Task { await DashboardGTKBridge.runOnMain { self.isRefreshingTelemetry = false } }
        }

        do {
            let activitySnapshot = context.2
            let refreshedSnapshot = try await Task.detached {
                let refreshedMetrics = try await NetworkSamplingService.shared.collectMetrics()
                return DashboardSamplingPipeline.buildTelemetrySnapshot(
                    current: currentSnapshot,
                    metrics: refreshedMetrics,
                    recentActivity: activitySnapshot
                )
            }.value
            await DashboardGTKBridge.runOnMain {
                self.applyTelemetrySnapshot(refreshedSnapshot)
            }
        } catch {
            DashboardCollectDiagnostics.log("telemetry refresh failed: \(error)")
        }
    }

    private func refreshLiveNetworkAsync() async {
        let shouldRun = await DashboardGTKBridge.runOnMain {
            guard self.cacheIsUnlockedForCollect() else { return false }
            self.isRefreshingLiveNetwork = true
            return true
        }
        guard shouldRun else { return }
        defer {
            Task { await DashboardGTKBridge.runOnMain { self.isRefreshingLiveNetwork = false } }
        }

        let inputs = await DashboardGTKBridge.runOnMain {
            (
                self.liveNetwork ?? self.snapshot?.metrics.network ?? .unavailable,
                self.visibleSockets.filter { $0.state == .established }.count
            )
        }
        do {
            let network = try await DashboardSamplingPipeline.pollLiveNetwork(
                preserving: inputs.0,
                establishedTCPCount: inputs.1
            )
            await DashboardGTKBridge.runOnMain {
                self.applyLiveNetwork(network)
            }
            DashboardCollectDiagnostics.log(
                "network poll: rx=\(Int(network.receivedBytesPerSecond)) tx=\(Int(network.sentBytesPerSecond)) if=\(network.interfaceName ?? "?")"
            )
        } catch {
            DashboardCollectDiagnostics.log("network refresh failed: \(error)")
        }
    }

    private func refreshSocketTableAsync() async {
        let context = await DashboardGTKBridge.runOnMain { () -> (Bool, NetworkMetrics, Int, UInt64?, [String: VisibleSocket]?, [NetworkActivityEvent], Bool) in
            guard self.cacheIsUnlockedForCollect() else {
                return (false, .unavailable, 0, nil, nil, [], false)
            }
            self.isRefreshingSockets = true
            let baseline = self.liveNetwork ?? self.snapshot?.metrics.network ?? .unavailable
            let count = self.visibleSockets.filter { $0.state == .established }.count
            let force = self.visibleSockets.isEmpty
            return (true, baseline, count, self.lastSocketFingerprint, self.previousConnections, self.recentActivity, force)
        }
        guard context.0 else { return }
        defer {
            Task { await DashboardGTKBridge.runOnMain { self.isRefreshingSockets = false } }
        }

        do {
            let sample = try await DashboardSamplingPipeline.pollNetwork(
                preserving: context.1,
                establishedTCPCount: context.2
            )
            await DashboardGTKBridge.runOnMain {
                self.applyLiveNetwork(sample.network)
            }

            let connections = sample.connections
            let fingerprint = context.3
            let previous = context.4
            let activity = context.5
            let force = context.6
            let socketUpdate = await Task.detached {
                DashboardSamplingPipeline.prepareSocketUIUpdate(
                    connections: connections,
                    previousFingerprint: fingerprint,
                    previousConnections: previous,
                    recentActivity: activity,
                    force: force
                )
            }.value
            if let socketUpdate {
                await DashboardGTKBridge.runOnMain {
                    self.applyLiveSocketUpdate(socketUpdate)
                }
                DashboardCollectDiagnostics.log(
                    "socket poll: \(socketUpdate.connections.count) sockets rx=\(Int(sample.network.receivedBytesPerSecond)) tx=\(Int(sample.network.sentBytesPerSecond))"
                )
            } else if !connections.isEmpty {
                await DashboardGTKBridge.runOnMain {
                    self.applyLiveSocketUpdate(
                        DashboardSamplingPipeline.SocketUIUpdate(
                            connections: connections,
                            fingerprint: VisibleSocketSampling.fingerprint(connections),
                            index: SocketConsoleFilter.buildIndex(connections: connections),
                            recentActivity: activity,
                            previousConnections: Dictionary(uniqueKeysWithValues: connections.map { ($0.id, $0) })
                        )
                    )
                }
            }
        } catch {
            DashboardCollectDiagnostics.log("socket refresh failed: \(error)")
        }
    }

    func startCollect() {
        DashboardCollectRunner.start()
    }

    func cacheIsUnlockedForCollect() -> Bool {
        !CacheSecurityCoordinator.isPasswordProtectionEnabled() || CacheSecurityCoordinator.isUnlocked()
    }

    func reportCollectLocked() {
        statusMessage = "Cache is locked. Unlock before collecting a snapshot."
        showStatusBanner = true
        notifyUI()
    }

    func markCollectStarted() {
        if isCollecting {
            DashboardCollectDiagnostics.log("collect: clearing stuck isCollecting flag")
            isCollecting = false
        }
        isCollecting = true
        statusMessage = "Collecting snapshot…"
        showStatusBanner = true
        notifyUI()
        DashboardCollectDiagnostics.log("collect started")
    }

    func markCollectSucceeded(
        snapshot collectedSnapshot: InsightSnapshot,
        socketUpdate: DashboardSamplingPipeline.SocketUIUpdate?
    ) {
        defer {
            isCollecting = false
            notifyUI()
        }
        if let socketUpdate {
            visibleSockets = socketUpdate.connections
            recentActivity = socketUpdate.recentActivity
            previousConnections = socketUpdate.previousConnections
            socketSearchIndex = socketUpdate.index
            lastSocketFingerprint = socketUpdate.fingerprint
            lastSocketSampleAt = Date()
        } else {
            visibleSockets = []
            socketSearchIndex = []
            lastSocketFingerprint = VisibleSocketSampling.fingerprint([])
        }
        liveNetwork = collectedSnapshot.metrics.network
        liveNetworkSamples = [collectedSnapshot.metrics.network]
        snapshot = collectedSnapshot
        statusMessage = "Collected a fresh policy scan and live snapshot."
        showStatusBanner = true
        notifyUI()
        DashboardCollectDiagnostics.log("collect: snapshot applied to view model")
        onCollectComplete?()
        startMonitoringIfNeeded()
    }

    func markCollectFailed(_ error: Error) {
        defer {
            isCollecting = false
            notifyUI()
        }
        statusMessage = "Collection failed: \(error.localizedDescription)"
        showStatusBanner = true
        notifyUI()
    }

    func collectSnapshotAsync() async {
        let unlocked = await DashboardGTKBridge.runOnMain { self.cacheIsUnlockedForCollect() }
        DashboardCollectDiagnostics.log(
            "collect async entry unlocked=\(unlocked) collecting=\(await DashboardGTKBridge.runOnMain { self.isCollecting }) snapshot=\(await DashboardGTKBridge.runOnMain { self.snapshot != nil })"
        )
        guard unlocked else {
            await DashboardGTKBridge.runOnMain {
                self.statusMessage = "Cache is locked. Unlock before collecting a snapshot."
                self.showStatusBanner = true
                self.notifyUI()
            }
            return
        }

        await DashboardGTKBridge.runOnMain {
            if self.isCollecting {
                DashboardCollectDiagnostics.log("collect: clearing stuck isCollecting flag")
                self.isCollecting = false
            }
            self.isCollecting = true
            self.statusMessage = "Collecting snapshot…"
            self.showStatusBanner = true
            self.notifyUI()
        }
        DashboardCollectDiagnostics.log("collect started")
        defer {
            Task { await DashboardGTKBridge.runOnMain {
                self.isCollecting = false
                self.notifyUI()
            }}
        }

        let startedAt = Date()
        do {
            DashboardCollectDiagnostics.log("collect: policy scan…")
            let baseSnapshot = try await NetworkSamplingService.shared.fullSnapshot()
            DashboardCollectDiagnostics.log(
                "collect: policy scan done (score=\(baseSnapshot.score), elapsed=\(String(format: "%.1f", Date().timeIntervalSince(startedAt)))s)"
            )

            DashboardCollectDiagnostics.log("collect: visible sockets…")
            let sockets = await NetworkSamplingService.shared.visibleSockets()
            DashboardCollectDiagnostics.log("collect: sockets=\(sockets.count)")

            let prepContext = await DashboardGTKBridge.runOnMain {
                (self.previousConnections, self.recentActivity)
            }
            let socketUpdate = await Task.detached {
                DashboardSamplingPipeline.prepareSocketUIUpdate(
                    connections: sockets,
                    previousFingerprint: nil,
                    previousConnections: prepContext.0,
                    recentActivity: prepContext.1,
                    force: true
                )
            }.value

            let collectedSnapshot = baseSnapshot.withNetworkActivity(
                Array((socketUpdate?.recentActivity ?? prepContext.1).prefix(NetworkSamplingLimits.maxActivityEvents))
            )

            try await Task.detached {
                try DashboardCacheLocations.writeSnapshot(collectedSnapshot)
            }.value
            DashboardCollectDiagnostics.log("collect: cache write ok")

            await DashboardGTKBridge.runOnMain {
                if let socketUpdate {
                    self.visibleSockets = socketUpdate.connections
                    self.recentActivity = socketUpdate.recentActivity
                    self.lastSocketSampleAt = Date()
                    self.socketSearchIndex = socketUpdate.index
                    self.lastSocketFingerprint = socketUpdate.fingerprint
                    self.previousConnections = socketUpdate.previousConnections
                }
                self.liveNetwork = baseSnapshot.metrics.network
                self.liveNetworkSamples = [baseSnapshot.metrics.network]
                self.snapshot = collectedSnapshot
                self.statusMessage = "Collected a fresh policy scan and live snapshot."
                self.showStatusBanner = true
                self.notifyUI()
            }
            DashboardCollectDiagnostics.log("collect: snapshot applied to view model")
            await DashboardGTKBridge.runOnMain {
                self.onCollectComplete?()
            }
        } catch {
            DashboardCollectDiagnostics.log("collect failed: \(error)")
            await DashboardGTKBridge.runOnMain {
                self.statusMessage = "Collection failed: \(error.localizedDescription)"
                self.showStatusBanner = true
                self.notifyUI()
            }
        }
    }

    func applyLiveSocketUpdate(_ update: DashboardSamplingPipeline.SocketUIUpdate) {
        lastSocketFingerprint = update.fingerprint
        previousConnections = update.previousConnections
        visibleSockets = update.connections
        socketSearchIndex = update.index
        recentActivity = update.recentActivity
        lastSocketSampleAt = Date()
        notifyUI()
    }

    func applyTelemetrySnapshot(_ refreshedSnapshot: InsightSnapshot) {
        snapshot = refreshedSnapshot
        if liveNetwork == nil {
            liveNetwork = refreshedSnapshot.metrics.network
        }
        notifyUI()
    }

    func prepareCacheSessionIfNeeded() {
        guard !CacheSecurityCoordinator.isPasswordProtectionEnabled() else { return }
        do {
            _ = try SnapshotCacheKeyStore.encryptionKey(
                forCacheDirectory: CacheSecurityCoordinator.primaryCacheDirectory()
            )
            DashboardCollectDiagnostics.log("cache session key ready")
        } catch {
            DashboardCollectDiagnostics.log("cache session key failed: \(error)")
        }
    }

    private func reloadCachedSnapshot(security: DashboardSecurityState) {
        guard security.isUnlocked || CacheSecurityCoordinator.isUnlocked() else { return }
        do {
            let loaded = try DashboardCacheLocations.readSnapshot()
            snapshot = loaded
            recentActivity = Array(loaded.networkActivity.prefix(NetworkSamplingLimits.maxActivityEvents))
            liveNetwork = loaded.metrics.network
            liveNetworkSamples = [loaded.metrics.network]
            statusMessage = "Loaded the latest cached snapshot."
            showStatusBanner = true
            notifyUI()
            DashboardCollectDiagnostics.log("reload cache: ok score=\(loaded.score)")
        } catch SnapshotCacheLockError.locked {
            DashboardCollectDiagnostics.log("reload cache: locked")
        } catch CocoaError.fileReadNoSuchFile {
            DashboardCollectDiagnostics.log("reload cache: no file")
        } catch {
            DashboardCollectDiagnostics.log("reload cache failed: \(error)")
        }
    }
}
