//
//  OIDCViewModel.swift
//  PingExample
//
//  Copyright (c) 2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRAuth
import UIKit

class OIDCViewModel: ObservableObject {
    
    private var topViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
              var topController = keyWindow.rootViewController else {
            return nil
        }
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
    
    public func startOIDC() async throws -> FRUser {
        
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<FRUser, Error>) in
            Task { @MainActor in
                FRUser.browser()?
                    .set(presentingViewController: self.topViewController!)
                    .set(browserType: .authSession)
                    .build().login { (user, error) in
                        if let frUser = user {
                            continuation.resume(returning: frUser)
                        } else {
                            continuation.resume(throwing: error!)
                        }
                    }
            }
        })
    }
}
