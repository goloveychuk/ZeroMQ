ZeroMQ
========

[![Swift][swift-badge]][swift-url]
[![Platform][platform-badge]][platform-url]
[![License][mit-badge]][mit-url]
[![Slack][slack-badge]][slack-url]


**ZeroMQ** is a [0mq](http://zeromq.org/) binding for **Swift 3**.

## Installation

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/Zewo/ZeroMQ.git", majorVersion: 0, minor: 5)
    ]
)
```

## Features

- [x] No `Foundation` dependency (**Linux ready**)
- [x] Context
- [x] Socket
- [x] Message
- [x] Poller
- [x] Proxy


##Example

```swift
import ZeroMQ

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

**ZeroMQ** requires 0mq version 4.1.2 to be installed. The easiest way on Mac OS X is through brew.

```
> brew install zeromq --with-libsodium
```

## Community

[![Slack](http://s13.postimg.org/ybwy92ktf/Slack.png)](https://zewo-slackin.herokuapp.com)

Join us on [Slack](https://zewo-slackin.herokuapp.com).

License
-------

**SwiftZMQ** is released under the MIT license. See LICENSE for details.

[swift-badge]: https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat
[swift-url]: https://swift.org
[platform-badge]: https://img.shields.io/badge/Platform-Mac%20%26%20Linux-lightgray.svg?style=flat
[platform-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
[slack-image]: http://s13.postimg.org/ybwy92ktf/Slack.png
[slack-badge]: https://zewo-slackin.herokuapp.com/badge.svg
[slack-url]: http://slack.zewo.io
