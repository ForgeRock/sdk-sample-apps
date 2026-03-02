//
//  AboutViewModel.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import UIKit
import Combine

/// ViewModel for the About screen.
@MainActor
class AboutViewModel: ObservableObject {
    // MARK: - App Information
    var appName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ??
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "MFA Example"
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }

    var copyright: String {
        "Copyright © 2026 Ping Identity Corporation. All rights reserved."
    }

    var description: String {
        "A sample iOS application demonstrating Multi-Factor Authentication (MFA) using Ping Identity SDK. Supports OATH (TOTP/HOTP), Push Authentication, and Journey-based MFA registration."
    }

    // MARK: - SDK Information
    var sdkVersions: [(name: String, version: String)] {
        [
            ("Ping iOS SDK", "4.0.0"),
            ("PingOath", "4.0.0"),
            ("PingPush", "4.0.0"),
            ("PingOrchestrate", "4.0.0")
        ]
    }

    // MARK: - Links
    var githubURL: URL? {
        URL(string: "https://github.com/ForgeRock/ping-ios-sdk")
    }

    var documentationURL: URL? {
        URL(string: "https://docs.pingidentity.com/sdks/latest/sdks/index.html")
    }

    var licenseURL: URL? {
        URL(string: "https://github.com/ForgeRock/ping-ios-sdk/blob/main/LICENSE")
    }

    // MARK: - Actions
    func openURL(_ url: URL?) {
        guard let url = url else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
