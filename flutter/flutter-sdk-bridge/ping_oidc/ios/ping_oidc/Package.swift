// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ping_oidc",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "ping-oidc", targets: ["ping_oidc"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(name: "ping_core", path: "../../ping_core/ios/ping_core"),
        .package(url: "https://github.com/ForgeRock/ping-ios-sdk", exact: "2.1.0")
    ],
    targets: [
        .target(
            name: "ping_oidc",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "ping-core", package: "ping_core"),
                .product(name: "PingOidc", package: "ping-ios-sdk"),
                .product(name: "PingBrowser", package: "ping-ios-sdk"),
                .product(name: "PingStorage", package: "ping-ios-sdk"),
                .product(name: "PingOrchestrate", package: "ping-ios-sdk"),
                .product(name: "PingLogger", package: "ping-ios-sdk")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "ping_oidcTests",
            dependencies: ["ping_oidc"]
        )
    ]
)
