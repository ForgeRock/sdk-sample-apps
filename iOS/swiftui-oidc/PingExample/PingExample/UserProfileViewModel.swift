//
//  UserProfileViewModel.swift
//  PingExample
//
//  Created by jey periyasamy on 5/8/24.
//

import Foundation

class UserProfileViewModel: ObservableObject {
    
    @Published var userProfile: String = ""
    
    init() {
        Task {
            await self.accessToken()
        }
    }
    
    func accessToken() async {
//        let foo = await davinci.user()?.userinfo(cache: <#T##Bool#>)
//        await MainActor.run {
//            accessToken =  foo.debugDescription
//        }
//        
//        print("AccessToken ----->\(String(describing: foo))")
    }
}
