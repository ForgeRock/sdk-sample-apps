//
//  AccountGroupCard.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingOath
import PingPush

/// Card component displaying account group information and OTP codes.
struct AccountGroupCard: View {
    let accountGroup: AccountGroup
    let codeInfo: OathCodeInfo?
    let lastNotificationDate: Date?
    let copyOtp: Bool
    let tapToReveal: Bool
    let onGenerateCode: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Avatar + Issuer / Account Name
                HStack(alignment: .center, spacing: 12) {
                    AccountAvatar(
                        issuer: accountGroup.displayIssuer.isEmpty ? accountGroup.issuer : accountGroup.displayIssuer,
                        accountName: accountGroup.displayAccountName.isEmpty ? accountGroup.accountName : accountGroup.displayAccountName,
                        imageURL: accountGroup.imageURL,
                        size: 48
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(accountGroup.displayIssuer.isEmpty ? accountGroup.issuer : accountGroup.displayIssuer)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(accountGroup.displayAccountName.isEmpty ? accountGroup.accountName : accountGroup.displayAccountName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // Account type badges
                HStack(spacing: 8) {
                    if !accountGroup.oathCredentials.isEmpty {
                        accountTypeBadge(
                            icon: "key.fill",
                            text: "OATH",
                            color: .blue
                        )
                    }

                    if !accountGroup.pushCredentials.isEmpty {
                        accountTypeBadge(
                            icon: "bell.fill",
                            text: "Push",
                            color: .blue
                        )
                    }

                    if accountGroup.isLocked {
                        accountTypeBadge(
                            icon: "lock.fill",
                            text: "Locked",
                            color: .red
                        )
                    }
                }

                // OATH Code (if available)
                if let oathCredential = accountGroup.oathCredentials.first {
                    Divider()

                    OathCredentialView(
                        credential: oathCredential,
                        codeInfo: codeInfo,
                        onGenerateCode: onGenerateCode,
                        copyOtp: copyOtp,
                        tapToReveal: tapToReveal
                    )
                }

                // Push Credentials (if available and no OATH credentials)
                if let pushCredential = accountGroup.pushCredentials.first, accountGroup.oathCredentials.isEmpty {
                    Divider()

                    PushCredentialView(
                        credential: pushCredential,
                        lastNotificationDate: lastNotificationDate
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    /// Creates a small badge showing account type or status.
    private func accountTypeBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(6)
    }
}



#Preview {
    VStack(spacing: 16) {
        AccountGroupCard(
            accountGroup: AccountGroup(
                issuer: "Google",
                accountName: "user@example.com",
                displayIssuer: "Google",
                displayAccountName: "user@example.com",
                oathCredentials: [
                    OathCredential(
                        issuer: "Google",
                        accountName: "user@example.com",
                        oathType: .totp,
                        secretKey: "JBSWY3DPEHPK3PXP"
                    )
                ],
                pushCredentials: []
            ),
            codeInfo: nil,
            lastNotificationDate: nil,
            copyOtp: false,
            tapToReveal: false,
            onGenerateCode: {},
            onTap: {}
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
