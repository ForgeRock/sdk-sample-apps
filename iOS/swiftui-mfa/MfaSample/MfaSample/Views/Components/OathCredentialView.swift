//
//  OathCodeView.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import UIKit
import PingOath

/// View for displaying OATH codes with formatting and countdown timer.
struct OathCredentialView: View {
    let credential: OathCredential
    let codeInfo: OathCodeInfo?
    let onGenerateCode: () -> Void
    var copyOtp: Bool = false
    var tapToReveal: Bool = false

    @State private var showCopied = false
    @State private var isRevealed: Bool = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let progress = computeProgress(at: timeline.date)
            HStack(spacing: 12) {
                // Code display
                if let code = codeInfo?.code {
                    let shouldHide = tapToReveal && !isRevealed
                    Button(action: {
                        if tapToReveal && !isRevealed {
                            isRevealed = true
                        } else if copyOtp {
                            UIPasteboard.general.string = code
                            showCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showCopied = false
                            }
                        }
                    }) {
                        Text(shouldHide ? "• • • • • •" : (showCopied ? "Copied!" : formattedCode(code)))
                            .font(.system(size: 28, weight: .semibold, design: .monospaced))
                            .foregroundColor(showCopied ? .green : (shouldHide ? .secondary : .primary))
                    }
                    .buttonStyle(.plain)
                    .disabled(!tapToReveal && !copyOtp)
                } else {
                    Text("------")
                        .font(.system(size: 28, weight: .semibold, design: .monospaced))
                        .foregroundColor(.gray)
                }

                Spacer()

                // Timer or refresh button
                if credential.oathType == .totp {
                    CircularProgressTimer(progress: progress)
                } else {
                    Button(action: onGenerateCode) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear {
            isRevealed = !tapToReveal
        }
        .onChange(of: tapToReveal) { newValue in
            // When the setting is toggled, update reveal state immediately
            isRevealed = !newValue
        }
        .onChange(of: codeInfo?.code) { _ in
            // Reset reveal state when a new code is generated
            if tapToReveal {
                isRevealed = false
            }
        }
    }
    
    /// Computes the current progress based on codeInfo and the given date.
    private func computeProgress(at date: Date) -> Double {
        guard let codeInfo = codeInfo, codeInfo.totalPeriod > 0 else { return 0 }
        let elapsedInPeriod = Int(date.timeIntervalSince1970) % codeInfo.totalPeriod
        let currentTimeRemaining = codeInfo.totalPeriod - elapsedInPeriod
        return Double(currentTimeRemaining) / Double(codeInfo.totalPeriod)
    }

    /// Formats the code with space in the middle for better readability.
    private func formattedCode(_ code: String) -> String {
        guard code.count > 3 else { return code }

        let midpoint = code.count / 2
        let index = code.index(code.startIndex, offsetBy: midpoint)
        let firstHalf = String(code[..<index])
        let secondHalf = String(code[index...])

        return "\(firstHalf) \(secondHalf)"
    }
}

#Preview {
    VStack(spacing: 20) {
        OathCredentialView(
            credential: OathCredential(
                issuer: "Example",
                accountName: "user@example.com",
                oathType: .totp,
                secretKey: "JBSWY3DPEHPK3PXP"
            ),
            codeInfo: OathCodeInfo.forTotp(
                code: "123456",
                timeRemaining: 15,
                totalPeriod: 30
            ),
            onGenerateCode: {}
        )
        .padding()

        OathCredentialView(
            credential: OathCredential(
                issuer: "Example",
                accountName: "user@example.com",
                oathType: .hotp,
                secretKey: "JBSWY3DPEHPK3PXP"
            ),
            codeInfo: OathCodeInfo.forHotp(
                code: "654321",
                counter: 5
            ),
            onGenerateCode: {}
        )
        .padding()
    }
}
