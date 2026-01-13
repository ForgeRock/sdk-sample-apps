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
            return [.deviceInfo, .logger, .storage, .bindingKeys]
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
    case logger = "Logger"
    case storage = "Storage"
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
        case .logger: return "doc.text.magnifyingglass"
        case .storage: return "externaldrive.fill"
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
        case .logger: return "Logger"
        case .storage: return "Storage"
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
        case .logger: return "Test logging"
        case .storage: return "Test storage"
        case .bindingKeys: return "Manage stored binding keys"
        }
    }
}

/// The main view of the application with redesigned UI
struct ContentView: View {
    @State private var deviceID: String = ""
    @State private var path: [MenuItem] = []
    @State private var deviceStatus: String = "Checking..."
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    headerSection
                    
                    // Content Section
                    VStack(spacing: 20) {
                        // Loop through all sections
                        ForEach(MenuSection.allCases) { section in
                            sectionCard(
                                title: section.title,
                                items: section.items
                            )
                        }
                        
                        deviceStatusCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
            }
            .background(Color(.systemGroupedBackground))
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
                case .logger:
                    LoggerView(menuItem: item)
                case .storage:
                    StorageView(menuItem: item)
                case .bindingKeys:
                    BindingKeysView()
                case .deviceInfo:
                    DeviceInfoView(menuItem: item)
                }
            }
            .task {
                let id = try? await DefaultDeviceIdentifier().id
                deviceID = id ?? "Unknown"
                
                let tamperDetector = TamperDetector()
                let score = tamperDetector.analyze()
                
                if score > 0 {
                    deviceStatus = "⚠️ Jailbroken (Score: \(score))"
                } else {
                    deviceStatus = "✓ Secure"
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        ZStack {
            LinearGradient(
                colors: [.themeButtonBackground, Color(red: 0.6, green: 0.1, blue: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 12) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                
                Text("Ping SDK")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Journey Module Sample")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(sdkVersion)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.vertical, 10)
        }
    }
    
    // MARK: - Section Card
    private func sectionCard(title: String, items: [MenuItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    menuItemButton(item)
                    
                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Menu Item Button
    private func menuItemButton(_ item: MenuItem) -> some View {
        Button {
            path.append(item)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: item.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(
                            colors: [.themeButtonBackground, Color(red: 0.6, green: 0.1, blue: 0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(item.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Device Status Card
    private var deviceStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.themeButtonBackground)
                
                Text("Device Information")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(deviceStatus)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(deviceStatus.contains("Secure") ? .green : .orange)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Device ID")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(deviceID.isEmpty ? "Loading..." : deviceID)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // Add computed properties:
    private var sdkVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
}

