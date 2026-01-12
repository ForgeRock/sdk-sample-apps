//
//  PingOneProtectEvaluationCallbackView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingProtect
import Combine

/**
 * A SwiftUI view for collecting PingOne Protect device profile data during authentication flows.
 *
 * This view automatically initiates device profile data collection when displayed, gathering
 * device signals and behavioral data for risk assessment. A loading indicator is shown for a
 * minimum duration to provide user feedback. Once collection completes, the view automatically
 * proceeds to the next step. This data helps detect fraud and assess authentication risk.
 *
 * **User Action Required:** NO - The data collection process is fully automatic.
 *
 * The UI displays a centered loading spinner with the message "Collecting device profile..."
 * The view ensures a minimum display time for better UX even if collection completes quickly.
 */
struct PingOneProtectEvaluationCallbackView: View {
    @StateObject private var viewModel: PingOneProtectEvaluationViewModel

    init(callback: PingOneProtectEvaluationCallback, onNext: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: PingOneProtectEvaluationViewModel(callback: callback, onNext: onNext))
    }

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)

            Text("Collecting device profile ...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .onAppear {
            viewModel.startEvaluationIfNeeded()
        }
        .onDisappear {
            viewModel.cancelEvaluation()
        }
    }
}

class PingOneProtectEvaluationViewModel: ObservableObject {
    @Published var isLoading: Bool = true

    nonisolated(unsafe) private var task: Task<Void, Never>?
    private let callback: PingOneProtectEvaluationCallback
    private let onNext: () -> Void
    private var hasStartedEvaluation = false

    init(callback: PingOneProtectEvaluationCallback, onNext: @escaping () -> Void) {
        self.callback = callback
        self.onNext = onNext
    }

    @MainActor
    func startEvaluationIfNeeded() {
        // Guard against multiple evaluation attempts
        guard !hasStartedEvaluation else { return }

        hasStartedEvaluation = true
        isLoading = true
        let startTime = Date()

        task = Task {
            // Execute the evaluation
            _ = await callback.collect()

            // Calculate task duration
            let taskDuration = Date().timeIntervalSince(startTime)

            // If task completed too quickly, delay to meet minimum display time
            let minimumDisplayTime: TimeInterval = 2.0
            let remainingTime = minimumDisplayTime - taskDuration
            if remainingTime > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
            }

            if !Task.isCancelled {
                await MainActor.run {
                    self.isLoading = false
                    self.onNext()
                }
            }
        }
    }

    nonisolated func cancelEvaluation() {
        task?.cancel()
        task = nil
    }

    deinit {
        cancelEvaluation()
    }
}
