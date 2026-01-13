//
//  BindingKeysViewModel.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingBinding
import PingCommons
import Combine

@MainActor
class BindingKeysViewModel: ObservableObject {
    
    @Published var userKeys: [UserKey] = []
    
    func fetchKeys() async {
        do {
            self.userKeys = try await BindingModule.getAllKeys()
        } catch {
            print("Error fetching keys: \(error)")
        }
    }
    
    func deleteKey(key: UserKey) async {
        do {
            try await BindingModule.deleteKey(key)
            await fetchKeys()
        } catch {
            print("Error deleting key: \(error)")
        }
    }
    
    func deleteAllKeys() async {
        do {
            try await BindingModule.deleteAllKeys()
            await fetchKeys()
        } catch {
            print("Error deleting all keys: \(error)")
        }
    }
}
