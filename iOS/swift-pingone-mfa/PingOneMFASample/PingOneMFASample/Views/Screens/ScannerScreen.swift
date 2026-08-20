// Views/Screens/ScannerScreen.swift
import SwiftUI

struct ScannerScreen: View {
    @StateObject private var viewModel = ScannerViewModel()
    @EnvironmentObject private var coordinator: AppNavigationCoordinator
    @EnvironmentObject private var manager: PingOneMFAManager
    @FocusState private var isTextFieldFocused: Bool
    @State private var manualKey = ""

    var body: some View {
        ZStack {
            // The view model is the delegate, so it is attached before the scanner's
            // `viewDidLoad` runs and setup errors reach the alert below.
            QRCodeScanner(delegate: viewModel, isScanningEnabled: viewModel.isScanningEnabled)
                .ignoresSafeArea()

            VStack {
                Spacer()
                VStack(spacing: 10) {
                    TextField("Enter pairing key manually", text: $manualKey)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($isTextFieldFocused)

                    Button {
                        isTextFieldFocused = false
                        Task { await viewModel.handleCode(manualKey) }
                    } label: {
                        Text(viewModel.isLoading ? "Pairing…" : "Pair")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.themeButtonBackground)
                    .disabled(manualKey.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
            }
        }
        .navigationTitle("Add Account")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.pairingSuccess) { _, success in
            if success {
                manualKey = ""
                Task {
                    await manager.fetchAccounts()
                    coordinator.dismissScanner()
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
