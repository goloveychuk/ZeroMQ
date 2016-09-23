import PackageDescription

let package = Package(
    name: "ZeroMQ",
    dependencies: [
        .Package(url: "https://github.com/Zewo/Core.git", majorVersion: 0, minor: 13),
        .Package(url: "https://github.com/Zewo/CZeroMQ.git", majorVersion: 1, minor: 0),
    ]
)
