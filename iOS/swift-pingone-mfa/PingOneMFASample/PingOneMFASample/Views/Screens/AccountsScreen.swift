// Views/Screens/AccountsScreen.swift
import SwiftUI
import PingOneMFA

struct AccountsScreen: View {
    @StateObject private var viewModel = AccountsViewModel()
    @EnvironmentObject private var coordinator: AppNavigationCoordinator
    @EnvironmentObject private var manager: PingOneMFAManager

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            Group {
                if viewModel.isLoading && viewModel.accounts.isEmpty {
                    ProgressView("Loading accounts…")
                } else if viewModel.accounts.isEmpty {
                    EmptyStateView(
                        icon: "person.2.slash",
                        title: "No MFA Accounts",
                        message: "Scan a QR code or enter a pairing key to add your first account.",
                        actionTitle: "Add Account",
                        action: { coordinator.showScanner = true }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            OtpHeaderView()
                            Text("Users")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 4)
                            ForEach(viewModel.accounts, id: \.id) { account in
                                AccountCardView(account: account)
                            }
                        }
                        .padding()
                    }
                    .refreshable { await viewModel.loadAccounts() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottomTrailing) {
                if !viewModel.isLoading || !viewModel.accounts.isEmpty {
                    Button { coordinator.showScanner = true } label: {
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.themeButtonBackground)
                            .clipShape(Circle())
                            .shadow(radius: 4, x: 0, y: 2)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("MFA Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $coordinator.showScanner) {
            NavigationStack {
                ScannerScreen()
                    .environmentObject(coordinator)
                    .environmentObject(manager)
            }
        }
        .sheet(item: $manager.pendingNotification) { notification in
            NotificationView(notification: notification)
                .onDisappear { manager.pendingNotification = nil }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task { await viewModel.loadAccounts() }
    }
}
