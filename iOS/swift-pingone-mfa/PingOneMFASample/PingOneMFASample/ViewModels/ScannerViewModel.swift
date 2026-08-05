// ViewModels/ScannerViewModel.swift
import Combine
import PingOneMFA
import Foundation

@MainActor
class ScannerViewModel: ObservableObject, QRCodeScannerDelegate {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var pairingSuccess = false

    /// The scanner accepts a new code only while idle: not pairing, no error still
    /// on screen, and not already paired. A failed pairing therefore re-arms the
    /// scanner as soon as the user dismisses the error.
    var isScanningEnabled: Bool {
        !isLoading && errorMessage == nil && !pairingSuccess
    }

    func handleCode(_ key: String) async {
        let trimmed = key.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isLoading else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil
        pairingSuccess = false

        do {
            try await PingOneMFA.pair(pairingKey: trimmed)
            successMessage = "Successfully paired with PingOne MFA."
            pairingSuccess = true
        } catch {
            errorMessage = AppError.pairingFailed(error.localizedDescription).errorDescription
        }

        isLoading = false
    }

    // MARK: - QRCodeScannerDelegate

    func didScan(code: String) {
        Task { await handleCode(code) }
    }

    func didFailWithError(error: Error) {
        errorMessage = error.localizedDescription
    }
}
