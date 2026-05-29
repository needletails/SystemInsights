import Foundation

enum DashboardCollectDiagnostics {
    static func log(_ message: String) {
        let line = "[SystemInsights] \(message)\n"
        line.withCString { fputs($0, stderr) }
        fflush(stderr)
    }
}
