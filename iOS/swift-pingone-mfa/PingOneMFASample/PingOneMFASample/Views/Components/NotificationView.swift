// Views/Components/NotificationView.swift
import SwiftUI
import PingOneMFA

struct NotificationView: View {
    @StateObject private var viewModel: NotificationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var enteredText = ""

    init(notification: MFAPushNotification) {
        _viewModel = StateObject(wrappedValue: NotificationViewModel(notification: notification))
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            colors: [.themeButtonBackground, Color(red: 0.6, green: 0.1, blue: 0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text("PingOne MFA Authentication")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Approve or deny this request")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            // Message content
            VStack(alignment: .leading, spacing: 6) {
                if let title = viewModel.notification.title {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let message = viewModel.notification.message {
                    Text(message)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // Number-matching UI
            if viewModel.notification.pushType == .challenge {
                if !viewModel.notification.getNumbersChallenge.isEmpty {
                    selectNumberSection
                } else {
                    enterManuallySection
                }
            }

            // Actions
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                actionButtons
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding()
        .onAppear {
            if viewModel.notification.isCancelAuthentication { dismiss() }
            if viewModel.notification.pushType == .dry { dismiss() }
        }
        .alert(viewModel.isDenied ? "Denied" : "Approved", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text(viewModel.isDenied ? "Authentication denied." : "Authentication approved.")
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

    private var selectNumberSection: some View {
        VStack(spacing: 12) {
            Text("Select the number shown on your other device")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                ForEach(viewModel.notification.getNumbersChallenge, id: \.self) { number in
                    Button { viewModel.approve(numberChallenge: number) } label: {
                        Text("\(number)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.themeButtonBackground)
                            .frame(width: 72, height: 72)
                            .overlay(Circle().stroke(Color.themeButtonBackground, lineWidth: 2))
                    }
                }
            }
        }
    }

    private var enterManuallySection: some View {
        VStack(spacing: 10) {
            Text("Enter the number shown on your other device")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            TextField("Number", text: $enteredText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 20, design: .monospaced))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 160)
            if !viewModel.isLoading {
                Button {
                    if let n = Int(enteredText) { viewModel.approve(numberChallenge: n) }
                } label: {
                    Label("Confirm Number", systemImage: "checkmark.circle.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(enteredText.isEmpty || Int(enteredText) == nil ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(enteredText.isEmpty || Int(enteredText) == nil)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button { viewModel.deny() } label: {
                Label("Deny", systemImage: "xmark.circle.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            if viewModel.notification.pushType == .default {
                Button { viewModel.approve() } label: {
                    Label("Approve", systemImage: "checkmark.circle.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}
