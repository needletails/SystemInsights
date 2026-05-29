import Foundation

enum DashboardCollectDiagnostics {
    nonisolated static func log(_ message: String) {
        FileHandle.standardError.write(Data("[SystemInsights] \(message)\n".utf8))
    }
}
