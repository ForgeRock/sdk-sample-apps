// 
//  SubmitButtonView.swift
//  PingExample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

struct SubmitButtonView: View {
    var field: SubmitCollector
    let onNext: (Bool) -> Void
    
    var body: some View {
        Button(field.label) {
            field.value = "submit"
            onNext(true)
        }
        .buttonStyle(.pingPrimary)
        .padding(.vertical, PingTheme.Spacing.small)
        .onDisappear {
            field.value = ""
        }
    }
        
}
