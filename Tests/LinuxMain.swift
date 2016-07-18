#if os(Linux)

import XCTest
@testable import ZeroMQTestSuite

XCTMain([
    testCase(ZeroMQTests.allTests)
])

#endif
