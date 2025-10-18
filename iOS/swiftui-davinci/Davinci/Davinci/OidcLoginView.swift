//
//  OidcLoginView.swift
//  Davinci
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import SwiftUI
import PingOidc

/// The main view for OIDC login authentication.
struct OidcLoginView: View {
    /// The view model that manages the OIDC login flow logic.
    @StateObject private var oidcLoginViewModel = OidcLoginViewModel()
    /// A binding to the navigation stack path.
    @Binding var path: [String]
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    Spacer()
                    // Handle different types of authentication states.
                    switch oidcLoginViewModel.state {
                    case .success( _ ):
                        VStack{}.onAppear {
                            path.removeLast()
                            path.append("Token")
                        }
                    case .failure(let error):
                        ErrorView(message: error.localizedDescription)
                    case .none:
                        VStack(spacing: 20) {
                            /// App logo displayed at the top of the view
                            Image("Logo").resizable().scaledToFill().frame(width: 100, height: 100)
                            
                            Text("OIDC Login")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Authenticate using OIDC Web flow")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Start OIDC Login") {
                                Task {
                                    await oidcLoginViewModel.startOidcLogin()
                                }
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding()
                    }
                }
            }
            
            Spacer()
            
            // Show an activity indicator when loading.
            if oidcLoginViewModel.isLoading {
                /// Semi-transparent overlay to indicate loading state
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                /// Circular progress indicator that provides visual feedback during loading operations
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(2)
                    .tint(.blue)
            }
        }
        .navigationTitle("OIDC Login")
    }
}
