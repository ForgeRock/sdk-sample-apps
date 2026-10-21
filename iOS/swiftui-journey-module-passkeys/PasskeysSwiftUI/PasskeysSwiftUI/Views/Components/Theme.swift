//
//  Theme.swift
//  PasskeysSwiftUI
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

extension Color {
    static let pingRed = Color(red: 163.0 / 255.0, green: 19.0 / 255.0, blue: 0.0 / 255.0)
    static let pingRedDark = Color(red: 0.6, green: 0.1, blue: 0.1)
    static let pingTextField = Color(red: 220.0 / 255.0, green: 230.0 / 255.0, blue: 230.0 / 255.0)
}

// MARK: - Primary Action Button

struct PingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.pingRed.opacity(configuration.isPressed ? 0.8 : 1))
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Branded Header

struct PingHeaderView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.pingRed, .pingRedDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)

                Text("Passkeys Demo")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text("Secure biometric authentication")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.vertical, 32)
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Branded Text Field

struct PingTextField: View {
    let placeholder: String
    @Binding var text: String
    var contentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .never

    var body: some View {
        TextField(placeholder, text: $text)
            .textContentType(contentType)
            .autocorrectionDisabled()
            .textInputAutocapitalization(autocapitalization)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.pingTextField, lineWidth: 1.5)
            )
    }
}

// MARK: - Branded Secure Field

struct PingSecureField: View {
    let placeholder: String
    @Binding var text: String
    @State private var isSecure = true

    var body: some View {
        HStack {
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textContentType(.password)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundColor(.pingRed)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.pingTextField, lineWidth: 1.5)
        )
    }
}

// MARK: - FIDO Icon View

struct FidoIconView: View {
    let systemName: String
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.12))
                .frame(width: 88, height: 88)

            Image(systemName: systemName)
                .font(.system(size: 40))
                .foregroundColor(tint)
        }
    }
}

// MARK: - Error Message View

struct ErrorMessageView: View {
    let message: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.leading)
        }
        .foregroundColor(.red)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let message: String

    init(_ message: String = "Loading…") {
        self.message = message
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.4)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
