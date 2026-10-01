//
//  DeviceManagementView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDeviceClient

/// View for managing devices
struct DeviceManagementView: View {
    let menuItem: MenuItem
    @StateObject private var viewModel = DeviceManagementViewModel()
    @State private var showingUpdateSheet = false
    @State private var deviceToUpdate: (id: String, name: String, type: DeviceType)?
    @State private var updatedName = ""
    @State private var initializationFailed = false
    
    var body: some View {
        ZStack {
            // Main content with initialization handling
            if viewModel.isInitializing {
                initializingView
            } else if initializationFailed {
                initializationErrorView
            } else {
                mainContentView
            }
        }
        .pingScreenBackground()
        .navigationTitle(menuItem.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await viewModel.refresh()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh Devices")
                .disabled(viewModel.isLoading || viewModel.isInitializing)
            }
        }
        .task {
            // Initialize and load devices only if successful
            if await viewModel.initialize() {
                await viewModel.loadDevices(for: .oath)
                initializationFailed = false
            } else {
                initializationFailed = true
            }
        }
        .pingErrorAlert(errorMessage: $viewModel.errorMessage)
        .sheet(isPresented: $showingUpdateSheet) {
            updateDeviceSheet
        }
    }
    
    // MARK: - Main Content View
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Device Type Picker
            TabPicker(
                selection: $viewModel.selectedDeviceType,
                label: \.rawValue,
                icon: \.icon,
                onSelect: { type in
                    Task { await viewModel.loadDevices(for: type) }
                },
                isDisabled: viewModel.isLoading
            )
            
            // Content
            if viewModel.isLoading {
                loadingView
            } else {
                deviceListView
            }
        }
    }
    
    // MARK: - Initializing View
    
    private var initializingView: some View {
        VStack(spacing: PingTheme.Spacing.large) {
            PingLoadingSpinner()

            Text("Initializing Device Management...")
                .font(PingTheme.Typography.body.weight(.medium))
                .foregroundStyle(PingTheme.Color.contentPrimary)

            Text("Retrieving authentication details")
                .pingSupportingText()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Initialization Error View

    private var initializationErrorView: some View {
        EmptyStateView(
            icon: "exclamationmark.triangle.fill",
            title: "Initialization Failed",
            subtitle: viewModel.errorMessage
        ) {
            Button {
                Task {
                    initializationFailed = false
                    if await viewModel.initialize() {
                        await viewModel.loadDevices(for: .oath)
                        initializationFailed = false
                    } else {
                        initializationFailed = true
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
            }
            .buttonStyle(.pingPrimary)
            .padding(.top, PingTheme.Spacing.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: PingTheme.Spacing.medium) {
            PingLoadingSpinner()

            Text("Loading \(viewModel.selectedDeviceType.rawValue.lowercased()) devices...")
                .pingBodySecondary()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Device List View

    @ViewBuilder
    private var deviceListView: some View {
        VStack(spacing: 0) {
            // Success message stays fixed above the list so it remains
            // visible even when the action that produced it emptied the list.
            if let success = viewModel.successMessage {
                successBanner(success)
                    .padding(.horizontal, PingTheme.Spacing.screen)
                    .padding(.top, PingTheme.Spacing.screen)
            }

            // Device list based on selected type
            switch viewModel.selectedDeviceType {
            case .oath:
                deviceListContent(devices: viewModel.oathDevices)
            case .push:
                deviceListContent(devices: viewModel.pushDevices)
            case .bound:
                deviceListContent(devices: viewModel.boundDevices)
            case .profile:
                deviceListContent(devices: viewModel.profileDevices)
            case .webAuthn:
                deviceListContent(devices: viewModel.webAuthnDevices)
            }
        }
    }

    // MARK: - Generic Device List

    @ViewBuilder
    private func deviceListContent<T: Device>(devices: [T]) -> some View {
        if devices.isEmpty {
            PingCenteredScrollContent { emptyStateView }
        } else {
            ScrollView {
                LazyVStack(spacing: PingTheme.Spacing.medium) {
                    ForEach(Array(devices.enumerated()), id: \.element.id) { index, device in
                        deviceCard(device)
                    }
                }
                .padding(PingTheme.Spacing.screen)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "tray",
            title: "No Devices Found",
            subtitle: "No \(viewModel.selectedDeviceType.rawValue.lowercased()) devices are registered for this user."
        )
    }
    
    // MARK: - Device Card
    
    private func deviceCard<T: Device>(_ device: T) -> some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.medium) {
            // Header
            HStack {
                Image(systemName: viewModel.selectedDeviceType.icon)
                    .font(.system(size: PingTheme.Control.Glyph.small))
                    .foregroundColor(PingTheme.Color.actionPrimary)

                Text(device.deviceName)
                    .pingSectionHeader()

                Spacer()

                Button {
                    deviceToUpdate = (device.id, device.deviceName, viewModel.selectedDeviceType)
                    updatedName = device.deviceName
                    showingUpdateSheet = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: PingTheme.Control.Glyph.small))
                        .foregroundStyle(PingTheme.Color.actionPrimary)
                }
                .disabled(viewModel.isLoading)

                Button(role: .destructive) {
                    Task {
                        await deleteDevice(device)
                    }
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: PingTheme.Control.Glyph.small))
                        .foregroundStyle(PingTheme.Color.statusError)
                }
                .disabled(viewModel.isLoading)
            }

            Divider()

            // Device-specific details
            VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
                if let oathDevice = device as? OathDevice {
                    oathDeviceDetails(oathDevice)
                } else if let pushDevice = device as? PushDevice {
                    pushDeviceDetails(pushDevice)
                } else if let boundDevice = device as? BoundDevice {
                    boundDeviceDetails(boundDevice)
                } else if let profileDevice = device as? ProfileDevice {
                    profileDeviceDetails(profileDevice)
                } else if let webAuthnDevice = device as? WebAuthnDevice {
                    webAuthnDeviceDetails(webAuthnDevice)
                }
            }
        }
        .pingCardStyle()
    }
    
    // MARK: - Device Type Specific Details
    
    private func oathDeviceDetails(_ device: OathDevice) -> some View {
        Group {
            detailRow(label: "UUID", value: device.uuid)
            detailRow(label: "Created", value: formatDate(device.createdDate))
            detailRow(label: "Last Access", value: formatDate(device.lastAccessDate))
        }
    }
    
    private func pushDeviceDetails(_ device: PushDevice) -> some View {
        Group {
            detailRow(label: "UUID", value: device.uuid)
            detailRow(label: "Created", value: formatDate(device.createdDate))
            detailRow(label: "Last Access", value: formatDate(device.lastAccessDate))
        }
    }
    
    private func boundDeviceDetails(_ device: BoundDevice) -> some View {
        Group {
            detailRow(label: "Device ID", value: device.deviceId)
            detailRow(label: "UUID", value: device.uuid)
            detailRow(label: "Created", value: formatDate(device.createdDate))
            detailRow(label: "Last Access", value: formatDate(device.lastAccessDate))
        }
    }
    
    private func profileDeviceDetails(_ device: ProfileDevice) -> some View {
        Group {
            detailRow(label: "Identifier", value: device.identifier)
            detailRow(label: "Last Selected", value: formatDate(device.lastSelectedDate))

            if let location = device.location {
                detailRow(label: "Location", value: "Lat: \(String(describing: location.latitude)), Lon: \(String(describing: location.longitude))")
            }

            if !device.metadata.isEmpty {
                VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
                    Text("Metadata:")
                        .font(PingTheme.Typography.caption.weight(.medium))
                        .foregroundStyle(PingTheme.Color.contentSecondary)

                    ForEach(Array(device.metadata.keys.sorted()), id: \.self) { key in
                        if let value = device.metadata[key] {
                            PingInfoRow(
                                label: key,
                                value: String(describing: value),
                                valueStyle: .monospaced
                            )
                        }
                    }
                }
            }
        }
    }

    private func webAuthnDeviceDetails(_ device: WebAuthnDevice) -> some View {
        Group {
            detailRow(label: "Credential ID", value: device.credentialId)
            detailRow(label: "UUID", value: device.uuid)
            detailRow(label: "Created", value: formatDate(device.createdDate))
            detailRow(label: "Last Access", value: formatDate(device.lastAccessDate))
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        PingInfoRow(label: label, value: value, valueStyle: .monospaced)
    }

    // MARK: - Success Banner

    private func successBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(PingTheme.Color.statusSuccess)

            Text(message)
                .font(PingTheme.Typography.supporting)
                .foregroundStyle(PingTheme.Color.contentPrimary)

            Spacer()

            Button {
                viewModel.clearMessages()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(PingTheme.Color.contentSecondary)
            }
        }
        .padding(PingTheme.Spacing.compact)
        .background(PingTheme.Color.statusSuccess.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: PingTheme.Shape.fieldRadius))
    }

    // MARK: - Update Sheet

    private var updateDeviceSheet: some View {
        NavigationView {
            VStack(spacing: PingTheme.Spacing.large) {
                VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
                    Text("Device Name")
                        .font(PingTheme.Typography.supporting.weight(.medium))
                        .foregroundStyle(PingTheme.Color.contentSecondary)

                    TextField("Enter new name", text: $updatedName)
                        .pingTextFieldStyle()
                        .font(PingTheme.Typography.body)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, PingTheme.Spacing.screen)

                Spacer()
            }
            .padding(.top, PingTheme.Spacing.screen)
            .navigationTitle("Update Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingUpdateSheet = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveDeviceUpdate()
                            showingUpdateSheet = false
                        }
                    }
                    .disabled(updatedName.isEmpty || updatedName == deviceToUpdate?.name)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func deleteDevice<T: Device>(_ device: T) async {
        switch viewModel.selectedDeviceType {
        case .oath:
            if let oathDevice = device as? OathDevice {
                await viewModel.deleteOathDevice(oathDevice)
            }
        case .push:
            if let pushDevice = device as? PushDevice {
                await viewModel.deletePushDevice(pushDevice)
            }
        case .bound:
            if let boundDevice = device as? BoundDevice {
                await viewModel.deleteBoundDevice(boundDevice)
            }
        case .profile:
            if let profileDevice = device as? ProfileDevice {
                await viewModel.deleteProfileDevice(profileDevice)
            }
        case .webAuthn:
            if let webAuthnDevice = device as? WebAuthnDevice {
                await viewModel.deleteWebAuthnDevice(webAuthnDevice)
            }
        }
    }
    
    private func saveDeviceUpdate() async {
        guard let deviceToUpdate = deviceToUpdate else { return }
        
        switch deviceToUpdate.type {
        case .bound:
            if let device = viewModel.boundDevices.first(where: { $0.id == deviceToUpdate.id }) {
                await viewModel.updateBoundDevice(device, newName: updatedName)
            }
        case .profile:
            if let device = viewModel.profileDevices.first(where: { $0.id == deviceToUpdate.id }) {
                await viewModel.updateProfileDevice(device, newName: updatedName)
            }
        case .webAuthn:
            if let device = viewModel.webAuthnDevices.first(where: { $0.id == deviceToUpdate.id }) {
                await viewModel.updateWebAuthnDevice(device, newName: updatedName)
            }
        case .push:
            if let device = viewModel.pushDevices.first(where: { $0.id == deviceToUpdate.id }) {
                await viewModel.updatePushDevice(device, newName: updatedName)
            }
        case .oath:
            if let device = viewModel.oathDevices.first(where: { $0.id == deviceToUpdate.id }) {
                await viewModel.updateOathDevice(device, newName: updatedName)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DeviceManagementView(menuItem: .deviceManagement)
    }
}
