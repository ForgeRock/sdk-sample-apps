//
//  ChoiceCallbackView.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney

struct ChoiceCallbackView: View {
    let callback: ChoiceCallback
    let onNodeUpdated: () -> Void

    @State var selectedIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker(callback.prompt, selection: $selectedIndex) {
                ForEach(callback.choices.indices, id: \.self) { index in
                    Text(callback.choices[index]).tag(index)
                }
            }
            .pickerStyle(.menu)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .onChange(of: selectedIndex) { newValue in
                callback.selectedIndex = newValue
            }
        }
        .padding()
        .onAppear {
            selectedIndex = callback.selectedIndex
        }
    }
}
