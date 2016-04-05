SwiftZMQ
========

[![Swift 2.1](https://img.shields.io/badge/Swift-2.1-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Platforms OS X](https://img.shields.io/badge/Platforms-OS%20X-lightgray.svg?style=flat)](https://developer.apple.com/swift/)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-Compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)](https://tldrlegal.com/license/mit-license)
[![Travis](https://img.shields.io/badge/Build-Passing-4BC51D.svg?style=flat)](https://travis-ci.org/Zewo/SwiftZMQ)
[![codecov.io](http://codecov.io/github/Zewo/SwiftZMQ/coverage.svg?branch=master)](http://codecov.io/github/Zewo/SwiftZMQ?branch=master)
[![Slack Status](https://zewo-slackin.herokuapp.com/badge.svg)](https://zewo-slackin.herokuapp.com)

**SwiftZMQ** is a [ZeroMQ](http://zeromq.org/) binding for **Swift 2**.

## Features

- [x] No `Foundation` dependency (**Linux ready**)
- [x] Context
- [x] Socket
- [x] Message
- [x] Poller
- [x] Proxy

This fork clones the libzmq repo and compiles it statically into the SwiftZMQ framework, also it adds the iOS framework target

##Example

```swift
import SwiftZMQ

do {
    let context = try Context()

    let inbound = try context.socket(.Pull)
    try inbound.bind("tcp://127.0.0.1:5555")

    let outbound = try context.socket(.Push)
    try outbound.connect("tcp://127.0.0.1:5555")

    try outbound.sendString("Hello World!")
    try outbound.sendString("Bye!")

    while let data = try inbound.receiveString() where data != "Bye!" {
        print(data) // "Hello World!"
    }
} catch {
    // Something bad happened :(
}
```

## Dependency

**SwiftZMQ** requires ZeroMQ version 4.2 to be installed. The easiest way on Mac OS X is through brew.

```
> brew install zeromq --with-libsodium --HEAD
```

## Installation

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/Zewo/ZeroMQ.git", majorVersion: 0, minor: 4)
    ]
)
```

## Community

[![Slack](http://s13.postimg.org/ybwy92ktf/Slack.png)](https://zewo-slackin.herokuapp.com)

Join us on [Slack](https://zewo-slackin.herokuapp.com).

License
-------

**SwiftZMQ** is released under the MIT license. See LICENSE for details.
