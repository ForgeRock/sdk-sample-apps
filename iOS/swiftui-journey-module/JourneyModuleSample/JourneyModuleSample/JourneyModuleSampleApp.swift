//
//  JourneyModuleSampleApp.swift
//  JourneyModuleSample
//
//  Created by george bafaloukas on 05/01/2026.
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
    // Connect AppDelegate for push notifications
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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
