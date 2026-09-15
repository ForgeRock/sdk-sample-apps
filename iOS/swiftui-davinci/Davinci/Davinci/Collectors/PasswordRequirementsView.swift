//
//  PasswordRequirementsView.swift
//  PingExample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

/// A view that displays password policy requirements with live pass/fail indicators.
struct PasswordRequirementsView: View {
    let policy: PasswordPolicy
    let password: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
            Text("Password Requirements")
                .font(PingTheme.Typography.sectionTitle)
                .foregroundStyle(PingTheme.Color.contentSecondary)  // intentionally de-emphasized header
            
            requirementRow(
                label: "Between \(policy.length.min) and \(policy.length.max) characters",
                isMet: password.count >= policy.length.min && password.count <= policy.length.max
            )
            
            if policy.minUniqueCharacters > 0 {
                requirementRow(
                    label: "At least \(policy.minUniqueCharacters) unique characters",
                    isMet: Set(password).count >= policy.minUniqueCharacters
                )
            }
            
            if policy.maxRepeatedCharacters < Int.max {
                let maxRepeated = password.reduce(into: [Character: Int]()) { counts, char in
                    counts[char, default: 0] += 1
                }.values.max() ?? 0
                requirementRow(
                    label: "No more than \(policy.maxRepeatedCharacters) repeated characters",
                    isMet: password.isEmpty || maxRepeated <= policy.maxRepeatedCharacters
                )
            }
            
            ForEach(policy.minCharacters.sorted(by: { $0.key < $1.key }), id: \.key) { chars, minCount in
                let foundCount = password.filter { chars.contains($0) }.count
                requirementRow(
                    label: "\(minCount) \(characterSetLabel(chars))",
                    isMet: foundCount >= minCount
                )
            }
        }
        .padding(.vertical, PingTheme.Spacing.xSmall)
    }
    
    @ViewBuilder
    private func requirementRow(label: String, isMet: Bool) -> some View {
        HStack(alignment: .top, spacing: PingTheme.Spacing.small) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isMet ? PingTheme.Color.statusSuccess : PingTheme.Color.contentSecondary)
                .font(PingTheme.Typography.supporting)
            Text(label)
                .font(PingTheme.Typography.supporting)
                .foregroundStyle(isMet ? PingTheme.Color.contentPrimary : PingTheme.Color.contentSecondary)
        }
    }
    
    private func characterSetLabel(_ chars: String) -> String {
        if chars.allSatisfy({ $0.isLowercase }) {
            return "lowercase letter(s)"
        } else if chars.allSatisfy({ $0.isUppercase }) {
            return "uppercase letter(s)"
        } else if chars.allSatisfy({ $0.isNumber }) {
            return "number(s)"
        } else {
            return "special character(s)"
        }
    }
}
