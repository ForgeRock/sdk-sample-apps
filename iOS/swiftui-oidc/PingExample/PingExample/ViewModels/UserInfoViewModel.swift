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

/*
 The UserInfoViewModel class is used to manage the user information for the current user.
    The class provides the following functionality:
        - Fetches the user information for the current user.
 */
class UserInfoViewModel: ObservableObject {
    
    @Published var userInfo: String = ""
    
    init() {
        Task {
            await fetchUserInfo()
        }
    }
    
    func fetchUserInfo() async {
        if let user = FRUser.currentUser {
            let _ = user.getUserInfo(completion: { result, error in
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
        } else {
            Task { @MainActor in
                self.userInfo = "No user found, need to log in first."
            }
        }
        
    }
}
