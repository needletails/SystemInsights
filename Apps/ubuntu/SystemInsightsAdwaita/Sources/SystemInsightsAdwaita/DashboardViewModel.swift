import Foundation
import SystemInsightCore

/// Process-wide dashboard state. GTK recreates ``DashboardView``; this singleton keeps collect/bootstrap alive.
@MainActor
final class DashboardViewModel {
    static let shared = DashboardViewModel()

    weak var renderState: DashboardRenderState?

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
    var onCollectComplete: (() -> Void)?

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
    }

    func bind(renderState: DashboardRenderState) {
        self.renderState = renderState
    }

    private func notifyUI() {
        renderState?.bump()
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
                "dashboard bootstrap skipped (didBootstrap=true snapshot=\(snapshot != nil))"
            )
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
        let unlocked = !CacheSecurityCoordinator.isPasswordProtectionEnabled()
            || CacheSecurityCoordinator.isUnlocked()
        DashboardCollectDiagnostics.log(
            "collect async entry unlocked=\(unlocked) collecting=\(isCollecting) snapshot=\(snapshot != nil)"
        )
        guard unlocked else {
            statusMessage = "Cache is locked. Unlock before collecting a snapshot."
            showStatusBanner = true
            notifyUI()
            return
        }
        if isCollecting {
            DashboardCollectDiagnostics.log("collect: clearing stuck isCollecting flag")
            isCollecting = false
            notifyUI()
        }

        isCollecting = true
        statusMessage = "Collecting snapshot…"
        showStatusBanner = true
        notifyUI()
        DashboardCollectDiagnostics.log("collect started")
        defer {
            isCollecting = false
            notifyUI()
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

            let previousConnectionsSnapshot = previousConnections
            let activitySnapshot = recentActivity
            let socketUpdate = await Task.detached {
                DashboardSamplingPipeline.prepareSocketUIUpdate(
                    connections: sockets,
                    previousFingerprint: nil,
                    previousConnections: previousConnectionsSnapshot,
                    recentActivity: activitySnapshot,
                    force: true
                )
            }.value
            if let socketUpdate {
                visibleSockets = socketUpdate.connections
                recentActivity = socketUpdate.recentActivity
                lastSocketSampleAt = Date()
                socketSearchIndex = socketUpdate.index
                lastSocketFingerprint = socketUpdate.fingerprint
                previousConnections = socketUpdate.previousConnections
            }
            notifyUI()
            liveNetwork = baseSnapshot.metrics.network
            liveNetworkSamples = [baseSnapshot.metrics.network]
            let collectedSnapshot = baseSnapshot.withNetworkActivity(
                Array(recentActivity.prefix(NetworkSamplingLimits.maxActivityEvents))
            )
            snapshot = collectedSnapshot
            notifyUI()
            DashboardCollectDiagnostics.log("collect: snapshot applied to view model")
            do {
                try await Task.detached {
                    try DashboardCacheLocations.writeSnapshot(collectedSnapshot)
                }.value
                DashboardCollectDiagnostics.log("collect: cache write ok")
                statusMessage = "Collected a fresh policy scan and live snapshot."
            } catch {
                DashboardCollectDiagnostics.log("collect: cache write failed: \(error)")
                statusMessage =
                    "Snapshot collected but could not save to cache: \(error.localizedDescription)"
            }
            showStatusBanner = true
            notifyUI()
            onCollectComplete?()
        } catch {
            DashboardCollectDiagnostics.log("collect failed: \(error)")
            statusMessage = "Collection failed: \(error.localizedDescription)"
            showStatusBanner = true
            notifyUI()
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

    func applyLiveNetwork(_ network: NetworkMetrics, samples: [NetworkMetrics]) {
        liveNetwork = network
        liveNetworkSamples = samples
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
        } catch SnapshotCacheLockError.locked {
            DashboardCollectDiagnostics.log("reload cache: locked")
        } catch CocoaError.fileReadNoSuchFile {
            DashboardCollectDiagnostics.log("reload cache: no file")
        } catch {
            DashboardCollectDiagnostics.log("reload cache failed: \(error)")
        }
    }
}
