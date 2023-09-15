// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "EventBus",
    products: [
        .library(name: "EventBus", targets: ["EventBus"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftarium/WeakRef.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "EventBus", dependencies: ["WeakRef"]),
        .testTarget(name: "EventBusTests", dependencies: ["EventBus"]),
    ],
    swiftLanguageVersions: [.v5]
)
