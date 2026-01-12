//
//  JourneyModuleSampleApp.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//
import SwiftUI
import PingExternalIdPFacebook
import PingExternalIdPGoogle
import PingBrowser
import PingDeviceId
import PingTamperDetector
import PingOidc
import PingProtect
import PingBinding
import PingOath
import PingPush

@main
struct JourneyModuleSampleApp: App {
    
    // Create an instance of the manager.
    // @StateObject ensures it's kept alive for the app's lifecycle.
    @StateObject private var sceneManager = ScenePhaseManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    let handled = GoogleRequestHandler.handleOpenURL(UIApplication.shared, url: url, options: nil)
                    if !handled {
                        FacebookRequestHandler.handleOpenURL(UIApplication.shared, url: url, options: nil)
                    }
                    OpenURLMonitor.shared.handleOpenURL(url)
                }
                .environmentObject(sceneManager)
        }
    }
}
