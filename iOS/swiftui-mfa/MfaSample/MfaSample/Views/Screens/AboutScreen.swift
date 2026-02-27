//
//  AboutScreen.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

/// Screen displaying app information, version details, and links.
struct AboutScreen: View {
    @StateObject private var viewModel = AboutViewModel()

    var body: some View {
        List {
            // App Icon and Name
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        // App Icon
                        if let iconName = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
                           let primaryIcon = iconName["CFBundlePrimaryIcon"] as? [String: Any],
                           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
                           let lastIcon = iconFiles.last {
                            Image(uiImage: UIImage(named: lastIcon) ?? UIImage())
                                .resizable()
                                .frame(width: 80, height: 80)
                                .cornerRadius(16)
                        } else {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                        }

                        Text(viewModel.appName)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Version \(viewModel.appVersion) (\(viewModel.buildNumber))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
            }
            .listRowBackground(Color.clear)

            // Description
            Section {
                Text(viewModel.description)
                    .font(.body)
                    .foregroundColor(.secondary)
            } header: {
                Text("About")
            }

            // Version Information
            Section {
                InfoRow(label: "Version", value: viewModel.appVersion)
                InfoRow(label: "Build", value: viewModel.buildNumber)
                InfoRow(label: "Bundle ID", value: viewModel.bundleIdentifier)
            } header: {
                Text("App Information")
            }

            // SDK Versions
            Section {
                ForEach(viewModel.sdkVersions, id: \.name) { sdk in
                    InfoRow(label: sdk.name, value: sdk.version)
                }
            } header: {
                Text("SDK Versions")
            }

            // Links
            Section {
                Button(action: {
                    viewModel.openURL(viewModel.githubURL)
                }) {
                    Label("GitHub Repository", systemImage: "link")
                }

                Button(action: {
                    viewModel.openURL(viewModel.documentationURL)
                }) {
                    Label("Documentation", systemImage: "book")
                }

                Button(action: {
                    viewModel.openURL(viewModel.licenseURL)
                }) {
                    Label("License", systemImage: "doc.text")
                }
            } header: {
                Text("Resources")
            }

            // Copyright
            Section {
                Text(viewModel.copyright)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("About")
    }
}

// MARK: - Info Row
private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationView {
        AboutScreen()
    }
}
