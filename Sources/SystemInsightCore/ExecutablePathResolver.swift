import Foundation

#if os(macOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

enum ExecutablePathResolver {
    static func path(forPID pid: Int) -> String? {
        guard pid > 0 else { return nil }

        #if os(macOS)
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        let length = proc_pidpath(pid_t(pid), &buffer, UInt32(buffer.count))
        guard length > 0 else { return nil }
        let path = String(decoding: buffer.prefix(Int(length)).map(UInt8.init), as: UTF8.self)
        return path.isEmpty ? nil : path
        #elseif os(Linux)
        let linkPath = "\(LinuxSandboxAdaptation.procDirectory)/\(pid)/exe"
        var buffer = [CChar](repeating: 0, count: Int(PATH_MAX))
        let length = readlink(linkPath, &buffer, buffer.count)
        guard length > 0 else { return nil }
        let path = String(decoding: buffer.prefix(length).map(UInt8.init), as: UTF8.self)
        return path.isEmpty ? nil : path
        #else
        return nil
        #endif
    }

    static func isWritableLocation(_ path: String) -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return path.hasPrefix("/tmp/")
            || path.hasPrefix("/private/tmp/")
            || path.hasPrefix("/var/tmp/")
            || path.hasPrefix("/Users/Shared/")
            || path.hasPrefix("\(home)/Downloads/")
            || path.hasPrefix("\(home)/.cache/")
    }
}
