//
//  FRAuthSampleHelpers.swift
//  Runner
//
//  Created by George Bafaloukas on 03/03/2022.
//

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
