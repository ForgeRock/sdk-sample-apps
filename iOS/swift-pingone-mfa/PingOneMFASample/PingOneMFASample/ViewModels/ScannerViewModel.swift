// ViewModels/ScannerViewModel.swift
import Combine
import PingOneMFA
import Foundation

@MainActor
class ScannerViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var pairingSuccess = false

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
}
