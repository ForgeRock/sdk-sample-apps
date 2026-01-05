//
//  StorageViewModel.swift
//  PingExample
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingStorage
import PingLogger

@MainActor
class StorageViewModel {
    func setupMemoryStorage() async {
        do {
            let memoryStorage1 = MemoryStorage<String>()
            try await memoryStorage1.save(item: "Andy")
            let storedValue1 = try await memoryStorage1.get()
            LogManager.standard.i("Memory Storage value: \(storedValue1!)")
        } catch {
            LogManager.standard.e("", error: error)
        }
        
    }
    
    func setupKeychainStorage() async {
        do {
            let keychainStorage = KeychainStorage<String>(account: "token", encryptor: SecuredKeyEncryptor() ?? NoEncryptor())
            try await keychainStorage.save(item: "Jey")
            let storedValue = try await keychainStorage.get()
            LogManager.standard.i("Keychain Storage value: \(storedValue!)")
        } catch {
            LogManager.standard.e("", error: error)
        }
    }
}
