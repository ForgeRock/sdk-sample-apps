//
//  AccountAvatar.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

/// Avatar component displaying an account logo from a URL, or a colored background with initials as fallback.
struct AccountAvatar: View {
    let issuer: String
    let accountName: String
    let imageURL: String?
    var size: CGFloat = 40

    private var backgroundColor: Color {
        let hash = abs(stableHashCode(issuer) + stableHashCode(accountName)) % 360
        return Color(hue: Double(hash) / 360.0, saturation: 0.6, brightness: 0.55)
    }

    /// Computes a deterministic hash code for a string using.
    /// Swift's built-in `hashValue` is randomized per-launch and cannot be used for it.
    private func stableHashCode(_ s: String) -> Int {
        s.unicodeScalars.reduce(0) { result, scalar in
            result &* 31 &+ Int(scalar.value)
        }
    }

    private var initials: String {
        let words = issuer.split(separator: " ").filter { !$0.isEmpty }
        return words.prefix(2)
            .compactMap { $0.first.map { String($0).uppercased() } }
            .joined()
    }

    var body: some View {
        Group {
            if let urlString = imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        initialsView
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    @unknown default:
                        initialsView
                    }
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
    }

    private var initialsView: some View {
        backgroundColor
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.white)
            )
    }
}

#Preview {
    VStack(spacing: 16) {
        AccountAvatar(issuer: "Google", accountName: "user@example.com", imageURL: nil, size: 48)
        AccountAvatar(issuer: "Ping Identity", accountName: "user@example.com", imageURL: nil, size: 48)
        AccountAvatar(issuer: "GitHub", accountName: "dev@example.com", imageURL: nil, size: 48)
        AccountAvatar(issuer: "A", accountName: "", imageURL: nil, size: 48)
    }
    .padding()
}
