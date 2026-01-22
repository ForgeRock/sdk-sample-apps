//
//  PushCredentialView.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import Combine
import PingPush

/// View displaying push credential information.
struct PushCredentialView: View {
    let credential: PushCredential
    let lastNotificationDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Last login attempt:")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let date = lastNotificationDate {
                Text(formatDate(date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("No login attempts yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 20) {
        PushCredentialView(
            credential: PushCredential(
                issuer: "Example",
                accountName: "user@example.com",
                serverEndpoint: "https://am.example.com/push",
                sharedSecret: "secret123"
            ),
            lastNotificationDate: Date()
        )
        PushCredentialView(
            credential: PushCredential(
                issuer: "Example",
                accountName: "user@example.com",
                serverEndpoint: "https://am.example.com/push",
                sharedSecret: "secret123"
            ),
            lastNotificationDate: nil
        )
    }
}
