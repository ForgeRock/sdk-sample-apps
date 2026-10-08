//
//  MobilePairingCollectorView.swift
//  Davinci
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingOneMFA

/// Renders the DaVinci `MOBILE_PAIRING` collector: pairs the device with PingOne MFA
/// while the flow waits, then submits the outcome back to the flow.
/// - Phases: pairing → success (Continue) / failure (Continue) / initialization failure (Retry).
struct MobilePairingCollectorView: View {
    private enum Phase {
        case pairing
        case success
        case failure(code: String, message: String)
        case initializationFailure(message: String)
    }

    let collector: MobilePairingCollector
    let onNext: () async -> Void

    @State private var phase: Phase = .pairing
    @State private var pairingTask: Task<Void, Never>?
    @State private var isSubmitting = false

    var body: some View {
        VStack(spacing: 20) {
            switch phase {
            case .pairing:
                ProgressView()
                Text("Pairing your device…")
                actionButton("Cancel", role: .destructive) {
                    Task { await cancel() }
                }
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.green)
                Text("Pairing successful")
                actionButton("Continue") {
                    Task { await submit() }
                }
            case let .initializationFailure(message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.orange)
                Text("Unable to initialize PingOne MFA")
                Text(message)
                    .multilineTextAlignment(.center)
                actionButton("Retry") {
                    startPairingIfNeeded(forceRetry: true)
                }
            case let .failure(code, message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.orange)
                Text("Pairing failed")
                Text(code)
                    .font(.caption.monospaced())
                Text(message)
                    .multilineTextAlignment(.center)
                actionButton("Continue") {
                    Task { await submit() }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .onAppear { startPairingIfNeeded() }
        .onDisappear {
            pairingTask?.cancel()
            pairingTask = nil
        }
    }

    @ViewBuilder
    private func actionButton(
        _ title: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .tint(role == .destructive ? .red : .themeButtonBackground)
        .disabled(isSubmitting)
    }

    private func startPairingIfNeeded(forceRetry: Bool = false) {
        guard pairingTask == nil || forceRetry else { return }
        pairingTask?.cancel()
        pairingTask = Task { @MainActor in
            do {
                try await PingOneMFA.initialize(geo: .northAmerica)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                pairingTask = nil
                phase = .initializationFailure(message: error.localizedDescription)
                return
            }

            guard !Task.isCancelled else { return }
            let result = await collector.collect()
            guard !Task.isCancelled else { return }
            switch result {
            case .success:
                phase = .success
            case .failure:
                phase = failurePhase(from: collector.payload())
            }
        }
    }

    private func submit() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        await onNext()
    }

    private func cancel() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        collector.cancel()
        pairingTask?.cancel()
        await onNext()
    }

    private func failurePhase(from payload: [String: Any]?) -> Phase {
        let error = payload?["error"] as? [String: Any]
        let code = error?["code"] as? String ?? "INTERNAL_ERROR"
        let message = error?["message"] as? String ?? "Pairing failed"
        return .failure(code: code, message: message)
    }
}
