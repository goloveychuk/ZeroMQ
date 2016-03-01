// ZMQTests.swift
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

import XCTest
import SwiftZMQ

class ZMQTests: XCTestCase {
    func testExample() {
        var called = false
        do {
            let context = try Context()

            let inbound = try context.socket(.Pull)
            try inbound.bind("tcp://127.0.0.1:5555")

            let outbound = try context.socket(.Push)
            try outbound.connect("tcp://127.0.0.1:5555")

            try outbound.sendString("Hello World!")
            try outbound.sendString("Bye!")

            while let data = try inbound.receiveString() where data != "Bye!" {
                called = true
                XCTAssert(data == "Hello World!")
            }
        } catch {
            XCTAssert(false)
        }
        XCTAssert(called)
    }
}
