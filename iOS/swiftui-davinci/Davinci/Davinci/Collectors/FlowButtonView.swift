// 
//  FlowButtonView.swift
//  PingExample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

struct FlowButtonView: View {
    var field: FlowCollector
    let onNext: (Bool) -> Void
    
    var body: some View {
        HStack {
            if field.type == "FLOW_LINK" {
                Button(action: {
                    field.value = "action"
                    onNext(false)
                }) {
                    Text(field.label)
                        .foregroundStyle(PingTheme.Color.actionPrimary)
                        .underline()
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Button(action: {
                    field.value = "action"
                    onNext(false)
                }) {
                    Text(field.label)
                        .foregroundStyle(PingTheme.Color.actionPrimary)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.vertical, PingTheme.Spacing.xSmall)
        .frame(maxWidth: .infinity)
        .onAppear {
            field.value = ""
        }
    }
}
