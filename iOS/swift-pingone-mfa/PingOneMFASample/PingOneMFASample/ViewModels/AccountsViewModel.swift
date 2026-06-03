// ViewModels/AccountsViewModel.swift
import Foundation
import Combine
import PingOneMFA

@MainActor
class AccountsViewModel: ObservableObject {
    @Published var accounts: [PingOneMfaAccount] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let manager: PingOneMFAManager
    private var cancellables = Set<AnyCancellable>()

    init(manager: PingOneMFAManager = .shared) {
        self.manager = manager
        manager.$accounts
            .receive(on: RunLoop.main)
            .assign(to: &$accounts)
        manager.$isLoading
            .receive(on: RunLoop.main)
            .assign(to: &$isLoading)
        manager.$errorMessage
            .receive(on: RunLoop.main)
            .assign(to: &$errorMessage)
    }

    func loadAccounts() async {
        await manager.fetchAccounts()
    }

    func clearError() {
        manager.clearError()
    }
}
