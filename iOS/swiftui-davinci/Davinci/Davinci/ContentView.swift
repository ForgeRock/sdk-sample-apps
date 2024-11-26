//
//  ContentView.swift
//  Davinci
//
//  Copyright (c) 2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

struct ContentView: View {
  @State private var startDavinici = false
  @State private var path: [String] = []
  
  var body: some View {
    
    NavigationStack(path: $path) {
      List {
        NavigationLink(value: "Davinci") {
          Text("Launch Davinci")
        }
        NavigationLink(value: "Token") {
          Text("Access Token")
        }
        NavigationLink(value: "User") {
          Text("User Info")
        }
        NavigationLink(value: "Logout") {
          Text("Logout")
        }
      }.navigationDestination(for: String.self) { item in
        switch item {
        case "Davinci":
          DavinciView(path: $path)
        case "Token":
          AccessTokenView()
        case "User":
          UserInfoView()
        case "Logout":
          LogOutView(path: $path)
        default:
          EmptyView()
        }
      }.navigationBarTitle("Davinci")
    }
    Spacer()
    Image("Logo").resizable().scaledToFill().frame(width: 100, height: 100)
      .padding(.vertical, 32)
  }
}

struct LogOutView: View {
  @Binding var path: [String]
  @StateObject private var viewmodel =  LogOutViewModel()
  
  var body: some View {
    Text("Logout")
      .font(.title)
      .navigationBarTitle("Logout", displayMode: .inline)
    
    NextButton(title: "Procced to logout") {
      Task {
        await viewmodel.logout()
        path.removeLast()
        path.append("Davinci")
      }
    }
  }
}

struct SecondTabView: View {
  var body: some View {
    Text("LogOut")
      .font(.title)
      .navigationBarTitle("LogOut", displayMode: .inline)
  }
}

struct Register: View {
  var body: some View {
    Text("Register")
      .font(.title)
      .navigationBarTitle("Register", displayMode: .inline)
  }
}

struct ForgotPassword: View {
  var body: some View {
    Text("ForgotPassword")
      .font(.title)
      .navigationBarTitle("ForgotPassword", displayMode: .inline)
  }
}


@main
struct MyApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

struct ActivityIndicatorView: View {
  @Binding var isAnimating: Bool
  let style: UIActivityIndicatorView.Style
  let color: Color
  
  var body: some View {
    if isAnimating {
      VStack {
        Spacer()
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: color))
          .padding()
        Spacer()
      }
      .background(Color.black.opacity(0.4).ignoresSafeArea())
    }
  }
}
