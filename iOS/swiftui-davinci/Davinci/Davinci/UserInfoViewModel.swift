// 
//  UserInfoViewModel.swift
//  Davinci
//
//  Copyright (c) 2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingLogger

/// A view model responsible for fetching and managing user information.
/// - Provides a published `userInfo` property that is updated with user information or error messages.
/// - Fetches user data asynchronously using the DaVinci SDK.
class UserInfoViewModel: ObservableObject {
  /// Published property to hold the user information or error messages.
  @Published var userInfo: String = ""
  
  /// Initializes the `UserInfoViewModel` and fetches user information.
  /// - The data is fetched asynchronously during initialization.
  init() {
    Task {
      await fetchUserInfo()
    }
  }
  
  /// Fetches user information from the DaVinci SDK.
  /// - The method retrieves user details as a dictionary and formats them as a string for display.
  /// - Updates the `userInfo` property with the fetched data or an error message.
  /// - Logs success and error messages using `PingLogger`.
  func fetchUserInfo() async {
    let userInfo = await davinci.user()?.userinfo(cache: false)
    switch userInfo {
    case .success(let userInfoDictionary):
      // On success, format the dictionary into a string and update `userInfo`.
      await MainActor.run {
        var userInfoDescription = ""
        userInfoDictionary.forEach { userInfoDescription += "\($0): \($1)\n" }
        self.userInfo = userInfoDescription
      }
      LogManager.standard.i("UserInfo: \(String(describing: self.userInfo))")
    case .failure(let error):
      // On failure, update `userInfo` with an error message and log the error.
      await MainActor.run {
        self.userInfo = "Error: \(error.localizedDescription)"
      }
      LogManager.standard.e("", error: error)
    case .none:
      // No data received, no further action required.
      break
    }
  }
}
