import PackageDescription

let package = Package(
    name: "ZeroMQ",
    targets: [Target(name: "ZeroMQ", dependencies: ["CZeroMQ"])],
    dependencies: [
        .Package(url: "https://github.com/open-swift/C7.git", majorVersion: 0, minor: 5)
    ]
)
