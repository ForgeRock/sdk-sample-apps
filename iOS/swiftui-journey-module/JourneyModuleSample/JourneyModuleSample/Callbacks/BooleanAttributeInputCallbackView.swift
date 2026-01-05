//
//  BooleanAttributeInputCallbackView.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney

struct BooleanAttributeInputCallbackView: View {
    let callback: BooleanAttributeInputCallback
    let onNodeUpdated: () -> Void

    @State var value: Bool = false

    var body: some View {
        HStack {
            Text(callback.prompt)
                .foregroundColor(.primary)

            Spacer()

            Toggle("", isOn: $value)
                .toggleStyle(SwitchToggleStyle())
                .onChange(of: value) { newValue in
                    callback.value = newValue
                }
        }
        .padding()
        .onAppear {
            value = callback.value
        }
    }
}
