// 
//  ReCaptchaEnterpriseCallbackView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import Combine
import PingJourney
import PingReCaptchaEnterprise

/**
 * A SwiftUI view for handling reCAPTCHA Enterprise verification during authentication flows.
 *
 * This view automatically initiates reCAPTCHA verification when displayed and shows
 * a loading indicator with progress message to inform the user that verification is in progress.
 * Once the verification completes successfully, it automatically proceeds to the next step in the journey.
 * If verification fails, an error message is displayed with a retry option.
 *
 * The UI displays a centered loading spinner with the message "Verifying security..."
 * during the verification process. The component handles the entire lifecycle of reCAPTCHA
 * execution without requiring user interaction for the actual CAPTCHA challenge.
 */
struct ReCaptchaEnterpriseCallbackView: View {
    @StateObject private var viewModel: ReCaptchaViewModel
    
    init(
        callback: ReCaptchaEnterpriseCallback,
        configBlock: @escaping (ReCaptchaEnterpriseConfig) -> Void = { _ in },
        onNext: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: ReCaptchaViewModel(
            callback: callback,
            onNext: onNext
        ))
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: PingTheme.Spacing.medium) {
            if viewModel.isLoading {
                PingLoadingSpinner()
                    .scaleEffect(1.2)

                Text("Verifying security...")
                    .multilineTextAlignment(.center)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: PingTheme.Spacing.medium) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: PingTheme.Control.Glyph.hero))
                        .foregroundStyle(PingTheme.Color.statusWarning)

                    Text("Verification Failed")
                        .pingSectionHeader()

                    Text(error)
                        .pingSupportingText()
                        .multilineTextAlignment(.center)

                    Button("Retry") {
                        viewModel.retry()
                    }
                    .buttonStyle(.pingSecondary)
                    .padding(.top, PingTheme.Spacing.small)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Edge spacing comes from CallbackView's screen padding; no own inset.
        .onAppear {
            viewModel.startVerification()
        }
        .onDisappear {
            viewModel.cancel()
        }
    }
}



@MainActor
class ReCaptchaViewModel: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    @Published var hasCompleted: Bool = false
    
    private var task: Task<Void, Never>?
    private let callback: ReCaptchaEnterpriseCallback
    private let onNext: () -> Void
    
    init(callback: ReCaptchaEnterpriseCallback, onNext: @escaping () -> Void) {
        self.callback = callback
        self.onNext = onNext
    }
    
    func startVerification() {
        guard task == nil, !hasCompleted else { return }
        
        isLoading = true
        errorMessage = nil
        
        task = Task { [weak self] in
            guard let self = self else { return }
            let result = await self.callback.verify{ config in
                // Optionally customize the configuration
                config.payload = ["firewallPolicyEvaluation": false,
                    "transactionData": [
                        "transactionId": "TXN-12345",
                        "paymentMethod": "CREDIT_CARD",
                        "cardBin": "123456",
                        "cardLastFour": "1234",
                        "currencyCode": "USD",
                        "value": 99.99
                    ],
                    "userInfo": [
                        "accountId": "user-abc123",
                    ]
                ]}
            
            if !Task.isCancelled {
                await MainActor.run {
                    self.task = nil
                    
                    switch result {
                    case .success:
                        self.hasCompleted = true
                        self.isLoading = false
                        self.onNext()
                    case .failure(let error):
                        self.isLoading = false
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func retry() {
        errorMessage = nil
        hasCompleted = false
        startVerification()
    }
    
    func cancel() {
        task?.cancel()
        task = nil
    }
}
