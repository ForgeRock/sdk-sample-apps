// 
//  NameCallbackView.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney

struct NameCallbackView: View {
    let callback: NameCallback
    let onNodeUpdated: () -> Void

    @State var text: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(
                callback.prompt,
                text: $text
            )
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .onAppear(perform: {
                text = callback.name
            })
            .onChange(of: text) { newValue in
                callback.name = newValue // update internal state only
            }
            .onSubmit {
                onNodeUpdated() // commit to node state only when done
            }
            .padding()
        }
    }
}
