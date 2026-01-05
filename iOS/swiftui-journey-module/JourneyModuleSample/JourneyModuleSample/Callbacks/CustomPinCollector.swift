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
