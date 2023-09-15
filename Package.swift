// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "EventBus",
    products: [
        .library(name: "EventBus", targets: ["EventBus"]),
    ],
    targets: [
        .target(name: "EventBus", dependencies: []),
        .testTarget(name: "EventBusTests", dependencies: ["EventBus"]),
    ],
    swiftLanguageVersions: [.v5]
)
