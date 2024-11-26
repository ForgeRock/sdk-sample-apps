//
//  InputView.swift
//  Davinci
//
//  Copyright (c) 2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingDavinci

struct InputView: View {
  @State var text: String = ""
  let placeholderString: String
  var secureField: Bool = false
  let field: any Collector
  
  var body: some View {
    VStack(alignment: .leading) {
      if secureField {
        SecureField(placeholderString, text: $text)
          .padding()
          .background(Color.themeTextField)
          .textContentType(.oneTimeCode)
          .disableAutocorrection(true)
          .autocapitalization(.none)
          .cornerRadius(20.0)
          .shadow(radius: 10.0, x: 20, y: 10)
          .onChange(of: text) { newValue in
            if let field = field as? PasswordCollector {
              field.value = newValue
            }
          }
      } else {
        TextField(placeholderString, text: $text)
          .padding()
          .background(Color.themeTextField)
          .disableAutocorrection(true)
          .textContentType(.oneTimeCode)
          .autocapitalization(.none)
          .cornerRadius(20.0)
          .shadow(radius: 10.0, x: 20, y: 10)
          .onChange(of: text) { newValue in
            if let field = field as? TextCollector {
              field.value = newValue
            }
          }
      }
    }.padding([.leading, .trailing], 27.5)
  }
}

struct InputButton: View {
  let title: String
  let field: any Collector
  let action: () -> (Void)
  
  var body: some View {
    Button(action:  {
      if let field = field as? SubmitCollector {
        field.value = field.key
      }
      action()
    } ) {
      Text(title)
        .font(.headline)
        .foregroundColor(.white)
        .padding()
        .frame(width: 300, height: 50)
        .background(Color(red: 163.0/255.0, green: 19.0/255.0, blue: 0.0/255.0)) // Red color
        .cornerRadius(15.0)
        .shadow(radius: 10.0, x: 20, y: 10)
    }
  }
}

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
        .background(Color.green)
        .cornerRadius(15.0)
        .shadow(radius: 10.0, x: 20, y: 10)
    }
  }
}

extension Color {
  static var themeTextField: Color {
    return Color(red: 220.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, opacity: 1.0)
  }
}
