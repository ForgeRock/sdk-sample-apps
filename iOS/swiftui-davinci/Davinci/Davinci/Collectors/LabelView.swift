// 
//  LabelView.swift
//  Davinci
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

/// A SwiftUI view that displays static text content.
///
/// The LabelView renders text content centered in its container. It's typically used
/// for displaying instructions, information, or other static text elements in a form.
///
/// Properties:
/// - field: The LabelCollector that contains the text content to display
///
/// The view presents the text from the field's content property with subheadline styling.
struct LabelView: View {
    var field: LabelCollector
    
    var body: some View {
        HStack {
            Text(field.content)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
