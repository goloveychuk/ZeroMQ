import XCTest
@testable import ZeroMQ

class ZeroMQTests: XCTestCase {
    func testPushPull() {
        var called = false
        do {
            let context = try Context()

            let inbound = try context.socket(.Pull)
            try inbound.bind("tcp://127.0.0.1:5555")

            let outbound = try context.socket(.Push)
            try outbound.connect("tcp://127.0.0.1:5555")

            try outbound.sendString("Hello World!")
            try outbound.sendString("Bye!")

            while let data = try inbound.receiveString() , data != "Bye!" {
                called = true
                XCTAssert(data == "Hello World!")
            }
        } catch {
            XCTAssert(false)
        }
        XCTAssert(called)
    }
}

extension ZeroMQTests {
    static var allTests: [(String, (ZeroMQTests) -> () throws -> Void)] {
        return [
           ("testPushPull", testPushPull),
        ]
    }
}
