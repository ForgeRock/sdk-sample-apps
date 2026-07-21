//
//  NameCallbackView.swift
//  PasskeysSwiftUI
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney

struct NameCallbackView: View {
    let callback: NameCallback
    @State private var username = ""

    var body: some View {
        PingTextField(
            placeholder: callback.prompt.isEmpty ? "Username" : callback.prompt,
            text: $username,
            contentType: .username
        )
        .onChange(of: username) { callback.name = username }
    }
}
