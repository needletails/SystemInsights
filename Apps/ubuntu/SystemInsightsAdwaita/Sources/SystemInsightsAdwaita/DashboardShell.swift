import Adwaita
import Foundation
import SystemInsightCore

#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

@MainActor
struct DashboardView: @preconcurrency View {
    @State private var security: DashboardSecurityState
    @State private var screen: DashboardScreen
    @State private var securityActionInFlight = false
    @State private var preferencesVisible = false
    @State private var showStatusBanner = false
    @State private var inspectorVisible = false
    @State private var selectedRecord: NetworkRecordSelection?

    @State private var snapshot: InsightSnapshot?
    @State private var recentActivity: [NetworkActivityEvent] = []
    @State private var liveNetwork: NetworkMetrics?
    @State private var liveNetworkSamples: [NetworkMetrics] = []
    @State private var visibleSockets: [VisibleSocket] = []
    @State private var socketSearchIndex: [SocketConsoleFilter.IndexEntry] = []
    @State private var lastSocketSampleAt: Date?
    @State private var lastSocketFingerprint: UInt64?
    @State private var announcedSocketLogPath = false
    @State private var statusMessage = ""
    @State private var isCollecting = false
    @State private var isRefreshingTelemetry = false
    @State private var isRefreshingLiveNetwork = false
    @State private var isRefreshingSockets = false
    @State private var lastGraphSampleAt: Date?
    @State private var isMonitoring = false
    @State private var previousConnections: [String: VisibleSocket]?
    @State private var backgroundWork = DashboardBackgroundCoordinator()
    /// Session key stashed when the user voluntarily locks so Cancel can restore the dashboard.
    @State private var voluntaryLockUndoKey: SymmetricKey?
    @State private var unlockAllowsCancel = false
    @State private var passwordSetupAllowsCancel = false
    @State private var pendingReleaseUpdate: ReleaseUpdatePresentation?

    init() {
        let initialSecurity = DashboardSecurityState()
        _security = State(wrappedValue: initialSecurity)
        _screen = State(wrappedValue: DashboardScreen.from(security: initialSecurity))
    }

    var view: Body {
        OperationsRoot {
            switch screen {
            case .unlock:
                unlockScreen
            case .passwordSetup:
                passwordSetupScreen
            case .main:
                dashboardScreen
            }
        }
        .onAppear {
            UIViewDeferral.run {
                DashboardCollectDiagnostics.log(
                    "dashboard appeared (flatpak=\(ProcessInfo.processInfo.environment["FLATPAK_ID"] ?? "no"))"
                )
                reconcileSecurityWithScreen(bootstrapIfUnlocked: true)
            }
        }
    }

    @ViewBuilder
    private var unlockScreen: Body {
        CacheUnlockPanel(
            errorMessage: security.errorMessage,
            onSubmit: submitUnlock
        )
        .topToolbar {
            SecurityScreenToolbar(
                subtitle: "Encrypted cache",
                title: "System Insights",
                showsCancel: unlockAllowsCancel,
                onCancel: cancelVoluntaryUnlock
            )
        }
        .extendContentToTopEdge(false)
    }

    @ViewBuilder
    private var passwordSetupScreen: Body {
        CachePasswordSetupPanel(
            mode: security.passwordSetupMode,
            errorMessage: security.errorMessage,
            onSubmit: submitPasswordSetup
        )
        .topToolbar {
            SecurityScreenToolbar(
                subtitle: passwordSetupToolbarSubtitle,
                title: "System Insights",
                showsCancel: passwordSetupAllowsCancel,
                onCancel: cancelPasswordSetup
            )
        }
        .extendContentToTopEdge(false)
    }

    private var passwordSetupToolbarSubtitle: String {
        switch security.passwordSetupMode {
        case .enable: "Enable protection"
        case .change: "Change password"
        }
    }

    @ViewBuilder
    private var dashboardScreen: Body {
        dashboardMainContent
        .topToolbar {
            HeaderBar {
                Box { }
                    .frame(minWidth: 8)
                ToolbarGlyphButton(
                    glyph: OperationsGlyphs.symbol(for: .default(icon: .viewRefresh)),
                    tooltip: "Reload cache",
                    action: reloadCachedSnapshot
                )
                ToolbarGlyphButton(
                    glyph: OperationsGlyphs.symbol(for: .default(icon: .systemRun)),
                    tooltip: "Scan now",
                    action: {
                        UIViewDeferral.run { collectSnapshot() }
                    }
                )
            } end: {
                ToolbarActivitySlot(active: isCollecting || isRefreshingLiveNetwork || isRefreshingSockets)
                ToolbarGlyphButton(
                    glyph: OperationsGlyphs.symbol(for: .default(icon: .preferencesSystem)),
                    tooltip: "Settings",
                    action: { preferencesVisible = true }
                )
                if security.isPasswordProtectionEnabled {
                    ToolbarGlyphButton(
                        glyph: OperationsGlyphs.symbol(for: .default(icon: .systemLockScreen)),
                        tooltip: "Lock cache",
                        action: lockFromToolbar
                    )
                }
            }
            .headerBarTitle {
                WindowTitle(
                    subtitle: snapshot.map { "\($0.score)/100 · \($0.host.hostName)" } ?? "Ready to collect",
                    title: "Network Operations"
                )
            }
        }
        .extendContentToTopEdge(false)
        .dialog(
            visible: $inspectorVisible,
            title: "Connection inspector",
            id: "connection-inspector",
            width: 660,
            height: 620
        ) {
            if let selectedRecord {
                OperationsInspectorDialog(
                    selection: selectedRecord,
                    context: inspectorContext
                ) {
                    dismissInspector()
                }
            }
        }
        .preferencesDialog(visible: $preferencesVisible)
        .preferencesPage("Privacy", icon: .default(icon: .securityHigh)) { page in
            OperationsPreferencesContent.privacyPage(
                page,
                security: security,
                onChangePassword: {
                    UIViewDeferral.run {
                        preferencesVisible = false
                        presentPasswordSetupFromSettings(mode: .change)
                    }
                },
                onEnablePassword: {
                    UIViewDeferral.run {
                        preferencesVisible = false
                        presentPasswordSetupFromSettings(mode: .enable)
                    }
                },
                onLockNow: {
                    UIViewDeferral.run {
                        preferencesVisible = false
                        lockFromUserAction()
                    }
                }
            )
        }
    }

    @ViewBuilder
    private var dashboardMainContent: Body {
        if let snapshot {
            ScrollView {
                VStack {
                    releaseUpdateBanner
                    if showStatusBanner, !statusMessage.isEmpty {
                        DashboardStatusBanner(
                            message: statusMessage,
                            visible: true,
                            onDismiss: dismissStatus
                        )
                    }
                    let network = liveNetwork ?? snapshot.metrics.network
                    let speedSamples = liveNetworkSamples.isEmpty ? [network] : liveNetworkSamples
                    DashboardOperationsPage(
                        snapshot: snapshot,
                        network: network,
                        speedSamples: speedSamples,
                        visibleSockets: visibleSockets,
                        socketSearchIndex: socketSearchIndex,
                        recentActivity: recentActivity,
                        lastSocketSampleAt: lastSocketSampleAt,
                        isCollecting: isCollecting,
                        onScan: collectSnapshot,
                        onSelectSocket: { presentInspector(.socket($0)) },
                        onSelectEvent: { presentInspector(.event($0)) }
                    )
                    .style("operations-page-content")
                    .frame(minWidth: DashboardWindowLayout.contentMinWidth)
                    .frame(minHeight: DashboardWindowLayout.contentMinHeight)
                }
                .hexpand()
            }
            .hexpand()
            .vexpand()
        } else {
            ScrollView {
                VStack {
                    releaseUpdateBanner
                    if showStatusBanner, !statusMessage.isEmpty {
                        DashboardStatusBanner(
                            message: statusMessage,
                            visible: true,
                            onDismiss: dismissStatus
                        )
                    }
                    let network = liveNetwork ?? .unavailable
                    let speedSamples = liveNetworkSamples.isEmpty ? [network] : liveNetworkSamples
                    LiveTrafficPanel(network: network, speedSamples: speedSamples)
                        .style("operations-traffic-panel")
                        .frame(minWidth: DashboardWindowLayout.contentMinWidth)
                    DashboardSurface(title: "CONNECTIVITY", icon: .default(icon: .networkWireless)) {
                        DashboardDetailRow(
                            label: "Interface",
                            value: network.interfaceName ?? "Waiting for first sample…"
                        )
                        DashboardDetailRow(label: "Active TCP", value: "\(network.activeTCPConnections)")
                        DashboardDetailRow(
                            label: "Latency",
                            value: DashboardFormatting.latency(network.latencyMilliseconds)
                        )
                        DashboardDetailRow(label: "Poll", value: DashboardFormatting.pollText(lastSocketSampleAt))
                    }
                    .style("operations-empty-connectivity")
                    Text("No policy snapshot yet")
                        .title2()
                    Text("Live network sampling is running. Collect a snapshot for health score, security findings, and the full socket console.")
                        .dimLabel()
                        .padding()
                    Button(isCollecting ? "Collecting…" : "Collect snapshot") {
                        UIViewDeferral.run {
                            DashboardCollectDiagnostics.log("collect button tapped")
                            Task { @MainActor in
                                await collectSnapshotAsync()
                            }
                        }
                    }
                    .suggested()
                    .pill()
                    .frame(maxWidth: 280)
                }
                .style("operations-empty-state")
                .frame(minWidth: DashboardWindowLayout.contentMinWidth)
            }
            .hexpand()
            .vexpand()
        }
    }

    private var inspectorContext: SocketInspectorContext {
        SocketInspectorContext(
            observedAt: lastSocketSampleAt,
            network: liveNetwork ?? snapshot?.metrics.network
        )
    }

    private func submitUnlock(password: String) {
        UIViewDeferral.run {
            guard !securityActionInFlight else { return }
            securityActionInFlight = true
            defer { securityActionInFlight = false }
            var next = security
            guard next.attemptUnlock(password: password) else {
                security = next
                return
            }
            next.syncAfterAuthentication()
            guard next.isUnlocked else {
                security = next
                return
            }
            clearVoluntaryLockUndo()
            security = next
            screen = .main
            bootstrapAfterUnlock()
        }
    }

    private func lockFromToolbar() {
        UIViewDeferral.run { lockFromUserAction() }
    }

    private func lockFromUserAction() {
        stashVoluntaryLockUndoKeyIfNeeded()
        security.lock(onLocked: resetAfterLock)
    }

    private func stashVoluntaryLockUndoKeyIfNeeded() {
        voluntaryLockUndoKey = SnapshotCacheSession.syncKey
        unlockAllowsCancel = voluntaryLockUndoKey != nil
    }

    private func clearVoluntaryLockUndo() {
        voluntaryLockUndoKey = nil
        unlockAllowsCancel = false
    }

    private func cancelVoluntaryUnlock() {
        guard let undoKey = voluntaryLockUndoKey else { return }
        CacheSecurityCoordinator.restoreUnlockedSession(undoKey)
        clearVoluntaryLockUndo()
        var next = security
        next.syncAfterAuthentication()
        security = next
        screen = .main
        bootstrapAfterUnlock()
    }

    private func presentPasswordSetupFromSettings(mode: DashboardSecurityState.PasswordSetupMode) {
        passwordSetupAllowsCancel = true
        var next = security
        next.presentPasswordSetup(mode: mode)
        security = next
        screen = .passwordSetup
    }

    private func cancelPasswordSetup() {
        passwordSetupAllowsCancel = false
        var next = security
        next.refresh()
        security = next
        screen = .main
        if security.isUnlocked {
            bootstrapAfterUnlock()
        }
    }

    private func submitPasswordSetup(current: String, password: String, confirm: String) {
        UIViewDeferral.run {
            guard !securityActionInFlight else { return }
            securityActionInFlight = true
            defer { securityActionInFlight = false }
            let mode = security.passwordSetupMode
            var next = security
            let succeeded: Bool
            switch mode {
            case .enable:
                succeeded = next.attemptEnablePassword(password: password, confirmPassword: confirm)
            case .change:
                succeeded = next.attemptChangePassword(
                    currentPassword: current,
                    password: password,
                    confirmPassword: confirm
                )
            }
            guard succeeded else {
                security = next
                return
            }
            next.syncAfterAuthentication()
            guard next.isUnlocked else {
                security = next
                return
            }
            passwordSetupAllowsCancel = false
            security = next
            screen = .main
            bootstrapAfterUnlock()
        }
    }

    private func reconcileSecurityWithScreen(bootstrapIfUnlocked: Bool) {
        var next = security
        next.refresh()
        security = next
        let nextScreen = DashboardScreen.from(security: next)
        if screen != nextScreen {
            screen = nextScreen
        }

        guard bootstrapIfUnlocked else { return }
        if security.isUnlocked {
            bootstrapAfterUnlock()
        } else {
            backgroundWork.stop()
            isMonitoring = false
        }
    }

    private func presentInspector(_ record: NetworkRecordSelection) {
        SecurityUIUpdate.afterCurrentEvent {
            selectedRecord = record
            inspectorVisible = true
        }
    }

    private func dismissInspector() {
        UIViewDeferral.run {
            inspectorVisible = false
            selectedRecord = nil
        }
    }

    private func bootstrapAfterUnlock() {
        DashboardCollectDiagnostics.log("bootstrap after unlock")
        reloadCachedSnapshot()
        startMonitoring()
        if snapshot == nil {
            postStatus("No cached snapshot on disk. Collecting a fresh snapshot…")
            showStatusBanner = true
        }
        Task { await checkForReleaseUpdate() }
    }

    private func resetAfterLock() {
        backgroundWork.stop()
        snapshot = nil
        recentActivity = []
        liveNetwork = nil
        liveNetworkSamples = []
        visibleSockets = []
        socketSearchIndex = []
        lastSocketSampleAt = nil
        lastSocketFingerprint = nil
        lastGraphSampleAt = nil
        isMonitoring = false
        var next = security
        next.refresh()
        security = next
        screen = .unlock
        unlockAllowsCancel = voluntaryLockUndoKey != nil
        postStatus("Cache locked. Enter your password to continue.")
    }

    private func reloadCachedSnapshot() {
        guard security.isUnlocked || CacheSecurityCoordinator.isUnlocked() else { return }
        do {
            let loaded = try DashboardCacheLocations.readSnapshot()
            snapshot = loaded
            recentActivity = Array(loaded.networkActivity.prefix(NetworkSamplingLimits.maxActivityEvents))
            liveNetwork = loaded.metrics.network
            liveNetworkSamples = [loaded.metrics.network]
            postStatus("Loaded the latest cached snapshot.")
            showStatusBanner = true
        } catch SnapshotCacheLockError.locked {
            CacheSecurityCoordinator.lock()
            reconcileSecurityWithScreen(bootstrapIfUnlocked: false)
            postStatus("Cache is locked. Enter your password to decrypt stored data.")
            showStatusBanner = true
        } catch CocoaError.fileReadNoSuchFile {
            postStatus("No encrypted snapshot found yet. Collecting a fresh snapshot…")
            showStatusBanner = true
        } catch {
            postStatus("Unable to read cache: \(error.localizedDescription)")
            showStatusBanner = true
        }
    }

    private func collectSnapshot() {
        Task { @MainActor in
            await collectSnapshotAsync()
        }
    }

    private func collectSnapshotAsync() async {
        guard security.isUnlocked else {
            postStatus("Cache is locked. Unlock before collecting a snapshot.")
            return
        }
        guard !isCollecting else {
            DashboardCollectDiagnostics.log("collect skipped: already in progress")
            return
        }

        isCollecting = true
        statusMessage = "Collecting snapshot…"
        showStatusBanner = true
        DashboardCollectDiagnostics.log("collect started")
        defer {
            SecurityUIUpdate.afterCurrentEvent {
                isCollecting = false
            }
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

            let activitySnapshot = recentActivity
            let previousConnectionsSnapshot = previousConnections
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
                applySocketUIUpdate(socketUpdate, source: "collect-snapshot")
            }
            lastSocketSampleAt = Date()
            applyNetworkSample(baseSnapshot.metrics.network)
            let collectedSnapshot = baseSnapshot.withNetworkActivity(
                Array(recentActivity.prefix(NetworkSamplingLimits.maxActivityEvents))
            )
            applyCollectedSnapshot(collectedSnapshot)
            do {
                try await Task.detached {
                    try DashboardCacheLocations.writeSnapshot(collectedSnapshot)
                }.value
                DashboardCollectDiagnostics.log("collect: cache write ok")
                postStatus("Collected a fresh policy scan and live snapshot.")
            } catch {
                DashboardCollectDiagnostics.log("collect: cache write failed: \(error)")
                postStatus(
                    "Snapshot collected but could not save to cache: \(error.localizedDescription)"
                )
            }
        } catch {
            DashboardCollectDiagnostics.log("collect failed: \(error)")
            postStatus("Collection failed: \(error.localizedDescription)")
        }
    }

    private func applyCollectedSnapshot(_ collectedSnapshot: InsightSnapshot) {
        snapshot = collectedSnapshot
        SecurityUIUpdate.afterCurrentEvent {
            snapshot = collectedSnapshot
        }
    }

    private func startMonitoring() {
        guard security.isUnlocked else { return }
        isMonitoring = true
        if snapshot == nil {
            collectSnapshot()
        }

        backgroundWork.start(
            canWork: { security.isUnlocked && isMonitoring },
            onLiveNetworkRefresh: { await refreshLiveNetworkAsync() },
            onSocketRefresh: { await refreshSocketTableAsync() },
            onTelemetryRefresh: { await refreshTelemetryAsync() },
            onSnapshotCollect: { await collectSnapshotAsync() }
        )
    }

    private func refreshTelemetryAsync() async {
        guard security.isUnlocked, !isRefreshingTelemetry, let currentSnapshot = snapshot else {
            return
        }
        isRefreshingTelemetry = true
        defer { isRefreshingTelemetry = false }

        do {
            let activitySnapshot = recentActivity
            let refreshedSnapshot = try await Task.detached {
                let refreshedMetrics = try await NetworkSamplingService.shared.collectMetrics()
                return DashboardSamplingPipeline.buildTelemetrySnapshot(
                    current: currentSnapshot,
                    metrics: refreshedMetrics,
                    recentActivity: activitySnapshot
                )
            }.value
            applyTelemetrySnapshot(refreshedSnapshot)
        } catch {
            postStatus("Telemetry refresh failed: \(error.localizedDescription)")
        }
    }

    private func refreshLiveNetworkAsync() async {
        guard security.isUnlocked else { return }
        isRefreshingLiveNetwork = true
        defer { isRefreshingLiveNetwork = false }

        let baseline = await MainActor.run { snapshot?.metrics.network ?? .unavailable }
        let establishedCount = await MainActor.run {
            visibleSockets.filter { $0.state == .established }.count
        }
        do {
            let network = try await DashboardSamplingPipeline.pollLiveNetwork(
                preserving: baseline,
                establishedTCPCount: establishedCount
            )
            applyNetworkSample(network)
        } catch {
            postStatus("Network refresh failed: \(error.localizedDescription)")
        }
    }

    private func refreshSocketTableAsync() async {
        guard security.isUnlocked else { return }
        isRefreshingSockets = true
        defer { isRefreshingSockets = false }

        let baseline = await MainActor.run { snapshot?.metrics.network ?? .unavailable }
        let establishedCount = await MainActor.run {
            visibleSockets.filter { $0.state == .established }.count
        }
        do {
            let sample = try await DashboardSamplingPipeline.pollNetwork(
                preserving: baseline,
                establishedTCPCount: establishedCount
            )
            applyNetworkSample(sample.network)
            lastSocketSampleAt = Date()

            let fingerprintSnapshot = await MainActor.run { lastSocketFingerprint }
            let previousConnectionsSnapshot = await MainActor.run { previousConnections }
            let activitySnapshot = await MainActor.run { recentActivity }
            let socketUpdate = await Task.detached {
                DashboardSamplingPipeline.prepareSocketUIUpdate(
                    connections: sample.connections,
                    previousFingerprint: fingerprintSnapshot,
                    previousConnections: previousConnectionsSnapshot,
                    recentActivity: activitySnapshot
                )
            }.value
            if let socketUpdate {
                applySocketUIUpdate(socketUpdate, source: "socket-poll")
            }
        } catch {
            postStatus("Socket refresh failed: \(error.localizedDescription)")
        }
    }

    private func applyTelemetrySnapshot(_ refreshedSnapshot: InsightSnapshot) {
        UIViewDeferral.run {
            snapshot = refreshedSnapshot
            if liveNetwork == nil {
                liveNetwork = refreshedSnapshot.metrics.network
            }
        }
    }

    private func applySocketUIUpdate(_ update: DashboardSamplingPipeline.SocketUIUpdate, source: String) {
        announceSocketLogIfNeeded()
        let connections = update.connections
        let fingerprint = update.fingerprint
        let index = update.index
        let activity = update.recentActivity
        let previous = update.previousConnections
        Task.detached {
            SocketConsoleDiagnostics.logRefresh(
                source: source,
                connections: connections,
                fingerprint: fingerprint,
                appliedToUI: true
            )
        }
        UIViewDeferral.run {
            lastSocketFingerprint = fingerprint
            previousConnections = previous
            visibleSockets = connections
            socketSearchIndex = index
            recentActivity = activity
        }
    }

    private func announceSocketLogIfNeeded() {
        guard SocketConsoleDiagnostics.isEnabled, !announcedSocketLogPath else { return }
        announcedSocketLogPath = true
        postStatus("Socket debug log: \(SocketConsoleDiagnostics.logFileURL.path)")
        showStatusBanner = true
    }

    private func applyNetworkSample(_ network: NetworkMetrics) {
        UIViewDeferral.run {
            liveNetwork = network
            if shouldAppendLiveNetworkSample(network) {
                liveNetworkSamples.append(network)
                lastGraphSampleAt = Date()
                if liveNetworkSamples.count > NetworkSamplingLimits.maxLiveNetworkSamples {
                    liveNetworkSamples.removeFirst(liveNetworkSamples.count - NetworkSamplingLimits.maxLiveNetworkSamples)
                }
            }
        }
    }

    private func shouldAppendLiveNetworkSample(_ network: NetworkMetrics) -> Bool {
        let now = Date()
        if let lastGraphSampleAt, now.timeIntervalSince(lastGraphSampleAt) >= 2 {
            return true
        }
        guard let last = liveNetworkSamples.last else { return true }
        let ratesChanged = abs(last.receivedBytesPerSecond - network.receivedBytesPerSecond) >= 256
            || abs(last.sentBytesPerSecond - network.sentBytesPerSecond) >= 256
        let contextChanged = last.interfaceName != network.interfaceName
            || last.activeTCPConnections != network.activeTCPConnections
            || last.vpn != network.vpn
            || last.latencyMilliseconds != network.latencyMilliseconds
        return ratesChanged || contextChanged
    }

    private func postStatus(_ message: String) {
        DashboardCollectDiagnostics.log("status: \(message)")
        SecurityUIUpdate.afterCurrentEvent {
            statusMessage = message
            showStatusBanner = true
        }
    }

    private func dismissStatus() {
        showStatusBanner = false
        statusMessage = ""
    }

    @ViewBuilder
    private var releaseUpdateBanner: Body {
        if let pendingReleaseUpdate {
            ReleaseUpdateBanner(presentation: pendingReleaseUpdate) {
                self.pendingReleaseUpdate = nil
            }
        }
    }

    private func checkForReleaseUpdate() async {
        guard security.isUnlocked, screen == .main else { return }
        guard let presentation = await ReleaseUpdateCoordinator.checkForUpdate() else { return }
        UIViewDeferral.run {
            pendingReleaseUpdate = presentation
        }
    }
}
