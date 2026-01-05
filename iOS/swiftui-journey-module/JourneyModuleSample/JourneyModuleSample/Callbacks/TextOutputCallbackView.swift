//
//  TextOutputCallbackView.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney

struct TextOutputCallbackView: View {
    let callback: TextOutputCallback

    var body: some View {
        HStack(spacing: 8) {
            // Icon based on message type
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.title2)

            // Message text
            Text(callback.message)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }

    private var iconName: String {
        switch callback.messageType {
        case .information:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        default:
            return "gear.circle.fill"
        }
    }

    private var iconColor: Color {
        switch callback.messageType {
        case .information:
            return .blue
        case .warning:
            return .orange
        case .error:
            return .red
        default:
            return .gray
        }
    }
}
