// TODO: Uncomment for 2.0.0 release
////
////  PingOneProtectInitializeCallbackView.swift
////  PingExample
////
////  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
////
////  This software may be modified and distributed under the terms
////  of the MIT license. See the LICENSE file for details.
////
//
//import SwiftUI
//import PingProtect
//
//struct PingOneProtectInitializeCallbackView: View {
//    @StateObject private var viewModel: PingOneProtectInitializeViewModel
//
//    init(callback: PingOneProtectInitializeCallback, onNext: @escaping () -> Void) {
//        self._viewModel = StateObject(wrappedValue: PingOneProtectInitializeViewModel(callback: callback, onNext: onNext))
//    }
//
//    var body: some View {
//        VStack(spacing: 16) {
//            ProgressView()
//                .progressViewStyle(CircularProgressViewStyle())
//                .scaleEffect(1.5)
//
//            Text("Initializing device profile collection...")
//                .foregroundColor(.secondary)
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .padding()
//        .onAppear {
//            viewModel.startInitializationIfNeeded()
//        }
//        .onDisappear {
//            viewModel.cancelInitialization()
//        }
//    }
//}
//
//class PingOneProtectInitializeViewModel: ObservableObject {
//    @Published var isLoading: Bool = true
//
//    private var task: Task<Void, Never>?
//    private let callback: PingOneProtectInitializeCallback
//    private let onNext: () -> Void
//    private var hasStartedInitialization = false
//
//    init(callback: PingOneProtectInitializeCallback, onNext: @escaping () -> Void) {
//        self.callback = callback
//        self.onNext = onNext
//    }
//
//    @MainActor
//    func startInitializationIfNeeded() {
//        // Guard against multiple initialization attempts
//        guard !hasStartedInitialization else { return }
//
//        hasStartedInitialization = true
//        isLoading = true
//        let startTime = Date()
//
//        task = Task {
//            // Execute the initialization
//            _ = await callback.start()
//
//            // Calculate task duration
//            let taskDuration = Date().timeIntervalSince(startTime)
//
//            // If task completed too quickly, delay to meet minimum display time
//            let minimumDisplayTime: TimeInterval = 2.0
//            let remainingTime = minimumDisplayTime - taskDuration
//            if remainingTime > 0 {
//                try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
//            }
//
//            if !Task.isCancelled {
//                await MainActor.run {
//                    self.isLoading = false
//                    self.onNext()
//                }
//            }
//        }
//    }
//
//    func cancelInitialization() {
//        task?.cancel()
//        task = nil
//    }
//
//    deinit {
//        cancelInitialization()
//    }
//}
