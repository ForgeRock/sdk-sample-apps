//
//  LoginView.swift
//  PingExample
//
//  Copyright (c) 2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import SwiftUI

struct ErrorView: View {
    var name: String = ""
    
    var body: some View {
        VStack {
            Text("Oops! Something went wrong.\(name)")
                .foregroundColor(.red).padding(.top, 20)
        }
    }
}

struct HeaderView: View {
    var name: String = ""
    var body: some View {
        VStack {
            Text(name)
                .font(.title)
        }
    }
}

struct LoginView: View {
    // MARK: - Propertiers
    @ObservedObject var oidcViewModel: OIDCViewModel
    @Binding var path: [String]
    
    // MARK: - View
    var body: some View {
        VStack {
            Spacer()
            NextButton(title: "Start OIDC flow") {
                Task {
                    do {
                        let _ = try await oidcViewModel.startOIDC()
                        path.removeLast()
                        path.append("Token")
                    } catch {
                        print(String(describing: error))
                    }
                }
            }
        }
    }
}

