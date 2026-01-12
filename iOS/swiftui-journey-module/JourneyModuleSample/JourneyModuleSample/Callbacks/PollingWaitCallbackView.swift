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

/**
 * A SwiftUI view for displaying a polling wait state during authentication flows.
 *
 * This view shows a progress indicator while waiting for a server-side operation to complete,
 * such as waiting for out-of-band authentication, email verification, or external approval.
 * The view displays a message and animated progress indicator for the specified wait duration.
 * Once the timeout expires, it automatically triggers the next polling attempt.
 *
 * **User Action Required:** NO - The wait and polling process is fully automatic.
 *
 * The UI displays the server-provided message and a circular progress indicator that smoothly
 * animates from 0% to 100% over the wait duration. Common use cases include push notification
 * approval waits or QR code scanning timeouts.
 */
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

    nonisolated(unsafe) private var task: Task<Void, Never>?
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

    nonisolated func cancelPolling() {
        task?.cancel()
        task = nil
    }

    deinit {
        cancelPolling()
    }
}
