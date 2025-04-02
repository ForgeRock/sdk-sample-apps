// 
//  FlowButtonView.swift
//  Davinci
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

/// A SwiftUI view that represents a navigation button within a flow.
///
/// The FlowButtonView creates either a standard button or a link-style button
/// based on the type property of the field. It triggers navigation to the next
/// step in the flow when pressed.
///
/// Properties:
/// - field: The FlowCollector that manages the button state and properties
/// - onNext: A callback function that triggers navigation to the next step when the button is pressed
///
/// The view sets the field's value to "action" when pressed to indicate it was activated.
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
                        .foregroundColor(Color.themeButtonBackground)
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
                        .foregroundColor(Color.themeButtonBackground)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity)
        .onAppear {
            field.value = ""
        }
    }
}
