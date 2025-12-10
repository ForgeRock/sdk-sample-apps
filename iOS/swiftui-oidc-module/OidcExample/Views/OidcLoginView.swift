//
//  OidcLoginView.swift
//  OidcExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import SwiftUI
import PingOrchestrate

/// View that handles OIDC login flow and displays authentication state.
struct OidcLoginView: View {
    /// The view model that manages the OIDC login flow logic.
    @StateObject private var oidcLoginViewModel = OidcLoginViewModel()
    /// A binding to the navigation stack path.
    @Binding var path: [String]

    var body: some View {
        VStack(spacing: 20) {
            if oidcLoginViewModel.isLoading {
                ProgressView("Authenticating...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                // Handle different authentication states
                if let state = oidcLoginViewModel.state {
                    switch state {
                    case .success(let _):
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)

                            Text("Authentication Successful!")
                                .font(.headline)

                            Text("User authenticated")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            // Navigate to token view
                            Button(action: {
                                path.append("Token")
                            }) {
                                Text("View Access Token")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                        .padding()

                    case .failure(let error):
                        VStack(spacing: 16) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.red)

                            Text("Authentication Failed")
                                .font(.headline)

                            Text(error.localizedDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Button(action: {
                                Task {
                                    await oidcLoginViewModel.startOidcLogin()
                                }
                            }) {
                                Text("Try Again")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                    }
                } else {
                    // Initial state - show login button
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("OIDC Authentication")
                            .font(.headline)

                        Text("Tap the button below to start the authentication flow")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: {
                            Task {
                                await oidcLoginViewModel.startOidcLogin()
                            }
                        }) {
                            Text("Start OIDC Login")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("OIDC Login")
    }
}
