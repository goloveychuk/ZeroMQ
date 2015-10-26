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

import ZeroMQ

public enum SocketType {
    case Req
    case Rep
    case Dealer
    case Router
    case Pub
    case Sub
    case XPub
    case XSub
    case Push
    case Pull
    case Pair
    case Stream
}

extension SocketType {
    init?(rawValue: Int32) {
        switch rawValue {
        case ZMQ_REQ:    self = Req
        case ZMQ_REP:    self = Rep
        case ZMQ_DEALER: self = Dealer
        case ZMQ_ROUTER: self = Router
        case ZMQ_PUB:    self = Pub
        case ZMQ_SUB:    self = Sub
        case ZMQ_XPUB:   self = XPub
        case ZMQ_XSUB:   self = XSub
        case ZMQ_PUSH:   self = Push
        case ZMQ_PULL:   self = Pull
        case ZMQ_PAIR:   self = Pair
        case ZMQ_STREAM: self = Stream
        default:         return nil
        }
    }
}

extension SocketType {
    var rawValue: Int32 {
        switch self {
        case .Req: return ZMQ_REQ
        case .Rep: return ZMQ_REP
        case .Dealer: return ZMQ_DEALER
        case .Router: return ZMQ_ROUTER
        case .Pub: return ZMQ_PUB
        case .Sub: return ZMQ_SUB
        case .XPub: return ZMQ_XPUB
        case .XSub: return ZMQ_XSUB
        case .Push: return ZMQ_PUSH
        case .Pull: return ZMQ_PULL
        case .Pair: return ZMQ_PAIR
        case .Stream: return ZMQ_STREAM
        }
    }
}

public final class Context {
    let context: UnsafeMutablePointer<Void>

    public init() throws {
        context = zmq_ctx_new()

        if context == nil {
            throw Error.lastError
        }
    }

    public init(IOThreads: Int32) throws {
        context = zmq_ctx_new()

        if context == nil {
            throw Error.lastError
        }

        self.IOThreads = IOThreads
    }

    deinit {
        zmq_ctx_term(context)
    }

    public func terminate() throws {
        if zmq_ctx_term(context) == -1 {
            throw Error.lastError
        }
    }

    func setOption(option: Int32, value: Int32) {
        zmq_ctx_set(context, option, value)
    }

    func getOption(option: Int32) -> Int32 {
        return zmq_ctx_get(context, option)
    }

    public func socket(type: SocketType) throws -> Socket {
        let socket = zmq_socket(context, type.rawValue)

        if socket == nil {
            throw Error.lastError
        }

        return Socket(socket: socket)
    }
}

extension Context {
    public var blocky: Bool {
        set {
            setOption(ZMQ_BLOCKY, value: newValue ? 1 : 0)
        }
        get {
            return getOption(ZMQ_BLOCKY) != 0
        }
    }

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

    public func setThreadSchedulingPolicy(value: Int32) {
        setOption(ZMQ_THREAD_SCHED_POLICY, value: value)
    }

    public func setThreadPriority(value: Int32) {
        setOption(ZMQ_THREAD_PRIORITY, value: value)
    }
}