import PackageDescription

let package = Package(
    name: "ZeroMQ",
    dependencies: [
        .Package(url: "https://github.com/Zewo/CZeroMQ.git", majorVersion: 1, minor: 0),
    ]
)
