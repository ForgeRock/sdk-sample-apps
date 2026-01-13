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

/**
 * A custom implementation of the PinCollector protocol for device binding and signing operations.
 *
 * This class provides a SwiftUI-based PIN collection interface that can be used as an alternative
 * to the default PIN collector in device binding and device signing scenarios. When PIN input is
 * required, this collector presents a modal PinCollectorView over the current view controller,
 * allowing the user to enter their 4-digit PIN.
 *
 * **Implementation Details:**
 * - Conforms to the PinCollector protocol from PingBinding SDK
 * - Presents PinCollectorView modally as a form sheet
 * - Finds the topmost view controller to present the PIN entry UI
 * - Handles both PIN submission and cancellation scenarios
 * - Executes completion handler with the collected PIN (or nil if cancelled)
 *
 * **Usage:**
 * This custom collector can be configured in DeviceBindingCallback or DeviceSigningVerifierCallback:
 *
 * ```swift
 * let result = await callback.bind { config in
 *     config.pinCollector = CustomPinCollector()
 * }
 * ```
 *
 * **Thread Safety:**
 * The collectPin method ensures UI operations are performed on the main thread using DispatchQueue.main.async.
 */
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
