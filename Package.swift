import PackageDescription

let package = Package(
    name: "SwiftZMQ",
    dependencies: [
        .Package(url: "https://github.com/Zewo/CLibzmq.git", majorVersion: 1),
    ]
)