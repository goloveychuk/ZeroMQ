// swift-tools-version: 5.7.0

import PackageDescription

let package = Package(
    name: "ZeroMQ",
    dependencies: [
        .package(url: "https://github.com/Zewo/CZeroMQ.git", branch: "master")
    ]
)
