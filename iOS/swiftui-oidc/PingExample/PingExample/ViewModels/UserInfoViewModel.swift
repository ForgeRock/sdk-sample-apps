// 
//  UserInfoViewModel.swift
//  PingExample
//
//  Copyright (c) 2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRAuth

class UserInfoViewModel: ObservableObject {
    
    @Published var userInfo: String = ""
    
    init() {
        Task {
            await fetchUserInfo()
        }
    }
    
    func fetchUserInfo() async {
        let _ = FRUser.currentUser?.getUserInfo(completion: { result, error in
            Task { @MainActor in
                if let userInfo = result?.userInfo {
                    var userInfoDescription = ""
                    userInfo.forEach { userInfoDescription += "\($0): \($1)\n" }
                    self.userInfo = userInfoDescription
                } else {
                    self.userInfo = "Error: \(String(describing: error?.localizedDescription))"
                }
            }
        })
    }
}
