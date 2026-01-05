//
//  DeviceManagementView.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
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
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            // Main content with initialization handling
            if viewModel.isInitializing {
                initializingView
            } else if initializationFailed {
                initializationErrorView
            } else {
                mainContentView
            }
        }
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
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearMessages()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $showingUpdateSheet) {
            updateDeviceSheet
        }
    }
    
    // MARK: - Main Content View
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Device Type Picker
            deviceTypePicker
            
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
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Initializing Device Management...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Text("Retrieving authentication details")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Initialization Error View
    
    private var initializationErrorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Initialization Failed")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
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
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.themeButtonBackground, Color(red: 0.6, green: 0.1, blue: 0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Device Type Picker
    
    private var deviceTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DeviceType.allCases) { type in
                    deviceTypeButton(type)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    private func deviceTypeButton(_ type: DeviceType) -> some View {
        Button {
            Task {
                await viewModel.loadDevices(for: type)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 14))
                
                Text(type.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                viewModel.selectedDeviceType == type
                    ? LinearGradient(
                        colors: [.themeButtonBackground, Color(red: 0.6, green: 0.1, blue: 0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color(.systemGray5), Color(.systemGray5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
            .foregroundColor(viewModel.selectedDeviceType == type ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(viewModel.isLoading)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading \(viewModel.selectedDeviceType.rawValue.lowercased()) devices...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Device List View
    
    @ViewBuilder
    private var deviceListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Success message
                if let success = viewModel.successMessage {
                    successBanner(success)
                }
                
                // Device list based on selected type
                switch viewModel.selectedDeviceType {
                case .oath:
                    deviceList(devices: viewModel.oathDevices)
                case .push:
                    deviceList(devices: viewModel.pushDevices)
                case .bound:
                    deviceList(devices: viewModel.boundDevices)
                case .profile:
                    deviceList(devices: viewModel.profileDevices)
                case .webAuthn:
                    deviceList(devices: viewModel.webAuthnDevices)
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Generic Device List
    
    private func deviceList<T: Device>(devices: [T]) -> some View {
        Group {
            if devices.isEmpty {
                emptyStateView
            } else {
                ForEach(Array(devices.enumerated()), id: \.element.id) { index, device in
                    deviceCard(device)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Devices Found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("No \(viewModel.selectedDeviceType.rawValue.lowercased()) devices are registered for this user.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
    
    // MARK: - Device Card
    
    private func deviceCard<T: Device>(_ device: T) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: viewModel.selectedDeviceType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.themeButtonBackground)
                
                Text(device.deviceName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                
                    Button {
                        deviceToUpdate = (device.id, device.deviceName, viewModel.selectedDeviceType)
                        updatedName = device.deviceName
                        showingUpdateSheet = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    }
                    .disabled(viewModel.isLoading)
               
                
                Button(role: .destructive) {
                    Task {
                        await deleteDevice(device)
                    }
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.red)
                }
                .disabled(viewModel.isLoading)
            }
            
            Divider()
            
            // Device-specific details
            VStack(alignment: .leading, spacing: 8) {
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
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                detailRow(label: "Location", value: "Lat: \(location.latitude), Lon: \(location.longitude)")
            }
            
            if !device.metadata.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Metadata:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(device.metadata.keys.sorted()), id: \.self) { key in
                        if let value = device.metadata[key] {
                            Text("\(key): \(String(describing: value))")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.primary)
                                .lineLimit(1)
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
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(2)
        }
    }
    
    // MARK: - Success Banner
    
    private func successBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button {
                viewModel.clearMessages()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Update Sheet
    
    private var updateDeviceSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Device Name")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Enter new name", text: $updatedName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 16))
                        .autocorrectionDisabled()
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 20)
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
        
        default:
            break
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DeviceManagementView(menuItem: .deviceManagement)
    }
}
