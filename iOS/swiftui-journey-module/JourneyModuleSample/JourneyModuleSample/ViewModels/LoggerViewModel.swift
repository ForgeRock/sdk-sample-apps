//
//  LoggerViewModel.swift
//  PingExample
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingLogger
import Combine

class LoggerViewModel {
    
    func setupLogger() {
        // shared logger - by default is "none"
        var sharedLogger = LogManager.logger
        sharedLogger.d("sharedLogger Debug")
        sharedLogger.i("sharedLogger Info")
        sharedLogger.w("sharedLogger Warning", error: TestError.success)
        sharedLogger.e("sharedLogger Error", error: TestError.failure)
        
        // standard logger - messages of all levels should be displayed in the console...
        let standardLogger = LogManager.standard
        standardLogger.d("standardLogger Debug")
        standardLogger.i("standardLogger Info")
        standardLogger.w("standardLogger Warning", error: TestError.success)
        standardLogger.e("standardLogger Error", error: TestError.failure)
        
        // warning logger - only warning and error messages should be displayed...
        let warningLogger = LogManager.warning
        warningLogger.d("warningLogger Debug")
        warningLogger.i("warningLogger Info")
        warningLogger.w("warningLogger Warning", error: TestError.success)
        warningLogger.e("warningLogger Error", error: TestError.failure)
        
        // none logger - none of these messages will be displayed...
        let noneLogger = LogManager.none
        noneLogger.d("noneLogger Debug")
        noneLogger.i("noneLogger Info")
        noneLogger.w("noneLogger Warning", error: TestError.success)
        noneLogger.e("noneLogger Error", error: TestError.failure)
        
        // switch the shared logger to "standard" - the message from below will be displayed in the console
        sharedLogger = LogManager.standard
        sharedLogger.d("sharedLogger Debug")
        sharedLogger.i("sharedLogger Info")
        sharedLogger.w("sharedLogger Warning", error: TestError.success)
        sharedLogger.e("sharedLogger Error", error: TestError.failure)
        
        // test a custom logger
        let customLogger = LogManager.customLogger
        customLogger.d("customLogger Debug")
        customLogger.i("customLogger Info")
        customLogger.w("customLogger Warning", error: TestError.success)
        customLogger.e("customLogger Error", error: TestError.failure)
    }
    
    enum TestError: Error {
        case success
        case failure
    }
}


struct CustomLogger: Logger {
    
    func i(_ message: String) {
        print("\(message) (CustomLogger)")
    }
    
    func d(_ message: String) {
        print("\(message) (CustomLogger)")
    }
    
    func w(_ message: String, error: Error?) {
        if let error = error {
            print("\(message): \(error) (CustomLogger)")
        } else {
            print("\(message) (CustomLogger)")
        }
    }
    
    func e(_ message: String, error: Error?) {
        if let error = error {
            print("\(message): \(error) (CustomLogger)")
        } else {
            print("\(message) (CustomLogger)")
        }
    }
}

extension LogManager {
    static var customLogger: Logger {
        return CustomLogger()
    }
}
