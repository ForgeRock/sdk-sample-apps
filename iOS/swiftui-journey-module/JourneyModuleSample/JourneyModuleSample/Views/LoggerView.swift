// 
//  LoggerView.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI

struct LoggerView: View {
    let menuItem: MenuItem
    var loggerViewModel = LoggerViewModel()
    var body: some View {
        Text("This View is for testing Logger functionality.\nPlease check the Console Logs")
            .font(.title3)
            .multilineTextAlignment(.center)
            .navigationTitle(menuItem.title)
            .onAppear() {
                loggerViewModel.setupLogger()
            }
    }
}

