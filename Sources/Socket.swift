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
import Data

public struct SendMode : OptionSetType {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let DontWait = SendMode(rawValue: Int(ZMQ_DONTWAIT))
    public static let SendMore = SendMode(rawValue: Int(ZMQ_SNDMORE))
}

public struct ReceiveMode : OptionSetType {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let DontWait = ReceiveMode(rawValue: Int(ZMQ_DONTWAIT))
}

public final class Socket {
    let socket: UnsafeMutablePointer<Void>

    init(socket: UnsafeMutablePointer<Void>) {
        self.socket = socket
    }

    deinit {
        zmq_close(socket)
    }

    func setOption(option: Int32, value: UnsafePointer<Void>, length: Int) throws {
        if zmq_setsockopt(socket, option, value, length) == -1 {
            throw Error.lastError
        }
    }

    func getOption(option: Int32, value: UnsafeMutablePointer<Void>, length: UnsafeMutablePointer<Int>) throws {
        if zmq_getsockopt(socket, option, value, length) == -1 {
            throw Error.lastError
        }
    }

    public func bind(endpoint: String) throws {
        if zmq_bind(socket, endpoint) == -1 {
            throw Error.lastError
        }
    }

    public func connect(endpoint: String) throws {
        if zmq_connect(socket, endpoint) == -1 {
            throw Error.lastError
        }
    }

    public func sendMessage(message: Message, mode: SendMode = []) throws -> Bool {
        let result = zmq_msg_send(&message.message, socket, Int32(mode.rawValue))

        if result == -1 && zmq_errno() == EAGAIN {
            return false
        }

        if result == -1 {
            throw Error.lastError
        }

        return true
    }

    func send(buffer: UnsafeMutablePointer<Void>, length: Int, mode: SendMode = []) throws -> Bool {
        let result = zmq_send(socket, buffer, length, Int32(mode.rawValue))

        if result == -1 && zmq_errno() == EAGAIN {
            return false
        }

        if result == -1 {
            throw Error.lastError
        }

        return true
    }
    public func send(data: Data, mode: SendMode = []) throws -> Bool {
        var data = data
        return try self.send(&data.bytes, length: data.count, mode: mode)
    }

    func sendImmutable(buffer: UnsafePointer<Void>, length: Int, mode: SendMode = []) throws -> Bool {
        let result = zmq_send_const(socket, buffer, length, Int32(mode.rawValue))

        if result == -1 && zmq_errno() == EAGAIN {
            return false
        }

        if result == -1 {
            throw Error.lastError
        }

        return true
    }

    public func receiveMessage(mode: ReceiveMode = []) throws -> Message? {
        let message = try Message()
        let result = zmq_msg_recv(&message.message, socket, Int32(mode.rawValue))

        if result == -1 && zmq_errno() == EAGAIN {
            return nil
        }

        if result == -1 {
            throw Error.lastError
        }

        return message
    }

    public func receive(bufferSize bufferSize: Int = 1024, mode: ReceiveMode = []) throws -> Data? {
        var data = Data.bufferWithSize(bufferSize)
        let result = zmq_recv(socket, &data.bytes, bufferSize, Int32(mode.rawValue))
        if result == -1 && zmq_errno() == EAGAIN {
            return nil
        }

        if result == -1 {
            throw Error.lastError
        }
        let bufferEnd = min(Int(result), bufferSize)
        return data[0 ..< bufferEnd]
    }
    
    public func close() throws {
        if zmq_close(socket) == -1 {
            throw Error.lastError
        }
    }

    public func monitor(endpoint: String, events: SocketEvent) throws {
        if zmq_socket_monitor(socket, endpoint, events.rawValue) == -1 {
            throw Error.lastError
        }
    }
}

public struct SocketEvent : OptionSetType {
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
    public func setAffinity(value: UInt64) throws {
        var value = value
        try setOption(ZMQ_AFFINITY, value: &value, length: strideof(UInt64))
    }

    public func setBacklog(value: Int32) throws {
        var value = value
        try setOption(ZMQ_BACKLOG, value: &value, length: strideof(Int32))
    }

    public func setConnectRID(value: String) throws {
        try value.withCString { v in
            try setOption(ZMQ_CONNECT_RID, value: v, length: value.utf8.count)
        }
    }

    public func setConflate(value: Bool) throws {
        var v = value ? 1 : 0
        try setOption(ZMQ_CONFLATE, value: &v, length: strideof(Int32))
    }

    public func setConnectTimeout(value: Int32) throws {
        var value = value
        try setOption(ZMQ_CONNECT_TIMEOUT, value: &value, length: strideof(Int32))
    }

    public func setCURVEPublicKey(value: String?) throws {
        if let value = value {
            try value.withCString { v in
                try setOption(ZMQ_CURVE_PUBLICKEY, value: v, length: value.utf8.count)
            }
        } else {
            try setOption(ZMQ_CURVE_PUBLICKEY, value: nil, length: 0)
        }
    }

    public func setCURVESecretKey(value: String?) throws {
        if let value = value {
            try value.withCString { v in
                try setOption(ZMQ_CURVE_SECRETKEY, value: v, length: value.utf8.count)
            }
        } else {
            try setOption(ZMQ_CURVE_SECRETKEY, value: nil, length: 0)
        }
    }

    public func setCURVEServer(value: Bool) throws {
        var v = value ? 1 : 0
        try setOption(ZMQ_CURVE_SERVER, value: &v, length: strideof(Int32))
    }

    public func setCURVEServerKey(value: String?) throws {
        if let value = value {
            try value.withCString { v in
                try setOption(ZMQ_CURVE_SERVERKEY, value: v, length: value.utf8.count)
            }
        } else {
            try setOption(ZMQ_CURVE_SERVERKEY, value: nil, length: 0)
        }
    }

    public func setGSSAPIPlainText(value: Bool) throws {
        var v = value ? 1 : 0
        try setOption(ZMQ_GSSAPI_PLAINTEXT, value: &v, length: strideof(Int32))
    }

    public func setGSSAPIPrincipal(value: String) throws {
        try value.withCString { v in
            try setOption(ZMQ_GSSAPI_PRINCIPAL, value: v, length: value.utf8.count)
        }
    }

    public func setGSSAPIServer(value: Bool) throws {
        var v = value ? 1 : 0
        try setOption(ZMQ_GSSAPI_SERVER, value: &v, length: strideof(Int32))
    }

    public func setGSSAPIServicePrincipal(value: String) throws {
        try value.withCString { v in
            try setOption(ZMQ_GSSAPI_SERVICE_PRINCIPAL, value: v, length: value.utf8.count)
        }
    }

    public func setHandshakeInterval(value: Int32) throws {
        var value = value
        try setOption(ZMQ_HANDSHAKE_IVL, value: &value, length: strideof(Int32))
    }

    public func setHeartbeatInterval(value: Int32) throws {
        var value = value
        try setOption(ZMQ_HEARTBEAT_IVL, value: &value, length: strideof(Int32))
    }

    public func setHeartbeatTimeout(value: Int32) throws {
        var value = value
        try setOption(ZMQ_HEARTBEAT_TIMEOUT, value: &value, length: strideof(Int32))
    }

    public func setHeartbeatTTTL(value: Int32) throws {
        var value = value
        try setOption(ZMQ_HEARTBEAT_TTL, value: &value, length: strideof(Int32))
    }

    public func setIdentity(value: String) throws {
        try value.withCString { v in
            try setOption(ZMQ_IDENTITY, value: v, length: value.utf8.count)
        }
    }

    public func setImmediate(value: Bool) throws {
        var value = value ? 1 : 0
        try setOption(ZMQ_IMMEDIATE, value: &value, length: strideof(Int32))
    }

    public func setInvertMatching(value: Bool) throws {
        var value = value ? 1 : 0
        try setOption(ZMQ_INVERT_MATCHING, value: &value, length: strideof(Int32))
    }

    public func setIPV6(value: Bool) throws {
        var value = value ? 1 : 0
        try setOption(ZMQ_IPV6, value: &value, length: strideof(Int32))
    }

    public func setLinger(value: Int32) throws {
        var value = value
        try setOption(ZMQ_LINGER, value: &value, length: strideof(Int32))
    }

    public func setMaxMessageSize(value: Int64) throws {
        var value = value
        try setOption(ZMQ_MAXMSGSIZE, value: &value, length: strideof(Int64))
    }

    public func setMulticastHops(value: Int32) throws {
        var value = value
        try setOption(ZMQ_MULTICAST_HOPS, value: &value, length: strideof(Int32))
    }

    public func setPlainPassword(value: String?) throws {
        if let value = value {
            try value.withCString { v in
                try setOption(ZMQ_PLAIN_PASSWORD, value: v, length: value.utf8.count)
            }
        } else {
            try setOption(ZMQ_PLAIN_PASSWORD, value: nil, length: 0)
        }
    }

    public func setPlainServer(value: Bool) throws {
        var v = value ? 1 : 0
        try setOption(ZMQ_PLAIN_SERVER, value: &v, length: strideof(Int32))
    }

    public func setPlainUsername(value: String?) throws {
        if let value = value {
            try value.withCString { v in
                try setOption(ZMQ_PLAIN_USERNAME, value: v, length: value.utf8.count)
            }
        } else {
            try setOption(ZMQ_PLAIN_USERNAME, value: nil, length: 0)
        }
    }

    public func setProbeRouter(value: Bool) throws {
        var value = value ? 1 : 0
        try setOption(ZMQ_PROBE_ROUTER, value: &value, length: strideof(Int32))
    }

    public func setRate(value: Int32) throws {
        var value = value
        try setOption(ZMQ_RATE, value: &value, length: strideof(Int32))
    }

    public func setReceiveBuffer(value: Int32) throws {
        var value = value
        try setOption(ZMQ_RCVBUF, value: &value, length: strideof(Int32))
    }

    public func setReceiveHighWaterMark(value: Int32) throws {
        var value = value
        try setOption(ZMQ_RCVHWM, value: &value, length: strideof(Int32))
    }

    public func setReceiveTimeout(value: Int32) throws {
        var value = value
        try setOption(ZMQ_RCVTIMEO, value: &value, length: strideof(Int32))
    }

    public func setReconnectInterval(value: Int32) throws {
        var value = value
        try setOption(ZMQ_RECONNECT_IVL, value: &value, length: strideof(Int32))
    }

    public func setReconnectIntervalMax(value: Int32) throws {
        var value = value
        try setOption(ZMQ_RECONNECT_IVL_MAX, value: &value, length: strideof(Int32))
    }

    public func setRecoveryInterval(value: Int32) throws {
        var value = value
        try setOption(ZMQ_RECOVERY_IVL, value: &value, length: strideof(Int32))
    }

    public func setReqCorrelate(value: Bool) throws {
        var value = value ? 1 : 0
        try setOption(ZMQ_REQ_CORRELATE, value: &value, length: strideof(Int32))
    }

    public func setReqRelaxed(value: Bool) throws {
        var value = value ? 1 : 0
        try setOption(ZMQ_REQ_RELAXED, value: &value, length: strideof(Int32))
    }

    public func setRouterHandover(value: Bool) throws {
        var value = value ? 1 : 0
        try setOption(ZMQ_ROUTER_HANDOVER, value: &value, length: strideof(Int32))
    }

    public func setRouterMandatory(value: Bool) throws {
        var value = value ? 1 : 0
        try setOption(ZMQ_ROUTER_MANDATORY, value: &value, length: strideof(Int32))
    }

    public func setRouterRaw(value: Bool) throws {
        var value = value ? 1 : 0
        try setOption(ZMQ_ROUTER_RAW, value: &value, length: strideof(Int32))
    }

    public func setSendBuffer(value: Int32) throws {
        var value = value
        try setOption(ZMQ_SNDBUF, value: &value, length: strideof(Int32))
    }

    public func setSendHighWaterMark(value: Int32) throws {
        var value = value
        try setOption(ZMQ_SNDHWM, value: &value, length: strideof(Int32))
    }

    public func setSendTimeout(value: Int32) throws {
        var value = value
        try setOption(ZMQ_SNDTIMEO, value: &value, length: strideof(Int32))
    }

    public func setStreamNotify(value: Bool) throws {
        var value = value ? 1 : 0
        try setOption(ZMQ_STREAM_NOTIFY, value: &value, length: strideof(Int32))
    }

    public func setSubscribe(value: String) throws {
        try value.withCString { v in
            try setOption(ZMQ_SUBSCRIBE, value: v, length: value.utf8.count)
        }
    }

    public func setTCPKeepAlive(value: Int32) throws {
        var value = value
        try setOption(ZMQ_TCP_KEEPALIVE, value: &value, length: strideof(Int32))
    }

    public func setTCPKeepAliveCount(value: Int32) throws {
        var value = value
        try setOption(ZMQ_TCP_KEEPALIVE_CNT, value: &value, length: strideof(Int32))
    }

    public func setTCPKeepAliveIdle(value: Int32) throws {
        var value = value
        try setOption(ZMQ_TCP_KEEPALIVE_IDLE, value: &value, length: strideof(Int32))
    }

    public func setTCPKeepAliveInterval(value: Int32) throws {
        var value = value
        try setOption(ZMQ_TCP_KEEPALIVE_INTVL, value: &value, length: strideof(Int32))
    }

//    public func setTCPRetransmitTimeout(var value: Int32) throws {
//        try setOption(ZMQ_TCP_RETRANSMIT_TIMEOUT, value: &value, length: strideof(Int32))
//    }

    public func setTypeOfService(value: Int32) throws {
        var value = value
        try setOption(ZMQ_TOS, value: &value, length: strideof(Int32))
    }

    public func setUnsubscribe(value: String) throws {
        try value.withCString { v in
            try setOption(ZMQ_UNSUBSCRIBE, value: v, length: value.utf8.count)
        }
    }

    public func setXPubVerbose(value: Bool) throws {
        var v = value ? 1 : 0
        try setOption(ZMQ_XPUB_VERBOSE, value: &v, length: strideof(Int32))
    }

//    public func setXPubVerboseUnsubscribe(value: Bool) throws {
//        var v = value ? 1 : 0
//        try setOption(ZMQ_XPUB_VERBOSE_UNSUBSCRIBE, value: &v, length: strideof(Int32))
//    }

    public func setXPubManual(value: Bool) throws {
        var v = value ? 1 : 0
        try setOption(ZMQ_XPUB_MANUAL, value: &v, length: strideof(Int32))
    }

    public func setXPubNoDrop(value: Bool) throws {
        var v = value ? 1 : 0
        try setOption(ZMQ_XPUB_NODROP, value: &v, length: strideof(Int32))
    }

    public func setXPubWelcomeMessage(value: String) throws {
        try value.withCString { v in
            try setOption(ZMQ_XPUB_WELCOME_MSG, value: v, length: value.utf8.count)
        }
    }

    public func setZAPDomain(value: String?) throws {
        if let value = value {
            try value.withCString { v in
                try setOption(ZMQ_ZAP_DOMAIN, value: v, length: value.utf8.count)
            }
        } else {
            try setOption(ZMQ_ZAP_DOMAIN, value: nil, length: 0)
        }
    }
}

extension Socket {
    public func getAffinity() throws -> UInt64 {
        var value: UInt64 = 0
        var length = strideof(UInt64)
        try getOption(ZMQ_AFFINITY, value: &value, length: &length)
        return value
    }

    public func getBacklog() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_BACKLOG, value: &value, length: &length)
        return value
    }

    public func getConnectTimeout() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_CONNECT_TIMEOUT, value: &value, length: &length)
        return value
    }

    public func getCURVEPublicKey() throws -> String {
        var value = [Int8](count: 41, repeatedValue: 0)
        var length = value.count
        try getOption(ZMQ_CURVE_PUBLICKEY, value: &value, length: &length)
        return String.fromCString(Array(value[0 ..< length]))!
    }

    public func getCURVESecretKey() throws -> String {
        var value = [Int8](count: 41, repeatedValue: 0)
        var length = value.count
        try getOption(ZMQ_CURVE_SECRETKEY, value: &value, length: &length)
        return String.fromCString(Array(value[0 ..< length]))!
    }

    public func getCURVEServerKey() throws -> String {
        var value = [Int8](count: 41, repeatedValue: 0)
        var length = value.count
        try getOption(ZMQ_CURVE_SERVERKEY, value: &value, length: &length)
        return String.fromCString(Array(value[0 ..< length]))!
    }

    public func getEvents() throws -> PollEvent? {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_EVENTS, value: &value, length: &length)
        return Int(value) == -1 ? nil : PollEvent(rawValue: Int16(value))
    }

    public func getFileDescriptor() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_FD, value: &value, length: &length)
        return value
    }

    public func getGSSAPIPlainText() throws -> Bool {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_GSSAPI_PLAINTEXT, value: &value, length: &length)
        return value != 0
    }

    public func getGSSAPIPrincipal() throws -> String {
        var value = [Int8](count: 256, repeatedValue: 0)
        var length = value.count
        try getOption(ZMQ_GSSAPI_PRINCIPAL, value: &value, length: &length)
        return String.fromCString(Array(value[0 ..< length]))!
    }

    public func getGSSAPIServer() throws -> Bool {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_GSSAPI_SERVER, value: &value, length: &length)
        return value != 0
    }

    public func getGSSAPIServicePrincipal() throws -> String {
        var value = [Int8](count: 256, repeatedValue: 0)
        var length = value.count
        try getOption(ZMQ_GSSAPI_SERVICE_PRINCIPAL, value: &value, length: &length)
        return String.fromCString(Array(value[0 ..< length]))!
    }

    public func getHandshakeInterval() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_HANDSHAKE_IVL, value: &value, length: &length)
        return value
    }

    public func getIdentity() throws -> String {
        var value = [Int8](count: 256, repeatedValue: 0)
        var length = value.count
        try getOption(ZMQ_IDENTITY, value: &value, length: &length)
        return String.fromCString(Array(value[0 ..< length])) ?? ""
    }

    public func getImmediate() throws -> Bool {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_IMMEDIATE, value: &value, length: &length)
        return value != 0
    }

    public func getInvertMatching() throws -> Bool {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_INVERT_MATCHING, value: &value, length: &length)
        return value != 0
    }

    public func getIPV4Only() throws -> Bool {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_IPV4ONLY, value: &value, length: &length)
        return value != 0
    }

    public func getIPV6() throws -> Bool {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_IPV6, value: &value, length: &length)
        return value != 0
    }

    public func getLastEndpoint() throws -> String {
        var value = [Int8](count: 256, repeatedValue: 0)
        var length = value.count
        try getOption(ZMQ_LAST_ENDPOINT, value: &value, length: &length)
        return String.fromCString(Array(value[0 ..< length]))!
    }

    public func getLinger() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_LINGER, value: &value, length: &length)
        return value
    }

    public func getMaxMessageSize() throws -> Int64 {
        var value: Int64 = 0
        var length = strideof(Int64)
        try getOption(ZMQ_MAXMSGSIZE, value: &value, length: &length)
        return value
    }

    public func getMechanism() throws -> SecurityMechanism {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_MECHANISM, value: &value, length: &length)
        return SecurityMechanism(rawValue: value)!
    }

    public func getMulticastHops() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_MULTICAST_HOPS, value: &value, length: &length)
        return value
    }

    public func getPlainPassword() throws -> String {
        var value = [Int8](count: 256, repeatedValue: 0)
        var length = value.count
        try getOption(ZMQ_PLAIN_PASSWORD, value: &value, length: &length)
        return String.fromCString(Array(value[0 ..< length]))!
    }

    public func getPlainServer() throws -> Bool {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_PLAIN_SERVER, value: &value, length: &length)
        return value != 0
    }

    public func getPlainUsername() throws -> String {
        var value = [Int8](count: 256, repeatedValue: 0)
        var length = value.count
        try getOption(ZMQ_PLAIN_USERNAME, value: &value, length: &length)
        return String.fromCString(Array(value[0 ..< length]))!
    }

    public func getRate() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_RATE, value: &value, length: &length)
        return value
    }

    public func getReceiveBuffer() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_RCVBUF, value: &value, length: &length)
        return value
    }

    public func getReceiveHighWaterMark() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_RCVHWM, value: &value, length: &length)
        return value
    }

    public func getReceiveMore() throws -> Bool {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_RCVMORE, value: &value, length: &length)
        return value != 0
    }

    public func getReceiveTimeout() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_RCVTIMEO, value: &value, length: &length)
        return value
    }

    public func getReconnectInterval() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_RECONNECT_IVL, value: &value, length: &length)
        return value
    }

    public func getReconnectIntervalMax() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_RECONNECT_IVL_MAX, value: &value, length: &length)
        return value
    }

    public func getRecoveryInterval() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_RECOVERY_IVL, value: &value, length: &length)
        return value
    }

    public func getSendBuffer() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_SNDBUF, value: &value, length: &length)
        return value
    }

    public func getSendHighWaterMark() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_SNDHWM, value: &value, length: &length)
        return value
    }

    public func getSendTimeout() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_SNDTIMEO, value: &value, length: &length)
        return value
    }

    public func getTCPKeepAlive() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_TCP_KEEPALIVE, value: &value, length: &length)
        return value
    }

    public func getTCPKeepAliveCount() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_TCP_KEEPALIVE_CNT, value: &value, length: &length)
        return value
    }

    public func getTCPKeepAliveIdle() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_TCP_KEEPALIVE_IDLE, value: &value, length: &length)
        return value
    }

    public func getTCPKeepAliveInterval() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_TCP_KEEPALIVE_INTVL, value: &value, length: &length)
        return value
    }

//    public func getTCPRetransmitTimeout() throws -> Int32 {
//        var value: Int32 = 0
//        var length = strideof(Int32)
//        try getOption(ZMQ_TCP_RETRANSMIT_TIMEOUT, value: &value, length: &length)
//        return value
//    }

    public func getThreadSafe() throws -> Bool {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_THREAD_SAFE, value: &value, length: &length)
        return value != 0
    }

    public func getTypeOfService() throws -> Int32 {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_TOS, value: &value, length: &length)
        return value
    }

    public func getType() throws -> SocketType {
        var value: Int32 = 0
        var length = strideof(Int32)
        try getOption(ZMQ_TYPE, value: &value, length: &length)
        return SocketType(rawValue: value)!
    }

    public func getZAPDomain() throws -> String {
        var value = [Int8](count: 256, repeatedValue: 0)
        var length = value.count
        try getOption(ZMQ_ZAP_DOMAIN, value: &value, length: &length)
        return String.fromCString(Array(value[0 ..< length]))!
    }
}

public enum SecurityMechanism {
    case Null
    case Plain
    case CURVE
}

extension SecurityMechanism {
    init?(rawValue: Int32) {
        switch rawValue {
        case ZMQ_NULL: self = Null
        case ZMQ_PLAIN: self = Plain
        case ZMQ_CURVE: self = CURVE
        default: return nil
        }
    }
}

extension Socket {
    public func sendString(string: String, mode: SendMode = []) throws -> Bool {
        return try send(Data(string), mode: mode)
    }

    public func receiveString(mode: ReceiveMode = []) throws -> String? {
        guard let buffer = try receive(mode: mode) else {
            return nil
        }
        return try? String(data: buffer)
    }
}