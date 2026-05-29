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
    private var model: DashboardViewModel { .shared }

    @State private var security: DashboardSecurityState
    @State private var screen: DashboardScreen
    @State private var securityActionInFlight = false
    @State private var preferencesVisible = false
    @State private var inspectorVisible = false
    @State private var selectedRecord: NetworkRecordSelection?

    @State private var announcedSocketLogPath = false
    @State private var isRefreshingTelemetry = false
    @State private var isRefreshingLiveNetwork = false
    @State private var isRefreshingSockets = false
    @State private var isMonitoring = false
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
        let _ = model.uiGeneration.generation
        OperationsRoot(onFirstAppear: performLaunchBootstrap) {
            screenContent
        }
    }

    @ViewBuilder
    private var screenContent: Body {
        switch screen {
        case .unlock:
            unlockScreen
        case .passwordSetup:
            passwordSetupScreen
        case .main:
            dashboardScreen
        }
    }

    private func performLaunchBootstrap() {
        model.registerDelayedBootstrap(performLaunchBootstrap)
        model.onCollectComplete = {
            startMonitoring()
        }
        model.performLaunchBootstrap(security: &security, screen: &screen)
        if model.snapshot != nil, !isMonitoring {
            startMonitoring()
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
                ToolbarActivitySlot(active: model.isCollecting || isRefreshingLiveNetwork || isRefreshingSockets)
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
                    subtitle: model.snapshot.map { "\($0.score)/100 · \($0.host.hostName)" } ?? "Ready to collect",
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
        if let snapshot = model.snapshot {
            let network = model.liveNetwork ?? snapshot.metrics.network
            let speedSamples = model.liveNetworkSamples.isEmpty ? [network] : model.liveNetworkSamples
            ScrollView {
                VStack {
                    releaseUpdateBanner
                    if model.showStatusBanner, !model.statusMessage.isEmpty {
                        DashboardStatusBanner(
                            message: model.statusMessage,
                            visible: true,
                            onDismiss: dismissStatus
                        )
                    }
                    DashboardOperationsPage(
                        snapshot: snapshot,
                        network: network,
                        speedSamples: speedSamples,
                        visibleSockets: model.visibleSockets,
                        socketSearchIndex: model.socketSearchIndex,
                        recentActivity: model.recentActivity,
                        lastSocketSampleAt: model.lastSocketSampleAt,
                        isCollecting: model.isCollecting,
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
                    if model.showStatusBanner, !model.statusMessage.isEmpty {
                        DashboardStatusBanner(
                            message: model.statusMessage,
                            visible: true,
                            onDismiss: dismissStatus
                        )
                    }
                    let network = model.liveNetwork ?? .unavailable
                    let speedSamples = model.liveNetworkSamples.isEmpty ? [network] : model.liveNetworkSamples
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
                        DashboardDetailRow(label: "Poll", value: DashboardFormatting.pollText(model.lastSocketSampleAt))
                    }
                    .style("operations-empty-connectivity")
                    Text("No policy snapshot yet")
                        .title2()
                    Text("Live network sampling is running. Collect a snapshot for health score, security findings, and the full socket console.")
                        .dimLabel()
                        .padding()
                    Button(model.isCollecting ? "Collecting…" : "Collect snapshot") {
                        DashboardCollectDiagnostics.log("collect button tapped (expect COLLECT_V3 next)")
                        model.startCollect()
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
            observedAt: model.lastSocketSampleAt,
            network: model.liveNetwork ?? model.snapshot?.metrics.network
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
        if model.snapshot == nil {
            model.statusMessage = "No cached snapshot on disk. Collecting a fresh snapshot…"
            model.showStatusBanner = true
            model.uiGeneration.bump()
        }
        Task { await checkForReleaseUpdate() }
    }

    private func resetAfterLock() {
        backgroundWork.stop()
        model.clearDashboardData()
        isMonitoring = false
        var next = security
        next.refresh()
        security = next
        screen = .unlock
        unlockAllowsCancel = voluntaryLockUndoKey != nil
        model.statusMessage = "Cache locked. Enter your password to continue."
        model.showStatusBanner = true
        model.uiGeneration.bump()
    }

    private func reloadCachedSnapshot() {
        guard security.isUnlocked || CacheSecurityCoordinator.isUnlocked() else { return }
        do {
            let loaded = try DashboardCacheLocations.readSnapshot()
            model.applySnapshot(loaded)
            model.statusMessage = "Loaded the latest cached snapshot."
            model.showStatusBanner = true
            model.uiGeneration.bump()
        } catch SnapshotCacheLockError.locked {
            CacheSecurityCoordinator.lock()
            reconcileSecurityWithScreen(bootstrapIfUnlocked: false)
            model.statusMessage = "Cache is locked. Enter your password to decrypt stored data."
            model.showStatusBanner = true
            model.uiGeneration.bump()
        } catch CocoaError.fileReadNoSuchFile {
            model.statusMessage = "No encrypted snapshot found yet. Collecting a fresh snapshot…"
            model.showStatusBanner = true
            model.uiGeneration.bump()
        } catch {
            model.statusMessage = "Unable to read cache: \(error.localizedDescription)"
            model.showStatusBanner = true
            model.uiGeneration.bump()
        }
    }

    private func collectSnapshot() {
        model.startCollect()
    }

    private func startMonitoring() {
        guard security.isUnlocked else { return }
        isMonitoring = true
        if model.snapshot == nil {
            model.startCollect()
        }

        backgroundWork.start(
            canWork: { security.isUnlocked && isMonitoring },
            onLiveNetworkRefresh: { await refreshLiveNetworkAsync() },
            onSocketRefresh: { await refreshSocketTableAsync() },
            onTelemetryRefresh: { await refreshTelemetryAsync() },
            onSnapshotCollect: { await model.collectSnapshotAsync() }
        )
    }

    private func refreshTelemetryAsync() async {
        guard security.isUnlocked, !isRefreshingTelemetry, let currentSnapshot = model.snapshot else {
            return
        }
        isRefreshingTelemetry = true
        defer { isRefreshingTelemetry = false }

        do {
            let activitySnapshot = await UIViewDeferral.readOnMain { model.recentActivity }
            let refreshedSnapshot = try await Task.detached {
                let refreshedMetrics = try await NetworkSamplingService.shared.collectMetrics()
                return DashboardSamplingPipeline.buildTelemetrySnapshot(
                    current: currentSnapshot,
                    metrics: refreshedMetrics,
                    recentActivity: activitySnapshot
                )
            }.value
            await UIViewDeferral.readOnMain {
                model.applyTelemetrySnapshot(refreshedSnapshot)
            }
        } catch {
            await UIViewDeferral.readOnMain {
                model.statusMessage = "Telemetry refresh failed: \(error.localizedDescription)"
                model.showStatusBanner = true
                model.uiGeneration.bump()
            }
        }
    }

    private func refreshLiveNetworkAsync() async {
        guard security.isUnlocked else { return }
        isRefreshingLiveNetwork = true
        defer { isRefreshingLiveNetwork = false }

        let baseline = await UIViewDeferral.readOnMain {
            model.liveNetwork ?? model.snapshot?.metrics.network ?? .unavailable
        }
        let establishedCount = await UIViewDeferral.readOnMain {
            model.visibleSockets.filter { $0.state == .established }.count
        }
        do {
            let network = try await DashboardSamplingPipeline.pollLiveNetwork(
                preserving: baseline,
                establishedTCPCount: establishedCount
            )
            await UIViewDeferral.readOnMain {
                model.applyLiveNetwork(network)
            }
        } catch {
            await UIViewDeferral.readOnMain {
                model.statusMessage = "Network refresh failed: \(error.localizedDescription)"
                model.showStatusBanner = true
                model.uiGeneration.bump()
            }
        }
    }

    private func refreshSocketTableAsync() async {
        guard security.isUnlocked else { return }
        isRefreshingSockets = true
        defer { isRefreshingSockets = false }

        let baseline = await UIViewDeferral.readOnMain {
            model.liveNetwork ?? model.snapshot?.metrics.network ?? .unavailable
        }
        let establishedCount = await UIViewDeferral.readOnMain {
            model.visibleSockets.filter { $0.state == .established }.count
        }
        do {
            let sample = try await DashboardSamplingPipeline.pollNetwork(
                preserving: baseline,
                establishedTCPCount: establishedCount
            )
            await UIViewDeferral.readOnMain {
                model.applyLiveNetwork(sample.network)
            }

            let fingerprintSnapshot = await UIViewDeferral.readOnMain { model.lastSocketFingerprint }
            let previousConnectionsSnapshot = await UIViewDeferral.readOnMain { model.previousConnections }
            let activitySnapshot = await UIViewDeferral.readOnMain { model.recentActivity }
            let socketUpdate = await Task.detached {
                DashboardSamplingPipeline.prepareSocketUIUpdate(
                    connections: sample.connections,
                    previousFingerprint: fingerprintSnapshot,
                    previousConnections: previousConnectionsSnapshot,
                    recentActivity: activitySnapshot
                )
            }.value
            if let socketUpdate {
                await UIViewDeferral.readOnMain {
                    applySocketUIUpdate(socketUpdate, source: "socket-poll")
                }
            }
        } catch {
            await UIViewDeferral.readOnMain {
                model.statusMessage = "Socket refresh failed: \(error.localizedDescription)"
                model.showStatusBanner = true
                model.uiGeneration.bump()
            }
        }
    }

    private func applyTelemetrySnapshot(_ refreshedSnapshot: InsightSnapshot) {
        model.applyTelemetrySnapshot(refreshedSnapshot)
    }

    private func applySocketUIUpdate(_ update: DashboardSamplingPipeline.SocketUIUpdate, source: String) {
        announceSocketLogIfNeeded()
        let connections = update.connections
        let fingerprint = update.fingerprint
        let index = update.index
        let activity = update.recentActivity
        Task.detached {
            SocketConsoleDiagnostics.logRefresh(
                source: source,
                connections: connections,
                fingerprint: fingerprint,
                appliedToUI: true
            )
        }
        UIViewDeferral.run {
            model.applyLiveSocketUpdate(update)
        }
    }

    private func announceSocketLogIfNeeded() {
        guard SocketConsoleDiagnostics.isEnabled, !announcedSocketLogPath else { return }
        announcedSocketLogPath = true
        model.statusMessage = "Socket debug log: \(SocketConsoleDiagnostics.logFileURL.path)"
        model.showStatusBanner = true
        model.uiGeneration.bump()
    }

    private func postStatus(_ message: String) {
        DashboardCollectDiagnostics.log("status: \(message)")
        UIViewDeferral.run {
            model.statusMessage = message
            model.showStatusBanner = true
            model.uiGeneration.bump()
        }
    }

    private func dismissStatus() {
        UIViewDeferral.run {
            model.showStatusBanner = false
            model.statusMessage = ""
            model.uiGeneration.bump()
        }
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
