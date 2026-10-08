//
//  MetadataView.swift
//  Davinci
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingDavinci

/// Demo view for the DaVinci SDK Integrator connector's METADATA step.
/// Displays the opaque payload the flow sent and offers two buttons to
/// simulate a success or error result without invoking a real third-party
/// SDK.
struct MetadataView: View {
    let field: MetadataCollector
    let onNext: (Bool) -> Void

    private var prettyMetadata: String {
        guard
            let data = try? JSONSerialization.data(
                withJSONObject: field.metadata,
                options: [.prettyPrinted, .sortedKeys]
            ),
            let string = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return string
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SDK Metadata")
                .font(.headline)

            Text("Payload from DaVinci:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView {
                Text(prettyMetadata)
                    .font(.caption.monospaced())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color(.systemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxHeight: 240)

            HStack(spacing: 12) {
                Button {
                    field.setResult(["verified": true, "score": 92])
                    onNext(true)
                } label: {
                    Text("Simulate success")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.themeButtonBackground)

                Button {
                    field.setError(code: "USER_CANCELLED", message: "User cancelled the operation")
                    onNext(true)
                } label: {
                    Text("Simulate error")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding(.vertical, 8)
    }
}
