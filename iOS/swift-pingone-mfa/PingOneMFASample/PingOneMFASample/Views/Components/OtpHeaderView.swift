// Views/Components/OtpHeaderView.swift
import SwiftUI
import PingOneMFA

struct OtpHeaderView: View {
    @StateObject private var viewModel = OtpHeaderViewModel()

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "number.square.fill")
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

                VStack(alignment: .leading, spacing: 3) {
                    Text("One-Time Passcode")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    if viewModel.isLoading && viewModel.otpInfo == nil {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if let info = viewModel.otpInfo {
                        Text(info.code)
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                            .tracking(4)
                        Text("Refreshes in \(viewModel.countdown)s")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .task { await viewModel.startRefreshing() }
        .onDisappear { viewModel.stopRefreshing() }
    }
}
