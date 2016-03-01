import PackageDescription

let package = Package(
    name: "SwiftZMQ",
    dependencies: [
        .Package(url: "https://github.com/younata/CZeroMQ.git", majorVersion: 1)
    ]
)
