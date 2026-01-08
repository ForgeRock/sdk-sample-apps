//
//  KeylessView.swift
//  JourneyModuleSample
//
//  Created by george bafaloukas on 08/01/2026.
//

import PingJourney
import SwiftUI

struct KeylessView: View {
    let viewModel = KeylessViewModel()
    let callback: HiddenValueCallback
    let onNodeUpdated: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(callback.valueId)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            .onSubmit {
                onNodeUpdated() // commit to node state only when done
            }
            .padding()
        }
    }
}
