//
//  ValidatedPasswordCallbackView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney
import Combine

struct ValidatedPasswordCallbackView: View {
    let callback: ValidatedPasswordCallback
    let onNodeUpdated: () -> Void

    @State var text: String = ""
    @State private var passwordVisibility: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Password Input Field
            VStack(alignment: .leading) {
                SecureFieldView(
                    label: callback.prompt,
                    value: $text,
                    isPasswordVisible: $passwordVisibility,
                    onValueChange: { value in
                        callback.password = value
                    },
                    onAppear: {
                        text = callback.password
                    },
                    isError: !callback.failedPolicies.isEmpty,
                    errorMessages: callback.failedPolicies.isEmpty ? [] : callback.failedPolicies.map({ $0.failedDescription(for: callback.prompt)})
                )
                .onSubmit {
                    onNodeUpdated()
                }
            }
        }
        .padding()
    }
}
