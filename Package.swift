// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TextEngineKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "TextEngineKit",
            targets: ["TextEngineKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/fengmingdev/FMLogger.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "TextEngineKit",
            dependencies: [
                "FMLogger"
            ],
            path: "Sources/TextEngineKit"
        ),
        .testTarget(
            name: "TextEngineKitTests",
            dependencies: ["TextEngineKit"],
            path: "Tests/TextEngineKitTests"
        )
    ]
)