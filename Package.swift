import PackageDescription

let package = Package(
    name: "SwiftZMQ",
    dependencies: [
        .Package(url: "https://github.com/Zewo/CZeroMQ.git", majorVersion: 1),
        .Package(url: "https://github.com/Zewo/Data.git", majorVersion: 0, minor: 2)
    ]
)
