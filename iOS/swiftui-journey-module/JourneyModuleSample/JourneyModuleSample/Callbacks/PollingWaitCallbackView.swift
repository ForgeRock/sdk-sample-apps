//
//  PollingWaitCallbackView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney
import Combine

struct PollingWaitCallbackView: View {
    @StateObject private var viewModel: PollingWaitViewModel

    init(callback: PollingWaitCallback, onTimeout: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: PollingWaitViewModel(callback: callback, onTimeout: onTimeout))
    }

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text(viewModel.message)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            ProgressView(value: viewModel.progress, total: 1.0)
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
        }
        .padding()
        .onAppear {
            viewModel.startPolling()
        }
        .onDisappear {
            viewModel.cancelPolling()
        }
    }
}


class PollingWaitViewModel: ObservableObject {
    @Published var progress: Double = 0.0

    private var task: Task<Void, Never>?
    private let callback: PollingWaitCallback
    private let onTimeout: () -> Void

    var message: String {
        callback.message
    }

    init(callback: PollingWaitCallback, onTimeout: @escaping () -> Void) {
        self.callback = callback
        self.onTimeout = onTimeout
    }

    @MainActor
    func startPolling() {
        progress = 0.0
        let waitTimeInSeconds = Double(callback.waitTime) / 1000.0
        let updateInterval = 0.1 // Update progress every 100ms for smooth animation
        let totalSteps = waitTimeInSeconds / updateInterval

        task = Task {
            for step in 0..<Int(totalSteps) {
                if Task.isCancelled { return }

                await MainActor.run {
                    self.progress = Double(step + 1) / totalSteps
                }

                try? await Task.sleep(nanoseconds: UInt64(updateInterval * 1_000_000_000))
            }

            if !Task.isCancelled {
                await MainActor.run {
                    self.onTimeout()
                }
            }
        }
    }

    func cancelPolling() {
        task?.cancel()
        task = nil
    }

    deinit {
        cancelPolling()
    }
}
