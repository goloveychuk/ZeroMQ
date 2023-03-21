// Poller.swift
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

public struct PollEvent : OptionSet {
    public let rawValue: Int16

    public init(rawValue: Int16) {
        self.rawValue = rawValue
    }

    public static let In       = PollEvent(rawValue: Int16(ZMQ_POLLIN))
    public static let Out      = PollEvent(rawValue: Int16(ZMQ_POLLOUT))
    public static let Error    = PollEvent(rawValue: Int16(ZMQ_POLLERR))
    // public static let Priority = PollEvent(rawValue: Int16(ZMQ_POLLPRI))
}

public enum PollItemEvent {
    case socket(socket: UnsafeMutableRawPointer, events: PollEvent)
    case fileDescriptor(fileDescriptor: Int32, events: PollEvent)

    var pollItem: zmq_pollitem_t {
        switch self {
        case .socket(let socket, let events):
            return zmq_pollitem_t(socket: socket, fd: 0, events: events.rawValue, revents: 0)
        case .fileDescriptor(let fileDescriptor, let events):
            return zmq_pollitem_t(socket: nil, fd: fileDescriptor, events: events.rawValue, revents: 0)
        }
    }

    init(pollItem: zmq_pollitem_t) {
        if pollItem.socket != nil {
            self = .socket(
                socket: pollItem.socket,
                events: PollEvent(rawValue: pollItem.revents)
            )
        } else {
            self = .fileDescriptor(
                fileDescriptor: pollItem.fd,
                events: PollEvent(rawValue: pollItem.revents)
            )
        }
    }
}

public func poll(_ items: PollItemEvent..., timeout: Int) throws -> [PollItemEvent] {
    var pollItems = items.map { $0.pollItem }

    if zmq_poll(&pollItems, Int32(pollItems.count), timeout) == -1 {
        throw ZeroMqError.lastError
    }

    return pollItems.map(PollItemEvent.init)
}
