import PackageDescription

let package = Package(
    name: "ZeroMQ",
    targets: [Target(name: "ZeroMQ", dependencies: ["CZeroMQ"])],
    dependencies: [
        .Package(url: "https://github.com/open-swift/S4.git", majorVersion: 0, minor: 5)
    ]
)
