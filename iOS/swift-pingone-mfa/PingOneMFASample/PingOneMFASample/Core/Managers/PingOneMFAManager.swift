// Core/Managers/PingOneMFAManager.swift
import Foundation
import Combine
import PingOneMFA

@MainActor
class PingOneMFAManager: ObservableObject {
    static let shared = PingOneMFAManager()

    @Published var accounts: [PingOneMfaAccount] = []
    @Published var pendingNotification: MFAPushNotification?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {}

    func fetchAccounts() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await PingOneMFA.getDeviceInfo()
            accounts = result.accounts
            if let errors = result.errors, !errors.isEmpty {
                errorMessage = errors.map { $0.localizedDescription }.joined(separator: "; ")
            }
        } catch {
            errorMessage = AppError.accountLoadFailed(error.localizedDescription).errorDescription
        }
        isLoading = false
    }

    func clearError() {
        errorMessage = nil
    }
}
