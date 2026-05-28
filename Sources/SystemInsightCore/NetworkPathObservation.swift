import Foundation

#if os(macOS)
import Network
#endif

public struct NetworkPathSnapshot: Sendable, Equatable {
    public let generation: UInt64
    public let routedTunnelInterfaces: [String]

    public init(generation: UInt64, routedTunnelInterfaces: [String]) {
        self.generation = generation
        self.routedTunnelInterfaces = routedTunnelInterfaces
    }

    static let empty = NetworkPathSnapshot(generation: 0, routedTunnelInterfaces: [])
}

/// Shared network path observation (macOS). Linux uses time-based VPN refresh only.
public actor NetworkPathObservationService {
    public static let shared = NetworkPathObservationService()

    private static let vpnRefreshInterval: Duration = .seconds(30)

    private var snapshot = NetworkPathSnapshot.empty
    private var monitorTask: Task<Void, Never>?
    private var updateContinuations: [UUID: AsyncStream<NetworkPathSnapshot>.Continuation] = [:]
    private var lastVPNRefreshGeneration: UInt64 = 0
    private var lastVPNRefreshAt: ContinuousClock.Instant?
    #if os(macOS)
    private var pathMonitor: NWPathMonitor?
    private var previousPath: NWPath?
    private var pathMonitorResume: CheckedContinuation<Void, Never>?
    #endif

    private init() {}

    public func ensureRunning() {
        #if os(macOS)
        guard monitorTask == nil else { return }
        monitorTask = Task { await runPathMonitor() }
        #endif
    }

    public func stop() {
        #if os(macOS)
        monitorTask?.cancel()
        monitorTask = nil
        #endif
    }

    public func currentSnapshot() -> NetworkPathSnapshot {
        snapshot
    }

    public func routedTunnelInterfaces() -> [String] {
        snapshot.routedTunnelInterfaces
    }

    public func pathUpdates() -> AsyncStream<NetworkPathSnapshot> {
        AsyncStream { continuation in
            let id = UUID()
            updateContinuations[id] = continuation
            if snapshot.generation > 0 {
                continuation.yield(snapshot)
            }
            continuation.onTermination = { @Sendable _ in
                Task { await self.removeContinuation(id) }
            }
        }
    }

    public func shouldRefreshVPN() -> Bool {
        #if os(macOS)
        if snapshot.generation != lastVPNRefreshGeneration, snapshot.generation > 0 {
            return true
        }
        #endif
        guard let lastVPNRefreshAt else { return true }
        return lastVPNRefreshAt.duration(to: ContinuousClock.now) >= Self.vpnRefreshInterval
    }

    public func noteVPNRefreshed() {
        lastVPNRefreshGeneration = snapshot.generation
        lastVPNRefreshAt = ContinuousClock.now
    }

    #if os(macOS)
    private func runPathMonitor() async {
        let monitor = NWPathMonitor()
        pathMonitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            Task { await self.handlePathUpdate(path) }
        }
        monitor.start(queue: DispatchQueue(label: "SystemInsights.NetworkPath"))

        await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                pathMonitorResume = continuation
            }
        } onCancel: {
            monitor.cancel()
        }

        await completePathMonitor()
    }

    private func completePathMonitor() {
        guard let resume = pathMonitorResume else {
            pathMonitor = nil
            previousPath = nil
            return
        }
        pathMonitorResume = nil
        resume.resume()
        pathMonitor = nil
        previousPath = nil
    }

    private func handlePathUpdate(_ path: NWPath) {
        let tunnels = Self.routedTunnelInterfaces(in: path)
        defer { previousPath = path }
        if previousPath == nil {
            snapshot = NetworkPathSnapshot(generation: 1, routedTunnelInterfaces: tunnels)
            broadcast(snapshot)
            return
        }
        guard path != previousPath else { return }
        let generation = snapshot.generation + 1
        snapshot = NetworkPathSnapshot(generation: generation, routedTunnelInterfaces: tunnels)
        broadcast(snapshot)
    }

    static func routedTunnelInterfaces(in path: NWPath) -> [String] {
        Array(Set(
            path.availableInterfaces.compactMap { interface in
                guard
                    interface.type == .other,
                    isTunnelInterfaceName(interface.name)
                else {
                    return nil
                }
                return interface.name
            }
        )).sorted()
    }

    private static func isTunnelInterfaceName(_ name: String) -> Bool {
        ["utun", "ppp", "ipsec"].contains { prefix in
            name.hasPrefix(prefix)
        }
    }
    #endif

    private func broadcast(_ snapshot: NetworkPathSnapshot) {
        for continuation in updateContinuations.values {
            continuation.yield(snapshot)
        }
    }

    private func removeContinuation(_ id: UUID) {
        updateContinuations[id] = nil
    }
}
