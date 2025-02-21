// 
//  LabelView.swift
//  Davinci
//
//  Copyright (c) 2025 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

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
