// Context.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import CZeroMQ

public enum SocketType {
    case req
    case rep
    case dealer
    case router
    case pub
    case sub
    case xPub
    case xSub
    case push
    case pull
    case pair
    case stream
    // case Server
    // case Client
}

extension SocketType {
    init?(rawValue: Int32) {
        switch rawValue {
        case ZMQ_REQ:    self = .req
        case ZMQ_REP:    self = .rep
        case ZMQ_DEALER: self = .dealer
        case ZMQ_ROUTER: self = .router
        case ZMQ_PUB:    self = .pub
        case ZMQ_SUB:    self = .sub
        case ZMQ_XPUB:   self = .xPub
        case ZMQ_XSUB:   self = .xSub
        case ZMQ_PUSH:   self = .push
        case ZMQ_PULL:   self = .pull
        case ZMQ_PAIR:   self = .pair
        case ZMQ_STREAM: self = .stream
        // case ZMQ_SERVER: self = Server
        // case ZMQ_CLIENT: self = Client

        default:         return nil
        }
    }
}

extension SocketType {
    var rawValue: Int32 {
        switch self {
        case .req: return ZMQ_REQ
        case .rep: return ZMQ_REP
        case .dealer: return ZMQ_DEALER
        case .router: return ZMQ_ROUTER
        case .pub: return ZMQ_PUB
        case .sub: return ZMQ_SUB
        case .xPub: return ZMQ_XPUB
        case .xSub: return ZMQ_XSUB
        case .push: return ZMQ_PUSH
        case .pull: return ZMQ_PULL
        case .pair: return ZMQ_PAIR
        case .stream: return ZMQ_STREAM
        // case .Server: return ZMQ_SERVER
        // case .Client: return ZMQ_CLIENT
        }
    }
}

public final class Context {
    let context: UnsafeMutableRawPointer?

    public init() throws {
        context = zmq_ctx_new()

        if context == nil {
            throw ZeroMqError.lastError
        }
    }

    public init(IOThreads: Int32) throws {
        context = zmq_ctx_new()

        if context == nil {
            throw ZeroMqError.lastError
        }

        self.IOThreads = IOThreads
    }

    deinit {
        zmq_ctx_term(context)
    }

    public func terminate() throws {
        if zmq_ctx_term(context) == -1 {
            throw ZeroMqError.lastError
        }
    }

    func setOption(_ option: Int32, value: Int32) {
        zmq_ctx_set(context, option, value)
    }

    func getOption(_ option: Int32) -> Int32 {
        return zmq_ctx_get(context, option)
    }

    public func socket(_ type: SocketType) throws -> Socket {

        guard let socket = zmq_socket(context, type.rawValue) else {
            throw ZeroMqError.lastError
        }

        return Socket(socket: socket)
    }
}

extension Context {
    // public var blocky: Bool {
    //     set {
    //         setOption(ZMQ_BLOCKY, value: newValue ? 1 : 0)
    //     }
    //     get {
    //         return getOption(ZMQ_BLOCKY) != 0
    //     }
    // }

    public var IOThreads: Int32 {
        set {
            setOption(ZMQ_IO_THREADS, value: newValue)
        }
        get {
            return getOption(ZMQ_IO_THREADS)
        }
    }

    public var maxSockets: Int32 {
        set {
            setOption(ZMQ_MAX_SOCKETS, value: newValue)
        }
        get {
            return getOption(ZMQ_MAX_SOCKETS)
        }
    }

    public var IPV6: Bool {
        set {
            setOption(ZMQ_IPV6, value: newValue ? 1 : 0)
        }
        get {
            return getOption(ZMQ_IPV6) != 0
        }
    }

    public var socketLimit: Int32 {
        return getOption(ZMQ_SOCKET_LIMIT)
    }

    public func setThreadSchedulingPolicy(_ value: Int32) {
        setOption(ZMQ_THREAD_SCHED_POLICY, value: value)
    }

    public func setThreadPriority(_ value: Int32) {
        setOption(ZMQ_THREAD_PRIORITY, value: value)
    }
}
