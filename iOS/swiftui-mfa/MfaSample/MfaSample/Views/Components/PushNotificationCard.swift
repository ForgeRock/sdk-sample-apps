//
//  PushNotificationCard.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingPush

/// Card component displaying a push notification item.
struct PushNotificationCard: View {
    let item: PushNotificationItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Issuer and Status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if let issuer = item.credential?.issuer, !issuer.isEmpty {
                            Text(issuer)
                                .font(.headline)
                                .foregroundColor(.primary)
                        } else {
                            Text("Unknown Service")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }

                        if let accountName = item.credential?.accountName, !accountName.isEmpty {
                            Text(accountName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    statusBadge
                }

                // Message
                if let message = item.notification.messageText, !message.isEmpty {
                    Text(message)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }

                // Metadata
                HStack(spacing: 12) {
                    // Notification Type
                    HStack(spacing: 4) {
                        Image(systemName: iconForPushType(item.notification.pushType))
                            .font(.caption)
                        Text(item.notification.pushType.rawValue.capitalized)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)

                    // Time
                    if let timeAgo = timeAgoString(from: item.notification.createdAt) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(timeAgo)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Status Badge
    private var statusBadge: some View {
        let (text, color) = statusInfo
        return Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(6)
    }

    private var statusInfo: (String, Color) {
        switch item.status {
        case .pending:
            return ("Pending", .orange)
        case .approved:
            return ("Approved", .green)
        case .denied:
            return ("Denied", .red)
        case .expired:
            return ("Expired", .gray)
        }
    }

    // MARK: - Helper Methods
    private func iconForPushType(_ type: PushType) -> String {
        switch type {
        case .default:
            return "checkmark.circle"
        case .biometric:
            return "faceid"
        case .challenge:
            return "number.circle"
        @unknown default:
            return "bell"
        }
    }

    private func timeAgoString(from date: Date) -> String? {
        let now = Date()
        let difference = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let days = difference.day, days > 0 {
            return "\(days)d ago"
        } else if let hours = difference.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = difference.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PushNotificationCard(
            item: PushNotificationItem(
                notification: PushNotification(
                    id: "1",
                    credentialId: "cred-123",
                    ttl: 300,
                    messageId: "msg-123",
                    messageText: "Login attempt from new device",
                    pushType: .default,
                    createdAt: Date().addingTimeInterval(-300)
                ),
                credential: nil,
                status: .pending
            ),
            onTap: {}
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
