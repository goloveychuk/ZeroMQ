# ZeroMQ

[![Swift][swift-badge]][swift-url]
[![Zewo][zewo-badge]][zewo-url]
[![Platform][platform-badge]][platform-url]
[![License][mit-badge]][mit-url]
[![Slack][slack-badge]][slack-url]
[![Travis][travis-badge]][travis-url]
[![Codebeat][codebeat-badge]][codebeat-url]

**ZeroMQ** is a [0mq](http://zeromq.org/) binding for **Swift 3**.

## Features

- [x] Context
- [x] Socket
- [x] Message
- [x] Poller
- [x] Proxy

##Example

```swift
import ZeroMQ

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
```

## Installation

Install ZeroMQ system library

```sh
./setup_env.sh
```

Add `ZeroMQ` to `Package.swift`

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/Zewo/ZeroMQ.git", majorVersion: 0, minor: 5),
    ]
)
```

## Support

If you need any help you can join our [Slack](http://slack.zewo.io) and go to the **#help** channel. Or you can create a Github [issue](https://github.com/Zewo/Zewo/issues/new) in our main repository. When stating your issue be sure to add enough details, specify what module is causing the problem and reproduction steps.

## Community

[![Slack][slack-image]][slack-url]

The entire Zewo code base is licensed under MIT. By contributing to Zewo you are contributing to an open and engaged community of brilliant Swift programmers. Join us on [Slack](http://slack.zewo.io) to get to know us!

## License

This project is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-badge]: https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat
[swift-url]: https://swift.org
[zewo-badge]: https://img.shields.io/badge/Zewo-0.5-FF7565.svg?style=flat
[zewo-url]: http://zewo.io
[platform-badge]: https://img.shields.io/badge/Platforms-OS%20X%20--%20Linux-lightgray.svg?style=flat
[platform-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
[slack-image]: http://s13.postimg.org/ybwy92ktf/Slack.png
[slack-badge]: https://zewo-slackin.herokuapp.com/badge.svg
[slack-url]: http://slack.zewo.io
[travis-badge]: https://travis-ci.org/Zewo/ZeroMQ.svg?branch=master
[travis-url]: https://travis-ci.org/Zewo/ZeroMQ
[codebeat-badge]: https://codebeat.co/badges/baad8b1a-7649-496b-b224-ce59b33a1717
[codebeat-url]: https://codebeat.co/projects/github-com-zewo-zeromq