// Message.swift
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

import CLibzmq

public final class Message {
    var message: zmq_msg_t

    public init() throws {
        message = zmq_msg_t()

        if zmq_msg_init(&message) == -1 {
            throw Error.lastError
        }
    }

    public init(size: Int) throws {
        message = zmq_msg_t()

        if zmq_msg_init_size(&message, size) == -1 {
            throw Error.lastError
        }
    }

    public init(data: UnsafeMutablePointer<Void>, size: Int, hint: UnsafeMutablePointer<Void> = nil, ffn: @convention(c) (UnsafeMutablePointer<Void>, UnsafeMutablePointer<Void>) -> Void) throws {
        message = zmq_msg_t()

        if zmq_msg_init_data(&message, data, size, ffn, hint) == -1 {
            throw Error.lastError
        }
    }

    public init(data: UnsafeMutablePointer<Void>, size: Int) throws {
        message = zmq_msg_t()

        if zmq_msg_init_data(&message, data, size, nil, nil) == -1 {
            throw Error.lastError
        }
    }

    deinit {
        zmq_msg_close(&message)
    }

    func setProperty(property: Int32, value: Int32) {
        zmq_msg_set(&message, property, value)
    }

    func getProperty(property: Int32) -> Int32 {
        return zmq_msg_get(&message, property)
    }

    public func getProperty(property: String) throws -> String {
        let result = zmq_msg_gets(&message, property)

        if result == nil {
            throw Error.lastError
        }

        return String(validatingUTF8: result)!
    }

    public func close() throws {
        if zmq_msg_close(&message) == -1 {
            throw Error.lastError
        }
    }

    public var data: UnsafeMutablePointer<Void> {
        return zmq_msg_data(&message)
    }

    public var size: Int {
        return zmq_msg_size(&message)
    }

    public var more: Bool {
        return zmq_msg_more(&message) != 0
    }

    public func copy() throws -> Message {
        let message = try Message()

        if zmq_msg_copy(&message.message, &self.message) == -1 {
            throw Error.lastError
        }

        return message
    }

    public func move(message: inout Message) throws {
        let message = try Message()

        if zmq_msg_move(&message.message, &self.message) == -1 {
            throw Error.lastError
        }
    }
}

extension Message {
    public var sourceFileDescriptor: Int32 {
        return getProperty(ZMQ_SRCFD)
    }

    public var shared: Bool {
        return getProperty(ZMQ_SHARED) != 0
    }
}