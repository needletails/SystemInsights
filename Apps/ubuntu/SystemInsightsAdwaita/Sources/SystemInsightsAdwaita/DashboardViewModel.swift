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

    private(set) var isMonitoring = false
    var isRefreshingTelemetry = false
    var isRefreshingLiveNetwork = false
    var isRefreshingSockets = false

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
        let ratesChanged = abs(last.receivedBytesPerSecond - network.receivedBytesPerSecond) >= 64
            || abs(last.sentBytesPerSecond - network.sentBytesPerSecond) >= 64
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
        startMonitoringIfNeeded()
        if snapshot == nil {
            statusMessage = "No cached snapshot on disk. Collecting a fresh snapshot…"
            showStatusBanner = true
            notifyUI()
            startCollect()
        }
    }

    func startMonitoringIfNeeded() {
        guard cacheIsUnlockedForCollect() else { return }
        guard !isMonitoring else { return }
        isMonitoring = true
        DashboardCollectDiagnostics.log("monitoring started")
        Task.detached {
            await DashboardSamplingScheduler.shared.startMonitoring()
        }
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        Task.detached {
            await DashboardSamplingScheduler.shared.stopMonitoring()
        }
        DashboardCollectDiagnostics.log("monitoring stopped")
    }

    func startCollect() {
        Task.detached {
            await DashboardSamplingScheduler.shared.requestCollect()
        }
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
