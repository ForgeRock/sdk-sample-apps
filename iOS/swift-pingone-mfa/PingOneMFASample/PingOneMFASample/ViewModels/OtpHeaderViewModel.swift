// ViewModels/OtpHeaderViewModel.swift
import Foundation
import SwiftUI
import PingOneMFA

@MainActor
class OtpHeaderViewModel: ObservableObject {
    @Published var otpInfo: OtpCodeInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var countdown: Int = 0

    private var refreshTask: Task<Void, Never>?
    private var countdownTimer: Timer?

    func startRefreshing() async {
        await fetchOtp()
    }

    func stopRefreshing() {
        refreshTask?.cancel()
        refreshTask = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    // MARK: - Private

    private func fetchOtp() async {
        refreshTask?.cancel()
        refreshTask = nil
        countdownTimer?.invalidate()
        countdownTimer = nil

        isLoading = true
        errorMessage = nil

        do {
            let info = try await PingOneMFA.getOneTimePasscode()
            otpInfo = info
            countdown = max(1, info.secondsRemaining)
            isLoading = false

            startCountdownTimer()

            let sleepNanoseconds = UInt64(countdown) * 1_000_000_000
            refreshTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: sleepNanoseconds)
                guard let self, !Task.isCancelled else { return }
                await self.fetchOtp()
            }
        } catch {
            errorMessage = "Failed to fetch OTP: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func startCountdownTimer() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.countdown > 0 {
                    self.countdown -= 1
                }
            }
        }
    }
}
