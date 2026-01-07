//
//  CustomPinCollector.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import UIKit
import SwiftUI
import PingBinding
import Combine

class CustomPinCollector: PinCollector {
    
    func collectPin(prompt: Prompt, completion: @escaping @Sendable (String?) -> Void) {
        DispatchQueue.main.async {
            let keyWindow = UIApplication.shared.windows.filter { $0.isKeyWindow }.first
            var topVC = keyWindow?.rootViewController
            while let presentedViewController = topVC?.presentedViewController {
                topVC = presentedViewController
            }
            
            guard let topVC = topVC else {
                completion(nil)
                return
            }
            
            let pinView = PinCollectorView(prompt: prompt) { pin in
                topVC.dismiss(animated: true) {
                    completion(pin)
                }
            }
            
            let hostingController = UIHostingController(rootView: pinView)
            hostingController.modalPresentationStyle = .formSheet
            
            topVC.present(hostingController, animated: true, completion: nil)
        }
    }
}
