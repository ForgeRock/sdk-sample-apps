// 
//  DeviceInfoView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI

/// Displays collected device profile data in two modes:
/// a styled card-based view grouped by sections (platform, hardware, network, etc.)
/// and a raw pretty-printed JSON view, toggled via a toolbar button.
struct DeviceInfoView: View {
    let menuItem: MenuItem
    @StateObject private var deviceInfoViewModel = DeviceInfoViewModel()
    @State private var viewMode: DeviceInfoViewMode = .styled
    
    var body: some View {
        ZStack {
            if deviceInfoViewModel.isLoading {
                PingLoadingSpinner()
            } else if let error = deviceInfoViewModel.error {
                VStack {
                    ErrorView(title: "Device Info Error", message: error)
                        .padding(.top, PingTheme.Spacing.small)
                    Spacer()
                }
            } else if viewMode == .raw {
                rawView
            } else {
                styledView
            }
        }
        .pingScreenBackground()
        .navigationTitle(menuItem.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !deviceInfoViewModel.isLoading && deviceInfoViewModel.error == nil {
                    Button {
                        viewMode = viewMode == .styled ? .raw : .styled
                    } label: {
                        Image(systemName: viewMode == .styled ? "curlybraces" : "list.bullet.rectangle")
                            .font(.system(size: PingTheme.Control.Glyph.small))
                            .frame(width: 24, height: 24)
                            .contentTransition(.identity)
                    }
                    .accessibilityLabel(viewMode == .styled ? "Show Raw JSON" : "Show Formatted View")
                    .buttonStyle(.plain)
                }
            }
        }
        .animation(.none, value: viewMode)
    }
    
    private var styledView: some View {
        ScrollView {
            VStack(spacing: PingTheme.Spacing.medium) {
                if !deviceInfoViewModel.topLevel.isEmpty {
                    sectionCard(icon: "info.circle.fill", title: "Device", entries: deviceInfoViewModel.topLevel)
                }
                
                ForEach(deviceInfoViewModel.sections, id: \.name) { section in
                    sectionCard(icon: sectionIcon(section.name), title: section.name.capitalized, entries: section.entries)
                }
            }
            .pingScrollContentPadding(top: PingTheme.Spacing.small)
        }
        .textSelection(.enabled)
    }
    
    private var rawView: some View {
        ScrollView {
            Text(deviceInfoViewModel.rawJSON)
                .font(PingTheme.Typography.monospacedCaption)
                .foregroundStyle(PingTheme.Color.contentPrimary)
                .padding(PingTheme.Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .pingCardStyle()
                .pingScrollContentPadding(top: PingTheme.Spacing.small)
        }
    }

    private func sectionCard(icon: String, title: String, entries: [(key: String, value: String)]) -> some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.medium) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: PingTheme.Control.Glyph.small))
                    .foregroundColor(PingTheme.Color.actionPrimary)
                Text(title)
                    .pingSectionHeader()
                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
                ForEach(entries, id: \.key) { entry in
                    PingInfoRow(
                        label: entry.key,
                        value: entry.value,
                        layout: .vertical,
                        valueStyle: .monospaced
                    )
                }
            }
        }
        .pingCardStyle()
    }
    
    private func sectionIcon(_ name: String) -> String {
        switch name {
        case "platform": return "iphone"
        case "hardware": return "cpu"
        case "network": return "wifi"
        case "telephony": return "phone.fill"
        case "browser": return "safari.fill"
        case "bluetooth": return "wave.3.right"
        case "location": return "location.fill"
        default: return "info.circle.fill"
        }
    }
}

private enum DeviceInfoViewMode {
    case styled, raw
}
