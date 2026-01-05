//
//  DeviceProfileCallbackView.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingJourney
import PingDeviceProfile

/**
 * A SwiftUI view for handling device profile collection during authentication flows.
 *
 * This view automatically initiates device profile collection when displayed and shows
 * a loading indicator with progress message to inform the user that device profiling is in progress.
 * Once the collection completes successfully, it automatically proceeds to the next step in the journey.
 *
 * The UI displays a centered loading spinner with the message "Gathering Device Profile..."
 * during the collection process. The component handles the entire lifecycle of device profile
 * collection without requiring user interaction.
 */
struct DeviceProfileCallbackView: View {
    
    @State private var isLoading: Bool = true
    @State private var task: Task<Void, Never>?
    private let callback: DeviceProfileCallback
    private let onNext: () -> Void
    
    init(callback: DeviceProfileCallback, onNext: @escaping () -> Void) {
        self.callback = callback
        self.onNext = onNext
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.2)
                
                Text("Gathering Device Profile...")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
        .onAppear {
            startDeviceProfileCollection()
        }
        .onDisappear {
            cancelCollection()
        }
    }
    
    @MainActor
    private func startDeviceProfileCollection() {
        // Prevent multiple concurrent collections
        guard task == nil && isLoading else { return }
        
        isLoading = true
        
        task = Task {
            do {
                _ = await callback.collect()
                
                if !Task.isCancelled {
                    await MainActor.run {
                        self.isLoading = false
                        self.task = nil  // Clear task reference
                        self.onNext()
                    }
                }
            }
        }
    }
    
    private func cancelCollection() {
        task?.cancel()
        task = nil
    }
}
