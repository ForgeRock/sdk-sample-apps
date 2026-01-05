// 
//  StorageView.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI

struct StorageView: View {
    let menuItem: MenuItem
    var storageViewModel = StorageViewModel()
    var body: some View {
        Text("This View is for testing Storage functionality.\nPlease check the Console Logs")
            .font(.title3)
            .multilineTextAlignment(.center)
            .navigationTitle(menuItem.title)
            .onAppear() {
                Task {
                    await storageViewModel.setupMemoryStorage()
                    await storageViewModel.setupKeychainStorage()
                }
            }
    }
}
