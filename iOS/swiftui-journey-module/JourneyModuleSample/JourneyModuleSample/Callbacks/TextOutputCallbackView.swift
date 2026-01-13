//
//  TextOutputCallbackView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney

/**
 * A SwiftUI view for displaying informational, warning, or error messages during authentication flows.
 *
 * This view presents read-only text messages with contextual icons based on message type
 * (information, warning, error, or default). It is used to provide feedback or instructions
 * to the user without requiring any input. The message is displayed with an appropriate
 * icon and color scheme to indicate severity or importance.
 *
 * **User Action Required:** NO - This is a display-only component for informational purposes.
 *
 * The UI displays an icon (info, warning, or error) alongside the message text. Colors are
 * automatically applied based on message type: blue for information, orange for warnings,
 * red for errors, and gray for default messages.
 */
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
