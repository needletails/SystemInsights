//
//  SignalData.swift
//  Adwaita
//
//  Created by david-swift on 31.07.24.
//

import CAdw

/// Data to pass to signal handlers.
public class SignalData {

    /// The closure.
    public var closure: ([Any?]) -> Any?
    /// Destroy the class.
    public var selfDestruction: (() -> Void)?

    /// The closure as a C handler.
    var handler: @convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> Void {
        { _, data in
            let data = unsafeBitCast(data, to: SignalData.self)
            _ = data.closure([])
        }
    }

    /// The closure as a C handler with three parameters.
    var threeParamsHandler: @convention(c) (
        UnsafeMutableRawPointer,
        UnsafeRawPointer?,
        UnsafeMutableRawPointer
    ) -> Void {
        { _, arg1, data in
            let data = unsafeBitCast(data, to: SignalData.self)
            _ = data.closure([arg1])
        }
    }

    /// The closure as a C handler with four parameters.
    var fourParamsHandler: @convention(c) (
        UnsafeMutableRawPointer,
        UnsafeRawPointer?,
        UnsafeRawPointer?,
        UnsafeMutableRawPointer
    ) -> Void {
        { _, arg1, arg2, data in
            let data = unsafeBitCast(data, to: SignalData.self)
            _ = data.closure([arg1, arg2])
        }
    }

    /// The closure as a C handler with five parameters.
    var fiveParamsHandler: @convention(c) (
        UnsafeMutableRawPointer,
        UnsafeRawPointer?,
        Double,
        Double,
        UnsafeMutableRawPointer
    ) -> Void {
        { _, arg1, arg2, arg3, data in
            let data = unsafeBitCast(data, to: SignalData.self)
            _ = data.closure([arg1, arg2, arg3])
        }
    }

    /// The closure as a C handler with a return value.
    var boolHandler: @convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> Bool {
        { _, data in
            let data = unsafeBitCast(data, to: SignalData.self)
            return data.closure([]) as? Bool ?? false
        }
    }

    /// Initialize the signal data.
    /// - Parameters:
    ///     - closure: The signal's closure.
    ///     - destroy: The self destruction.
    public convenience init(closure: @escaping () -> Any?, destroy: (() -> Void)? = nil) {
        self.init(closure: { _ in closure() }, destroy: destroy)
    }

    /// Initialize the signal data.
    /// - Parameters:
    ///     - closure: The signal's closure.
    ///     - destroy: The self destruction.
    public convenience init(closure: @escaping () -> Void, destroy: (() -> Void)? = nil) {
        self.init(closure: { _ in closure(); return nil }, destroy: destroy)
    }

    /// Initialize the signal data.
    /// - Parameters:
    ///     - closure: The signal's closure.
    ///     - destroy: The self destruction.
    public init(closure: @escaping ([Any]) -> Any?, destroy: (() -> Void)? = nil) {
        self.closure = closure
        self.selfDestruction = destroy
    }

    /// The return type.
    public enum ReturnType {

        /// Returns a boolean.
        case bool

    }

    /// Connect the signal data to a signal.
    /// - Parameters:
    ///     - pointer: The pointer to the object which holds the signal.
    ///     - signal: The signal's name.
    ///     - argCount: The number of arguments.
    ///     - return: The return type.
    public func connect(
        pointer: UnsafeMutableRawPointer?,
        signal: String,
        argCount: Int = 0,
        return: ReturnType? = nil
    ) {
        let callback: GCallback
        if let `return` {
            switch `return` {
            case .bool:
                callback = unsafeBitCast(boolHandler, to: GCallback.self)
            }
        } else if argCount >= 3 {
            callback = unsafeBitCast(fiveParamsHandler, to: GCallback.self)
        } else if argCount == 2 {
            callback = unsafeBitCast(fourParamsHandler, to: GCallback.self)
        } else if argCount == 1 {
            callback = unsafeBitCast(threeParamsHandler, to: GCallback.self)
        } else {
            callback = unsafeBitCast(handler, to: GCallback.self)
        }
        let destroy: GClosureNotify = { data, _ in
            guard let data else {
                return
            }
            let signalData: SignalData = Unmanaged.fromOpaque(data).takeUnretainedValue()
            signalData.selfDestruction?()
        }
        g_signal_connect_data(
            pointer,
            signal,
            callback,
            Unmanaged.passUnretained(self).toOpaque().cast(),
            destroy,
            GConnectFlags(rawValue: 1)
        )
    }

}
