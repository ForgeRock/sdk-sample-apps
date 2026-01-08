//
//  KeylessView.swift
//  JourneyModuleSample
//
//  Created by george bafaloukas on 08/01/2026.
//

import PingJourney
import SwiftUI

struct KeylessView: View {
//    let viewModel = KeylessViewModel()
    let callback: HiddenValueCallback
    let onNext: () -> Void

    var body: some View {
        VStack {
            Text("Device Signing")
                .font(.title)
            Text("Please wait while we sign the challenge.")
                .font(.body)
                .padding()
            ProgressView()
        }
        .onAppear(perform: handleKeyless)
    }
    
    func handleKeyless() {
        
    }
}
