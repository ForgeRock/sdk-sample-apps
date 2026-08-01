// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ping_journey",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "ping-journey", targets: ["ping_journey"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(name: "ping_core", path: "../../ping_core/ios/ping_core"),
        .package(url: "https://github.com/ForgeRock/ping-ios-sdk", exact: "2.0.0")
    ],
    targets: [
        .target(
            name: "ping_journey",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "ping-core", package: "ping_core"),
                .product(name: "PingJourney", package: "ping-ios-sdk")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "ping_journeyTests",
            dependencies: ["ping_journey"]
        )
    ]
)
