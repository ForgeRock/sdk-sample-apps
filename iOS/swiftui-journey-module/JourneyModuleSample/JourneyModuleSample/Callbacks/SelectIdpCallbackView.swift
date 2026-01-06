//
//  SelectIdpCallbackView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingExternalIdP
import Combine

struct SelectIdpCallbackView: View {
    let callback: SelectIdpCallback
    let onNext: () -> Void
    
    var body: some View {
        ScrollView {
            
            LazyVStack(alignment: .center, spacing: 12) {
                
                // Add a title for better context
                Text("Select a provider")
                    .font(.headline)
                    .padding(.bottom, 8)
                
                ForEach(callback.providers) { provider in
                    Button(action: {
                        callback.value = provider.provider
                        self.onNext()
                    }) {
                        // Make the button label more descriptive and visually appealing
                        Text(provider.provider.capitalized)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }
}
