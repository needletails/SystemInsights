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

    @State private var renderTick = 0
    @State private var security: DashboardSecurityState
    @State private var screen: DashboardScreen
    @State private var securityActionInFlight = false
    @State private var preferencesVisible = false
    @State private var inspectorVisible = false
    @State private var selectedRecord: NetworkRecordSelection?

    @State private var announcedSocketLogPath = false
    @State private var pendingReleaseUpdate: ReleaseUpdatePresentation?
    @State private var unlockAllowsCancel = false
    @State private var passwordSetupAllowsCancel = false
    /// Session key stashed when the user voluntarily locks so Cancel can restore the dashboard.
    @State private var voluntaryLockUndoKey: SymmetricKey?

    init() {
        let initialSecurity = DashboardSecurityState()
        _security = State(wrappedValue: initialSecurity)
        _screen = State(wrappedValue: DashboardScreen.from(security: initialSecurity))
    }

    var view: Body {
        let _ = renderTick
        let _ = model.viewRenderTick
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
        model.onUIDidChange = {
            UIViewDeferral.run {
                renderTick += 1
            }
        }
        model.registerDelayedBootstrap(performLaunchBootstrap)
        model.performLaunchBootstrap(security: &security, screen: &screen)
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
                ToolbarActivitySlot(active: model.isCollecting || model.isRefreshingLiveNetwork || model.isRefreshingSockets)
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
                        UIViewDeferral.run {
                            DashboardCollectDiagnostics.log("collect button tapped (expect COLLECT_V3 next)")
                            model.startCollect()
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
            model.stopMonitoring()
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
        model.startMonitoringIfNeeded()
        if model.snapshot == nil {
            model.statusMessage = "No cached snapshot on disk. Collecting a fresh snapshot…"
            model.showStatusBanner = true
            model.touchUI()
        }
        Task { await checkForReleaseUpdate() }
    }

    private func resetAfterLock() {
        model.clearDashboardData()
        var next = security
        next.refresh()
        security = next
        screen = .unlock
        unlockAllowsCancel = voluntaryLockUndoKey != nil
        model.statusMessage = "Cache locked. Enter your password to continue."
        model.showStatusBanner = true
        model.touchUI()
    }

    private func reloadCachedSnapshot() {
        guard security.isUnlocked || CacheSecurityCoordinator.isUnlocked() else { return }
        do {
            let loaded = try DashboardCacheLocations.readSnapshot()
            model.applySnapshot(loaded)
            model.statusMessage = "Loaded the latest cached snapshot."
            model.showStatusBanner = true
            model.touchUI()
            model.startMonitoringIfNeeded()
        } catch SnapshotCacheLockError.locked {
            CacheSecurityCoordinator.lock()
            reconcileSecurityWithScreen(bootstrapIfUnlocked: false)
            model.statusMessage = "Cache is locked. Enter your password to decrypt stored data."
            model.showStatusBanner = true
            model.touchUI()
        } catch CocoaError.fileReadNoSuchFile {
            model.statusMessage = "No encrypted snapshot found yet. Collecting a fresh snapshot…"
            model.showStatusBanner = true
            model.touchUI()
        } catch {
            model.statusMessage = "Unable to read cache: \(error.localizedDescription)"
            model.showStatusBanner = true
            model.touchUI()
        }
    }

    private func collectSnapshot() {
        model.startCollect()
    }

    private func announceSocketLogIfNeeded() {
        guard SocketConsoleDiagnostics.isEnabled, !announcedSocketLogPath else { return }
        announcedSocketLogPath = true
        model.statusMessage = "Socket debug log: \(SocketConsoleDiagnostics.logFileURL.path)"
        model.showStatusBanner = true
        model.touchUI()
    }

    private func postStatus(_ message: String) {
        DashboardCollectDiagnostics.log("status: \(message)")
        UIViewDeferral.run {
            model.statusMessage = message
            model.showStatusBanner = true
            model.touchUI()
        }
    }

    private func dismissStatus() {
        UIViewDeferral.run {
            model.showStatusBanner = false
            model.statusMessage = ""
            model.touchUI()
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
