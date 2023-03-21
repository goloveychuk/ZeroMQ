// Socket.swift
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
import struct Foundation.Data

public struct SendMode : OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let DontWait = SendMode(rawValue: Int(ZMQ_DONTWAIT))
    public static let SendMore = SendMode(rawValue: Int(ZMQ_SNDMORE))
}

public struct ReceiveMode : OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let DontWait = ReceiveMode(rawValue: Int(ZMQ_DONTWAIT))
}

public final class Socket {
    let socket: UnsafeMutableRawPointer

    init(socket: UnsafeMutableRawPointer) {
        self.socket = socket
    }

    deinit {
        zmq_close(socket)
    }

    func setOption(_ option: Int32, value: UnsafeRawPointer?, length: Int) throws {
        if zmq_setsockopt(socket, option, value, length) == -1 {
            throw ZeroMqError.lastError
        }
    }

    func getOption(_ option: Int32, value: UnsafeMutableRawPointer, length: UnsafeMutablePointer<Int>) throws {
        if zmq_getsockopt(socket, option, value, length) == -1 {
            throw ZeroMqError.lastError
        }
    }

    public func bind(_ endpoint: String) throws {
        if zmq_bind(socket, endpoint) == -1 {
            throw ZeroMqError.lastError
        }
    }

    public func connect(_ endpoint: String) throws {
        if zmq_connect(socket, endpoint) == -1 {
            throw ZeroMqError.lastError
        }
    }

    public func sendMessage(_ message: Message, mode: SendMode = []) throws -> Bool {
        let result = zmq_msg_send(&message.message, socket, Int32(mode.rawValue))

        if result == -1 && zmq_errno() == EAGAIN {
            return false
        }

        if result == -1 {
            throw ZeroMqError.lastError
        }

        return true
    }

    func send(_ buffer: UnsafeMutableRawPointer, length: Int, mode: SendMode = []) throws -> Bool {
        let result = zmq_send(socket, buffer, length, Int32(mode.rawValue))

        if result == -1 && zmq_errno() == EAGAIN {
            return false
        }

        if result == -1 {
            throw ZeroMqError.lastError
        }

        return true
    }
    public func send(_ data: Data, mode: SendMode = []) throws -> Bool {
        var dta = data
        return try dta.withUnsafeMutableBytes { bytes in
            return try self.send(bytes, length: data.count, mode: mode)
        }
    }

    func sendImmutable(_ buffer: UnsafeRawPointer, length: Int, mode: SendMode = []) throws -> Bool {
        let result = zmq_send_const(socket, buffer, length, Int32(mode.rawValue))

        if result == -1 && zmq_errno() == EAGAIN {
            return false
        }

        if result == -1 {
            throw ZeroMqError.lastError
        }

        return true
    }

    public func receiveMessage(_ mode: ReceiveMode = []) throws -> Message? {
        let message = try Message()
        let result = zmq_msg_recv(&message.message, socket, Int32(mode.rawValue))

        if result == -1 && zmq_errno() == EAGAIN {
            return nil
        }

        if result == -1 {
            throw ZeroMqError.lastError
        }

        return message
    }

    public func receive(_ bufferSize: Int = 1024, mode: ReceiveMode = []) throws -> Data? {
        var data = Data(count: bufferSize)
        let result = data.withUnsafeMutableBytes { bytes in
            return zmq_recv(socket, bytes, bufferSize, Int32(mode.rawValue))
        }
        if result == -1 && zmq_errno() == EAGAIN {
            return nil
        }

        if result == -1 {
            throw ZeroMqError.lastError
        }
        let bufferEnd = min(Int(result), bufferSize)
        return Data(data[0 ..< bufferEnd])
    }

    public func close() throws {
        if zmq_close(socket) == -1 {
            throw ZeroMqError.lastError
        }
    }

    public func monitor(_ endpoint: String, events: SocketEvent) throws {
        if zmq_socket_monitor(socket, endpoint, events.rawValue) == -1 {
            throw ZeroMqError.lastError
        }
    }
}

public struct SocketEvent : OptionSet {
    public let rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public static let All            = SocketEvent(rawValue: ZMQ_EVENT_ALL)
    public static let Connected      = SocketEvent(rawValue: ZMQ_EVENT_CONNECTED)
    public static let Delayed        = SocketEvent(rawValue: ZMQ_EVENT_CONNECT_DELAYED)
    public static let Retried        = SocketEvent(rawValue: ZMQ_EVENT_CONNECT_RETRIED)
    public static let Listening      = SocketEvent(rawValue: ZMQ_EVENT_LISTENING)
    public static let BindFailed     = SocketEvent(rawValue: ZMQ_EVENT_BIND_FAILED)
    public static let Accepted       = SocketEvent(rawValue: ZMQ_EVENT_ACCEPTED)
    public static let AcceptFailed   = SocketEvent(rawValue: ZMQ_EVENT_ACCEPT_FAILED)
    public static let Closed         = SocketEvent(rawValue: ZMQ_EVENT_CLOSED)
    public static let CloseFailed    = SocketEvent(rawValue: ZMQ_EVENT_CLOSE_FAILED)
    public static let Disconnected   = SocketEvent(rawValue: ZMQ_EVENT_DISCONNECTED)
    public static let MonitorStopped = SocketEvent(rawValue: ZMQ_EVENT_MONITOR_STOPPED)
}

extension Socket {
    func setOption(_ option: Int32, _ value: Bool) throws {
        var value = value ? 1 : 0
        try setOption(option, value: &value, length: MemoryLayout<Int32>.size)
    }
    func setOption(_ option: Int32, _ value: Int32) throws {
        var value = value
        try setOption(option, value: &value, length: MemoryLayout<Int32>.size)
    }
    func setOption(_ option: Int32, _ value: String) throws {
        try value.withCString { v in
            try setOption(option, value: v, length: value.utf8.count)
        }
    }
    func setOption(_ option: Int32, _ value: Data) throws {
        try value.withUnsafeBytes { bytes in
            try setOption(option, value: bytes, length: value.count)
        }
    }
    func setOption(_ option: Int32, _ value: String?) throws {
        if let value = value {
            try value.withCString { v in
                try setOption(option, value: v, length: value.utf8.count)
            }
        } else {
            try setOption(option, value: nil, length: 0)
        }
    }
}

extension Socket {
    public func setAffinity(_ value: UInt64) throws {
        var value = value
        try setOption(ZMQ_AFFINITY, value: &value, length: MemoryLayout<UInt64>.size)
    }

    public func setBacklog(_ value: Int32) throws {
        try setOption(ZMQ_BACKLOG, value)
    }

    public func setConnectRID(_ value: String) throws {
        try setOption(ZMQ_CONNECT_RID, value)
    }

    public func setConflate(_ value: Bool) throws {
        try setOption(ZMQ_CONFLATE, value)
    }

    // public func setConnectTimeout(value: Int32) throws {
    //     try setOption(ZMQ_CONNECT_TIMEOUT, value)
    // }

    public func setCURVEPublicKey(_ value: String?) throws {
        try setOption(ZMQ_CURVE_PUBLICKEY, value)
    }

    public func setCURVESecretKey(_ value: String?) throws {
        try setOption(ZMQ_CURVE_SECRETKEY, value)
    }

    public func setCURVEServer(_ value: Bool) throws {
        try setOption(ZMQ_CURVE_SERVER, value)
    }

    public func setCURVEServerKey(_ value: String?) throws {
        try setOption(ZMQ_CURVE_SERVERKEY, value)
    }

    public func setGSSAPIPlainText(_ value: Bool) throws {
        try setOption(ZMQ_GSSAPI_PLAINTEXT, value)
    }

    public func setGSSAPIPrincipal(_ value: String) throws {
        try setOption(ZMQ_GSSAPI_PRINCIPAL, value)
    }

    public func setGSSAPIServer(_ value: Bool) throws {
        try setOption(ZMQ_GSSAPI_SERVER, value)
    }

    public func setGSSAPIServicePrincipal(_ value: String) throws {
        try setOption(ZMQ_GSSAPI_SERVICE_PRINCIPAL, value)
    }

    public func setHandshakeInterval(_ value: Int32) throws {
        try setOption(ZMQ_HANDSHAKE_IVL, value)
    }

    // public func setHeartbeatInterval(value: Int32) throws {
    //     try setOption(ZMQ_HEARTBEAT_IVL, value)
    // }

    // public func setHeartbeatTimeout(value: Int32) throws {
    //     try setOption(ZMQ_HEARTBEAT_TIMEOUT, value)
    // }

    // public func setHeartbeatTTTL(value: Int32) throws {
    //     try setOption(ZMQ_HEARTBEAT_TTL, value)
    // }

    public func setIdentity(_ value: String) throws {
        try setOption(ZMQ_IDENTITY, value)
    }

    public func setImmediate(_ value: Bool) throws {
        try setOption(ZMQ_IMMEDIATE, value)
    }

    // public func setInvertMatching(value: Bool) throws {
    //     try setOption(ZMQ_INVERT_MATCHING, value)
    // }

    public func setIPV6(_ value: Bool) throws {
        try setOption(ZMQ_IPV6, value)
    }

    public func setLinger(_ value: Int32) throws {
        try setOption(ZMQ_LINGER, value)
    }

    public func setMaxMessageSize(_ value: Int64) throws {
        var value = value
        try setOption(ZMQ_MAXMSGSIZE, value: &value, length: MemoryLayout<Int64>.size)
    }

    public func setMulticastHops(_ value: Int32) throws {
        try setOption(ZMQ_MULTICAST_HOPS, value)
    }

    public func setPlainPassword(_ value: String?) throws {
        try setOption(ZMQ_PLAIN_PASSWORD, value)
    }

    public func setPlainServer(_ value: Bool) throws {
        try setOption(ZMQ_PLAIN_SERVER, value)
    }

    public func setPlainUsername(_ value: String?) throws {
        try setOption(ZMQ_PLAIN_USERNAME, value)
    }

    public func setProbeRouter(_ value: Bool) throws {
        try setOption(ZMQ_PROBE_ROUTER, value)
    }

    public func setRate(_ value: Int32) throws {
        try setOption(ZMQ_RATE, value)
    }

    public func setReceiveBuffer(_ value: Int32) throws {
        try setOption(ZMQ_RCVBUF, value)
    }

    public func setReceiveHighWaterMark(_ value: Int32) throws {
        try setOption(ZMQ_RCVHWM, value)
    }

    public func setReceiveTimeout(_ value: Int32) throws {
        try setOption(ZMQ_RCVTIMEO, value)
    }

    public func setReconnectInterval(_ value: Int32) throws {
        try setOption(ZMQ_RECONNECT_IVL, value)
    }

    public func setReconnectIntervalMax(_ value: Int32) throws {
        try setOption(ZMQ_RECONNECT_IVL_MAX, value)
    }

    public func setRecoveryInterval(_ value: Int32) throws {
        try setOption(ZMQ_RECOVERY_IVL, value)
    }

    public func setReqCorrelate(_ value: Bool) throws {
        try setOption(ZMQ_REQ_CORRELATE, value)
    }

    public func setReqRelaxed(_ value: Bool) throws {
        try setOption(ZMQ_REQ_RELAXED, value)
    }

    public func setRouterHandover(_ value: Bool) throws {
        try setOption(ZMQ_ROUTER_HANDOVER, value)
    }

    public func setRouterMandatory(_ value: Bool) throws {
        try setOption(ZMQ_ROUTER_MANDATORY, value)
    }

    public func setRouterRaw(_ value: Bool) throws {
        try setOption(ZMQ_ROUTER_RAW, value)
    }

    public func setSendBuffer(_ value: Int32) throws {
        try setOption(ZMQ_SNDBUF, value)
    }

    public func setSendHighWaterMark(_ value: Int32) throws {
        try setOption(ZMQ_SNDHWM, value)
    }

    public func setSendTimeout(_ value: Int32) throws {
        try setOption(ZMQ_SNDTIMEO, value)
    }

    // public func setStreamNotify(value: Bool) throws {
    //     try setOption(ZMQ_STREAM_NOTIFY, value)
    // }

    public func setSubscribe(_ value: Data) throws {
        try setOption(ZMQ_SUBSCRIBE, value)
    }

    public func setTCPKeepAlive(_ value: Int32) throws {
        try setOption(ZMQ_TCP_KEEPALIVE, value)
    }

    public func setTCPKeepAliveCount(_ value: Int32) throws {
        try setOption(ZMQ_TCP_KEEPALIVE_CNT, value)
    }

    public func setTCPKeepAliveIdle(_ value: Int32) throws {
        try setOption(ZMQ_TCP_KEEPALIVE_IDLE, value)
    }

    public func setTCPKeepAliveInterval(_ value: Int32) throws {
        try setOption(ZMQ_TCP_KEEPALIVE_INTVL, value)
    }

//    public func setTCPRetransmitTimeout(var value: Int32) throws {
//        try setOption(ZMQ_TCP_RETRANSMIT_TIMEOUT, value: &value, length: strideof(Int32))
//    }

    public func setTypeOfService(_ value: Int32) throws {
        try setOption(ZMQ_TOS, value)
    }

    public func setUnsubscribe(_ value: Data) throws {
        try setOption(ZMQ_UNSUBSCRIBE, value)
    }

    public func setXPubVerbose(_ value: Bool) throws {
        try setOption(ZMQ_XPUB_VERBOSE, value)
    }

//    public func setXPubVerboseUnsubscribe(value: Bool) throws {
//        var v = value ? 1 : 0
//        try setOption(ZMQ_XPUB_VERBOSE_UNSUBSCRIBE, value: &v, length: strideof(Int32))
//    }

    // public func setXPubManual(value: Bool) throws {
    //     try setOption(ZMQ_XPUB_MANUAL, value)
    // }

    public func setXPubNoDrop(_ value: Bool) throws {
        try setOption(ZMQ_XPUB_NODROP, value)
    }

    // public func setXPubWelcomeMessage(value: String) throws {
    //     try setOption(ZMQ_XPUB_WELCOME_MSG, value)
    // }

    public func setZAPDomain(_ value: String?) throws {
        try setOption(ZMQ_ZAP_DOMAIN, value)
    }
}
extension Socket {
    func getOption(_ option: Int32) throws -> Int32 {
        var value: Int32 = 0
        var length = MemoryLayout<Int32>.size
        try getOption(option, value: &value, length: &length)
        return value
    }
    func getOption(_ option: Int32) throws -> Bool {
        let value: Int32 = try getOption(option)
        return value != 0
    }
    func getOption(_ option: Int32, count: Int) throws -> String? {
        var value = [Int8](repeating: 0, count: count)
        var length = value.count
        try getOption(option, value: &value, length: &length)
        return String(validatingUTF8: Array(value[0 ..< length]))
    }
}

extension Socket {
    public func getAffinity() throws -> UInt64 {
        var value: UInt64 = 0
        var length = MemoryLayout<UInt64>.size
        try getOption(ZMQ_AFFINITY, value: &value, length: &length)
        return value
    }

    public func getBacklog() throws -> Int32 {
        return try getOption(ZMQ_BACKLOG)
    }

    // public func getConnectTimeout() throws -> Int32 {
    //     return try getOption(ZMQ_CONNECT_TIMEOUT)
    // }

    public func getCURVEPublicKey() throws -> String {
        return try getOption(ZMQ_CURVE_PUBLICKEY, count: 41)!
    }

    public func getCURVESecretKey() throws -> String {
        return try getOption(ZMQ_CURVE_SECRETKEY, count: 41)!
    }

    public func getCURVEServerKey() throws -> String {
        return try getOption(ZMQ_CURVE_SERVERKEY, count: 41)!
    }

    public func getEvents() throws -> PollEvent? {
        let value: Int32 = try getOption(ZMQ_EVENTS)
        return Int(value) == -1 ? nil : PollEvent(rawValue: Int16(value))
    }

    public func getFileDescriptor() throws -> Int32 {
        return try getOption(ZMQ_FD)
    }

    public func getGSSAPIPlainText() throws -> Bool {
        return try getOption(ZMQ_GSSAPI_PLAINTEXT)
    }

    public func getGSSAPIPrincipal() throws -> String {
        return try getOption(ZMQ_GSSAPI_PRINCIPAL, count: 256)!
    }

    public func getGSSAPIServer() throws -> Bool {
        return try getOption(ZMQ_GSSAPI_SERVER)
    }

    public func getGSSAPIServicePrincipal() throws -> String {
        return try getOption(ZMQ_GSSAPI_SERVICE_PRINCIPAL, count: 256)!
    }

    public func getHandshakeInterval() throws -> Int32 {
        return try getOption(ZMQ_HANDSHAKE_IVL)
    }

    public func getIdentity() throws -> String {
        return try getOption(ZMQ_IDENTITY, count: 256) ?? ""
    }

    public func getImmediate() throws -> Bool {
        return try getOption(ZMQ_IMMEDIATE)
    }

    // public func getInvertMatching() throws -> Bool {
    //     return try getOption(ZMQ_INVERT_MATCHING)
    // }

    public func getIPV4Only() throws -> Bool {
        return try getOption(ZMQ_IPV4ONLY)
    }

    public func getIPV6() throws -> Bool {
        return try getOption(ZMQ_IPV6)
    }

    public func getLastEndpoint() throws -> String {
        return try getOption(ZMQ_LAST_ENDPOINT, count: 256)!
    }

    public func getLinger() throws -> Int32 {
        return try getOption(ZMQ_LINGER)
    }

    public func getMaxMessageSize() throws -> Int64 {
        var value: Int64 = 0
        var length = MemoryLayout<Int64>.size
        try getOption(ZMQ_MAXMSGSIZE, value: &value, length: &length)
        return value
    }

    public func getMechanism() throws -> SecurityMechanism {
        let value: Int32 = try getOption(ZMQ_MECHANISM)
        return SecurityMechanism(rawValue: value)!
    }

    public func getMulticastHops() throws -> Int32 {
        return try getOption(ZMQ_MULTICAST_HOPS)
    }

    public func getPlainPassword() throws -> String {
        return try getOption(ZMQ_PLAIN_PASSWORD, count: 256)!
    }

    public func getPlainServer() throws -> Bool {
        return try getOption(ZMQ_PLAIN_SERVER)
    }

    public func getPlainUsername() throws -> String {
        return try getOption(ZMQ_PLAIN_USERNAME, count: 256)!
    }

    public func getRate() throws -> Int32 {
        return try getOption(ZMQ_RATE)
    }

    public func getReceiveBuffer() throws -> Int32 {
        return try getOption(ZMQ_RCVBUF)
    }

    public func getReceiveHighWaterMark() throws -> Int32 {
        return try getOption(ZMQ_RCVHWM)
    }

    public func getReceiveMore() throws -> Bool {
        return try getOption(ZMQ_RCVMORE)
    }

    public func getReceiveTimeout() throws -> Int32 {
        return try getOption(ZMQ_RCVTIMEO)
    }

    public func getReconnectInterval() throws -> Int32 {
        return try getOption(ZMQ_RECONNECT_IVL)
    }

    public func getReconnectIntervalMax() throws -> Int32 {
        return try getOption(ZMQ_RECONNECT_IVL_MAX)
    }

    public func getRecoveryInterval() throws -> Int32 {
        return try getOption(ZMQ_RECOVERY_IVL)
    }

    public func getSendBuffer() throws -> Int32 {
        return try getOption(ZMQ_SNDBUF)
    }

    public func getSendHighWaterMark() throws -> Int32 {
        return try getOption(ZMQ_SNDHWM)
    }

    public func getSendTimeout() throws -> Int32 {
        return try getOption(ZMQ_SNDTIMEO)
    }

    public func getTCPKeepAlive() throws -> Int32 {
        return try getOption(ZMQ_TCP_KEEPALIVE)
    }

    public func getTCPKeepAliveCount() throws -> Int32 {
        return try getOption(ZMQ_TCP_KEEPALIVE_CNT)
    }

    public func getTCPKeepAliveIdle() throws -> Int32 {
        return try getOption(ZMQ_TCP_KEEPALIVE_IDLE)
    }

    public func getTCPKeepAliveInterval() throws -> Int32 {
        return try getOption(ZMQ_TCP_KEEPALIVE_INTVL)
    }

//    public func getTCPRetransmitTimeout() throws -> Int32 {
//        var value: Int32 = 0
//        var length = strideof(Int32)
//        try getOption(ZMQ_TCP_RETRANSMIT_TIMEOUT, value: &value, length: &length)
//        return value
//    }

    // public func getThreadSafe() throws -> Bool {
    //     return try getOption(ZMQ_THREAD_SAFE)
    // }

    public func getTypeOfService() throws -> Int32 {
        return try getOption(ZMQ_TOS)
    }

    public func getType() throws -> SocketType {
        let value: Int32 = try getOption(ZMQ_TYPE)
        return SocketType(rawValue: value)!
    }

    public func getZAPDomain() throws -> String {
        return try getOption(ZMQ_ZAP_DOMAIN, count: 256)!
    }
}

public enum SecurityMechanism {
    case null
    case plain
    case curve
}

extension SecurityMechanism {
    init?(rawValue: Int32) {
        switch rawValue {
        case ZMQ_NULL: self = .null
        case ZMQ_PLAIN: self = .plain
        case ZMQ_CURVE: self = .curve
        default: return nil
        }
    }
}

extension Socket {
    public func send(_ string: String, mode: SendMode = []) throws -> Bool {
        return try send(Data(string.utf8), mode: mode)
    }

    public func receive(_ mode: ReceiveMode = []) throws -> String? {
        guard let buffer = try receive(mode: mode) else {
            return nil
        }
        return String(data: buffer, encoding: String.Encoding.utf8)
    }
}
