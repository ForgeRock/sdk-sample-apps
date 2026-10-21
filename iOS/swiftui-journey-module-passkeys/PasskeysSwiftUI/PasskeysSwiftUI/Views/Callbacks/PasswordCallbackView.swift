//
//  PasswordCallbackView.swift
//  PasskeysSwiftUI
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney

struct PasswordCallbackView: View {
    let callback: PasswordCallback
    @State private var password = ""

    var body: some View {
        PingSecureField(
            placeholder: callback.prompt.isEmpty ? "Password" : callback.prompt,
            text: $password
        )
        .onChange(of: password) { callback.password = password }
    }
}
