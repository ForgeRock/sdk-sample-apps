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
                // If your plugin requires a privacy manifest, for example if it uses any required
                // reason APIs, update the PrivacyInfo.xcprivacy file to describe your plugin's
                // privacy impact, and then uncomment these lines. For more information, see
                // https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
                // .process("PrivacyInfo.xcprivacy"),

                // If you have other resources that need to be bundled with your plugin, refer to
                // the following instructions to add them:
                // https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package
            ]
        ),
        .testTarget(
            name: "ping_journeyTests",
            dependencies: ["ping_journey"]
        )
    ]
)
