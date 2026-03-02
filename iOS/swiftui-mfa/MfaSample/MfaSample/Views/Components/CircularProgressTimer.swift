//
//  CircularProgressTimer.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

/// A circular progress indicator for TOTP countdown timers.
struct CircularProgressTimer: View {
    let progress: Double  // 0.0 to 1.0
    let lineWidth: CGFloat
    let size: CGFloat

    init(progress: Double, lineWidth: CGFloat = 3, size: CGFloat = 40) {
        self.progress = max(0, min(1, progress))  // Clamp between 0 and 1
        self.lineWidth = lineWidth
        self.size = size
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    Color.gray.opacity(0.2),
                    lineWidth: lineWidth
                )

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))  // Start from top
        }
        .frame(width: size, height: size)
    }

    /// Returns the color based on the remaining time.
    private var progressColor: Color {
        switch progress {
        case 0.5...1.0:
            return .green
        case 0.2..<0.5:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CircularProgressTimer(progress: 1.0)
        CircularProgressTimer(progress: 0.5)
        CircularProgressTimer(progress: 0.2)
        CircularProgressTimer(progress: 0.0)
    }
    .padding()
}
