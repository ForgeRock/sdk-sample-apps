//
//  IdpCallbackView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import SwiftUI
import PingExternalIdP
import Combine

struct IdpCallbackView: View {
    @StateObject var viewModel: IdpCallbackViewModel
    
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            switch viewModel.authState {
            case .authenticating:
                Image(systemName: "person.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Text(viewModel.callback.provider)
                    .font(.body)
                    .foregroundColor(.secondary)
                    NextButton(title: "Continue") {
                        Task { @MainActor in
                            if viewModel.hasStartedAuthorization == false {
                                // Call the performAuthorization method to start the process.
                                await viewModel.performAuthorization()
                            }
                        }
                    }
            case .failure(let error):
                Image(systemName: "xmark.octagon.fill")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                Text("Authorization failed: \(error.localizedDescription)")
                    .font(.body)
                    .multilineTextAlignment(.center)
                NextButton(title: "Continue") {
                    Task {
                        self.onNext()
                    }
                }
                .buttonStyle(.bordered)
                
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                Text("Authorization Successful")
                    .font(.body)
                    .multilineTextAlignment(.center)
                NextButton(title: "Continue") {
                    Task {
                        self.onNext()
                    }
                }
            }
        }
        .padding()
    }
}

@MainActor
class IdpCallbackViewModel: ObservableObject {
    
    @Published var authState: AuthState = .authenticating
    
    // 1. Add a flag to track if the task has been started.
    var hasStartedAuthorization = false
    
    let callback: IdpCallback

    enum AuthState {
        case authenticating
        case completed
        case failure(Error)
    }
    
    init(callback: IdpCallback) {
        self.callback = callback
    }
    
    func performAuthorization() async {
        Task { @MainActor in
            // 2. Check the flag. If the task has already run, do nothing.
            guard !hasStartedAuthorization else { return }
            hasStartedAuthorization = true
            
            let result = await callback.authorize()
            
            switch result {
            case .success:
                self.authState = .completed
            case .failure(let error):
                self.authState = .failure(error)
            }
        }
    }
}
