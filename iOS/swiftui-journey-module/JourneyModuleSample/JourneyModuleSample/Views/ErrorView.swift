//
//  ErrorView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingOrchestrate
import Combine

/// A reusable error card view with a title and message in the semantic error color.
struct ErrorView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
            Text(title)
                .font(PingTheme.Typography.body.weight(.semibold))
                .foregroundStyle(PingTheme.Color.statusError)
            Text(message)
                .font(PingTheme.Typography.supporting)
                .foregroundStyle(PingTheme.Color.statusError)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pingStatusCardStyle(tint: PingTheme.Color.statusError)
        .padding(.horizontal, PingTheme.Spacing.screen)
    }
}

/// Renders an orchestration `ErrorNode` as the shared error card, with the
/// node's message exposed in an alert on tap.
struct ErrorNodeView: View {
    let node: ErrorNode

    var body: some View {
        ErrorView(title: "Error", message: node.message)
            .onTapGesture {
                errorMessage = node.message
            }
            .pingErrorAlert(errorMessage: $errorMessage)
    }

    /// Non-nil surfaces the shared error alert with the node's message.
    @State private var errorMessage: String? = nil
}

/// Validation messages rendered in the semantic error color; empty entries
/// are dropped. Replaces the legacy per-view `ErrorMessageView`.
struct ErrorMessageView: View {
    var errors: [String]

    var body: some View {
        PingFieldMessages(errorMessages: errors)
    }
}
