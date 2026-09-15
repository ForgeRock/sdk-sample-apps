//
//  LabelView.swift
//  PingExample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

struct LabelView: View {
    var field: LabelCollector

    var body: some View {
        HStack {
            labelContent
                .pingSectionHeader()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Label Content

    @ViewBuilder
    private var labelContent: some View {
        if let richContent = field.richContent {
            Text(RichTextBuilder.build(from: richContent))
        } else {
            Text(field.content)
        }
    }
}
