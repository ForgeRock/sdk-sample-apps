//
//  CustomViews.swift
//  Davinci
//
//  Copyright (c) 2024 - 2025 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

/// A reusable button view for general "Next" actions.
/// - Executes a provided action when tapped.
struct NextButton: View {
  let title: String
  let action: () -> (Void)
  
  var body: some View {
    Button(action:  {
      action()
    } ) {
      Text(title)
        .font(.headline)
        .foregroundColor(.white)
        .padding()
        .frame(width: 300, height: 50)
        .background(Color.themeButtonBackground)
        .cornerRadius(15.0)
        .shadow(radius: 10.0, x: 20, y: 10)
    }
  }
}

/// A view for displaying the header of a node.
struct HeaderView: View {
  var name: String = ""
  
  var body: some View {
    VStack {
      Text(name)
        .font(.title)
        .foregroundStyle(Color.gray)
    }
  }
}

/// A view for displaying the description of a node.
struct DescriptionView: View {
  var name: String = ""
  
  var body: some View {
    VStack {
      Text(name)
        .font(.subheadline)
        .foregroundStyle(Color.gray)
    }
  }
}

/// A custom color extension for theme consistency.
/// - Provides a reusable color for text fields.
extension Color {
  static var themeTextField: Color {
    return Color(red: 220.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, opacity: 1.0)
  }
  
  static var themeButtonBackground: Color {
    return Color(red: 163.0/255.0, green: 19.0/255.0, blue: 0.0/255.0) // Red color
  }
}
