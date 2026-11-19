//
//  AuthorizationDetailsCard.swift
//  OidcExample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingOidc
import SwiftUI

/// A card that lists the RFC 9396 `authorization_details` objects the server granted for a token.
/// - Renders one block per object: the standard members first, then the type-specific members
///   sorted by name, with nested JSON values pretty-printed.
struct AuthorizationDetailsCard: View {
    /// The granted authorization details, shown in the order the server returned them.
    let details: [AuthorizationDetail]

    var body: some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
            HStack(spacing: PingTheme.Spacing.medium) {
                PingIconTile(systemName: "checkmark.shield.fill", diameter: 40, iconSize: 20)

                Text("Granted Authorization Details")
                    .pingSectionHeader()

                Spacer()
            }

            Divider()

            ForEach(Array(details.enumerated()), id: \.offset) { index, detail in
                VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
                    if index > 0 {
                        Divider()
                    }
                    detailBlock(detail)
                }
            }
        }
        .pingCardStyle()
    }

    // MARK: - Detail Block

    private func detailBlock(_ detail: AuthorizationDetail) -> some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
            detailRow("Type", detail.type)
            listRow("Locations", detail.locations)
            listRow("Actions", detail.actions)
            listRow("Datatypes", detail.datatypes)
            listRow("Privileges", detail.privileges)

            ForEach(detail.additionalFields.keys.sorted(), id: \.self) { key in
                if let value = detail.additionalFields[key] {
                    detailRow(key, displayValue(value))
                }
            }
        }
        .textSelection(.enabled)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        PingInfoRow(
            label: label,
            value: value,
            layout: .vertical,
            valueStyle: .monospaced
        )
    }

    /// A row for an optional list of strings; omitted when the list is absent or empty.
    @ViewBuilder
    private func listRow(_ label: String, _ values: [String]?) -> some View {
        if let values, !values.isEmpty {
            detailRow(label, values.joined(separator: ", "))
        }
    }

    /// The text shown for a type-specific member: strings as-is, and every other value
    /// (including nested objects and arrays) as sorted, pretty-printed JSON. Slashes are left
    /// unescaped so URLs inside nested values stay readable.
    private func displayValue(_ value: AuthorizationDetailValue) -> String {
        if case .string(let text) = value {
            return text
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(value) else {
            return String(describing: value)
        }
        return String(decoding: data, as: UTF8.self)
    }
}

#Preview {
    ScrollView {
        AuthorizationDetailsCard(details: [
            AuthorizationDetail(
                type: "payment_initiation",
                locations: ["https://example.com/payments"],
                actions: ["initiate", "status"],
                additionalFields: [
                    "instructedAmount": .object([
                        "currency": .string("EUR"),
                        "amount": .string("123.50")
                    ]),
                    "creditorName": .string("Merchant123"),
                    "creditorAccount": .object([
                        "iban": .string("DE02100100109307118603")
                    ])
                ]
            ),
            AuthorizationDetail(
                type: "account_information",
                actions: ["list_accounts", "read_balances"]
            )
        ])
        .padding(.horizontal, PingTheme.Spacing.screen)
        .padding(.top, PingTheme.Spacing.medium)
    }
    .pingScreenBackground()
}
