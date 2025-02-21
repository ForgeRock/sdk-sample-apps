// 
//  ErrorMessageView.swift
//  Davinci
//
//  Copyright (c) 2025 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

struct ErrorMessageView: View {
    var errors: [String]
    
    var body: some View {
        if errors.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(errors, id: \.self) { error in
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.vertical, 4)
                }
            }
            .padding(2)
        }
    }
}
