// swift-tools-version: 5.7.0

import PackageDescription

let package = Package(
    name: "ZeroMQ",
    products: [
        .library(
            name: "ZeroMQ",
            targets: ["ZeroMQ"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Zewo/CZeroMQ.git", branch: "master")
    ],
    targets: [
        .target(
            name: "ZeroMQ",
            dependencies: ["CZeroMQ"]
        )
    ]
)
