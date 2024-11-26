//
//  TokenViewModel.swift
//  Davinci
//
//  Copyright (c) 2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingLogger

class TokenViewModel: ObservableObject {
  @Published var accessToken: String = ""
  
  init() {
    Task {
      await accessToken()
    }
  }
  
  func accessToken() async {
    let token = await davinci.user()?.token()
    switch token {
    case .success(let accessToken):
      await MainActor.run {
        self.accessToken = String(describing: accessToken)
      }
      LogManager.standard.i("AccessToken: \(self.accessToken)")
    case .failure(let error):
      await MainActor.run {
        self.accessToken = "Error: \(error.localizedDescription)"
      }
      LogManager.standard.e("", error: error)
    case .none:
      break
    }
  }
}

class UserInfoViewModel: ObservableObject {
  @Published var userInfo: String = ""
  
  init() {
    Task {
      await fetchUserInfo()
    }
  }
  
  func fetchUserInfo() async {
    let userInfo = await davinci.user()?.userinfo(cache: false)
    switch userInfo {
    case .success(let userInfoDictionary):
      await MainActor.run {
        var userInfoDescription = ""
        userInfoDictionary.forEach { userInfoDescription += "\($0): \($1)\n" }
        self.userInfo = userInfoDescription
      }
      LogManager.standard.i("UserInfo: \(String(describing: self.userInfo))")
    case .failure(let error):
      await MainActor.run {
        self.userInfo = "Error: \(error.localizedDescription)"
      }
      LogManager.standard.e("", error: error)
    case .none:
      break
    }
  }
}

class LogOutViewModel: ObservableObject {
  @Published var logout: String = ""
  
  func logout() async {
    await davinci.user()?.logout()
    await MainActor.run {
      logout =  "Logout completed"
    }
  }
}
