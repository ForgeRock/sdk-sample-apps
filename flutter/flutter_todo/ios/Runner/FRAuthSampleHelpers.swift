/*
 * Copyright (c) 2022-2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */


import Foundation

extension Dictionary {
    
    /// Convert Dictionary to JSON string
    /// - Throws: exception if dictionary cannot be converted to JSON data or when data cannot be converted to UTF8 string
    /// - Returns: JSON string
    func toJson() throws -> String {
        let data = try JSONSerialization.data(withJSONObject: self)
        if let string = String(data: data, encoding: .utf8) {
            return string
        }
        throw NSError(domain: "Dictionary", code: 1, userInfo: ["message": "Data cannot be converted to .utf8 string"])
    }
}

extension Array {
    
    /// Convert Array to JSON string
    /// - Throws: exception if Array cannot be converted to JSON data or when data cannot be converted to UTF8 string
    /// - Returns: JSON string
    func toJson() throws -> String {
        let data = try JSONSerialization.data(withJSONObject: self, options: [])
        if let string = String(data: data, encoding: .utf8) {
            return string
        }
        throw NSError(domain: "Array", code: 1, userInfo: ["message": "Data cannot be converted to .utf8 string"])
    }
}

extension String {
    /**
     Converts a JSON string to a dictionary.
     
     - Returns: A dictionary representation of the JSON string, or nil if the conversion fails.
     */
    func convertToDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
