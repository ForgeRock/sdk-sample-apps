// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ping_device_profile",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "ping-device-profile", targets: ["ping_device_profile"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(name: "ping_core", path: "../ping_core"),
        .package(url: "https://github.com/ForgeRock/ping-ios-sdk", exact: "2.2.0")
    ],
    targets: [
        .target(
            name: "ping_device_profile",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "ping-core", package: "ping_core"),
                .product(name: "PingDeviceProfile", package: "ping-ios-sdk"),
                .product(name: "PingJourneyPlugin", package: "ping-ios-sdk")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
        // No .testTarget: a package test target can't link Flutter.framework, so the native tests
        // live in example/ios/RunnerTests, hosted by the example app.
    ]
)
