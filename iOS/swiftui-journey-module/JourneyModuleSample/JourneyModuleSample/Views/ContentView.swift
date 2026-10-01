//
//  ContentView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2024 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingExternalIdPFacebook
import PingExternalIdPGoogle
import PingBrowser
import PingDeviceId
import PingTamperDetector
import PingOidc
import PingBinding
import Combine

// MARK: - Menu Section Enum
enum MenuSection: CaseIterable, Identifiable {
    case authentication
    case userManagement
    case developerTools

    var id: String { title }

    var title: String {
        switch self {
        case .authentication: return "Authentication"
        case .userManagement: return "User Management"
        case .developerTools: return "Developer Tools"
        }
    }

    var items: [MenuItem] {
        switch self {
        case .authentication:
            return [.journey]
        case .userManagement:
            return [.token, .user, .deviceManagement, .logout]
        case .developerTools:
            return [.deviceInfo, .bindingKeys]
        }
    }
}

// MARK: - Menu Item Enum
enum MenuItem: String, CaseIterable, Identifiable {
    case journey = "Journey"
    case token = "Token"
    case user = "User"
    case logout = "Logout"
    case deviceManagement = "Device Management"
    case deviceInfo = "DeviceInfo"
    case bindingKeys = "Binding Keys"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .journey: return "map.fill"
        case .token: return "ticket.fill"
        case .user: return "person.fill"
        case .logout: return "rectangle.portrait.and.arrow.right"
        case .deviceManagement: return "iphone.and.arrow.forward"
        case .deviceInfo: return "iphone"
        case .bindingKeys: return "key.icloud.fill"
        }
    }

    var title: String {
        switch self {
        case .journey: return "Journey Flow"
        case .token: return "Access Token"
        case .user: return "User Info"
        case .logout: return "Logout"
        case .deviceManagement: return "Device Management"
        case .deviceInfo: return "Device Info"
        case .bindingKeys: return "Binding Keys"
        }
    }

    var subtitle: String {
        switch self {
        case .journey: return "Test Journey authentication"
        case .token: return "View current token"
        case .user: return "View user details"
        case .logout: return "End session"
        case .deviceManagement: return "Manage registered devices"
        case .deviceInfo: return "Collect device data"
        case .bindingKeys: return "Manage stored binding keys"
        }
    }
}

/// The main view of the application.
struct ContentView: View {
    @State private var deviceID: String = ""
    @State private var path: [MenuItem] = []
    @State private var deviceStatus: String = "Checking..."

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection

                    VStack(spacing: PingTheme.Spacing.large) {
                        ForEach(MenuSection.allCases) { section in
                            sectionCard(
                                title: section.title,
                                items: section.items
                            )
                        }

                        deviceStatusCard
                    }
                    .padding(.horizontal, PingTheme.Spacing.screen)
                    .padding(.top, PingTheme.Spacing.large)
                    .padding(.bottom, PingTheme.Spacing.scrollBottomInset)
                }
            }
            .pingScreenBackground()
            .navigationDestination(for: MenuItem.self) { item in
                switch item {
                case .journey:
                    JourneyView(path: $path)
                case .token:
                    AccessTokenView(menuItem: item)
                case .user:
                    UserInfoView(menuItem: item)
                case .deviceManagement:
                    DeviceManagementView(menuItem: item)
                case .logout:
                    LogOutView(path: $path)
                case .bindingKeys:
                    BindingKeysView()
                case .deviceInfo:
                    DeviceInfoView(menuItem: item)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                let id = try? await DefaultDeviceIdentifier().id
                deviceID = id ?? "Unknown"

                let tamperDetector = TamperDetector()
                let score = tamperDetector.analyze()

                if score > 0 {
                    deviceStatus = "Jailbroken (Score: \(score))"
                } else {
                    deviceStatus = "Secure"
                }
            }
        }
    }

    // MARK: - Header Section

    /// Full-bleed branded hero banner: the gradient shape is repartnered with
    /// the dynamic action colors so the foreground contrast holds in dark mode.
    private var headerSection: some View {
        ZStack {
            LinearGradient(
                colors: [PingTheme.Color.actionPrimary, PingTheme.Color.actionPrimaryPressed],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: PingTheme.Spacing.medium) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)

                Text("Orchestration SDK")
                    .font(PingTheme.Typography.display)
                    .foregroundColor(PingTheme.Color.actionPrimaryForeground)

                Text("Journey Module Sample")
                    .font(PingTheme.Typography.supporting.weight(.medium))
                    .foregroundColor(PingTheme.Color.actionPrimaryForeground.opacity(0.9))
            }
            .padding(.vertical, PingTheme.Spacing.large)
        }
    }

    // MARK: - Section Card

    private func sectionCard(title: String, items: [MenuItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(PingTheme.Typography.supporting.weight(.semibold))
                .foregroundStyle(PingTheme.Color.contentSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, PingTheme.Spacing.medium)
                .padding(.bottom, PingTheme.Spacing.small)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    menuItemButton(item)

                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, PingTheme.Control.infoRowDividerInset - PingTheme.Control.fieldPadding)
                    }
                }
            }
            .pingCardStyle(size: .rowList)
        }
    }

    // MARK: - Menu Item Button

    private func menuItemButton(_ item: MenuItem) -> some View {
        Button {
            path.append(item)
        } label: {
            HStack(spacing: PingTheme.Spacing.medium) {
                PingIconTile(systemName: item.icon, diameter: 40, iconSize: 20)

                VStack(alignment: .leading, spacing: PingTheme.Spacing.xxSmall) {
                    Text(item.title)
                        .font(PingTheme.Typography.body.weight(.medium))
                        .foregroundStyle(PingTheme.Color.contentPrimary)

                    Text(item.subtitle)
                        .pingSupportingText()
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: PingTheme.Control.Glyph.small, weight: .semibold))
                    .foregroundStyle(PingTheme.Color.contentSecondary)
            }
            .padding(.vertical, PingTheme.Spacing.small)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Device Status Card

    private var deviceStatusCard: some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.medium) {
            HStack {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: PingTheme.Control.Glyph.small, weight: .semibold))
                    .foregroundStyle(PingTheme.Color.actionPrimary)

                Text("Device Information")
                    .pingSectionHeader()

                Spacer()

                let isSecure = deviceStatus.contains("Secure")
                HStack(spacing: PingTheme.Spacing.xSmall) {
                    Image(systemName: isSecure ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: PingTheme.Control.Glyph.small, weight: .medium))
                        .foregroundStyle(isSecure ? PingTheme.Color.statusSuccess : PingTheme.Color.statusWarning)

                    Text(deviceStatus)
                        .font(PingTheme.Typography.caption.weight(.medium))
                        .foregroundStyle(isSecure ? PingTheme.Color.statusSuccess : PingTheme.Color.statusWarning)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: PingTheme.Spacing.xSmall) {
                Text("Device ID")
                    .pingCaptionText()

                Text(deviceID.isEmpty ? "Loading..." : deviceID)
                    .font(PingTheme.Typography.monospacedCaption)
                    .foregroundStyle(PingTheme.Color.contentPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .textSelection(.enabled)
            }
        }
        .pingCardStyle()
    }
}
