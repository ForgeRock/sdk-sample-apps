/*
 * Copyright (c) 2022-2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import FRCore
import FRAuth

/**
 A struct representing a ForgeRock authentication node.
 */
public struct FRNode: Encodable {
    /// An array of FRCallback objects.
    var frCallbacks: [FRCallback]
    
    /// The authentication ID.
    var authId: String
    
    /// Unique UUID String value of initiated AuthService flow.
    var authServiceId: String
    
    /// Stage attribute in Page Node.
    var stage: String?
    
    /// Header attribute in Page Node.
    var pageHeader: String?
    
    /// Description attribute in Page Node.
    var pageDescription: String?
    
    /// An array of raw callbacks.
    var callbacks: [[String: Any]]
    
    private enum CodingKeys: String, CodingKey {
        case frCallbacks, authId, authServiceId, stage, pageHeader, pageDescription
    }
    
    init(node: Node) {
        authId = node.authId
        authServiceId = node.authServiceId
        stage = node.stage
        pageHeader = node.pageHeader
        pageDescription = node.pageDescription
        frCallbacks = [FRCallback]()
        callbacks = [[String: Any]]()
        for callback in node.callbacks {
            callbacks.append(callback.response)
            frCallbacks.append(FRCallback(callback: callback))
        }
    }
    
    // used for passing the Node object back to the Flutter layer
    func resolve() throws -> String {
        var response = [String: Any]()
        response["authId"] = self.authId
        response["authServiceId"] = self.authServiceId
        response["stage"] = self.stage
        response["description"] = self.pageDescription
        response["header"] = self.pageHeader
        response["callbacks"] = self.callbacks
        return try response.toJson()
    }
}

/**
 A struct representing a ForgeRock callback.
 */
public struct FRCallback: Encodable {
    var type: String
    var prompt: String?
    var choices: [String]?
    var predefinedQuestions: [String]?
    var inputNames: [String]?
    var policies: RawPolicy?
    var failedPolicies: [RawFailedPolicy]?
    
    /// Raw JSON response of Callback
    var response: String
    
    init(callback: Callback) {
        self.type = callback.type
        
        if let thisCallback = callback as? SingleValueCallback {
            self.prompt = thisCallback.prompt
            self.inputNames = [thisCallback.inputName!]
        }
        
        if let thisCallback = callback as? KbaCreateCallback {
            self.prompt = thisCallback.prompt
            self.predefinedQuestions = thisCallback.predefinedQuestions
            self.inputNames = thisCallback.inputNames
        }
        
        if let thisCallback = callback as? ChoiceCallback {
            self.choices = thisCallback.choices
            self.inputNames = [thisCallback.inputName!]
        }
        
        if let thisCallback = callback as? AbstractValidatedCallback {
            if let policyDictionary = thisCallback.policies, let policiesJSON = try? policyDictionary.toJson() {
                let jsonData = Data(policiesJSON.utf8)
                do {
                    self.policies = try JSONDecoder().decode(RawPolicy.self, from: jsonData)
                } catch {
                    print(error)
                }
            }
            if let failedPolicies = thisCallback.failedPolicies {
                self.failedPolicies = []
                for failedPolicy in failedPolicies {
                    var paramsDictionary = [String: FlexibleType]()
                    if let params = failedPolicy.params {
                        let newDictionary = params.mapValues { value -> FlexibleType in
                            if let str = value as? String {
                                return FlexibleType(str, originalType: .string)
                            } else if let str = value as? Int {
                                return FlexibleType(String(str), originalType: .int)
                            } else if let str = value as? Double {
                                return FlexibleType(String(str), originalType: .double)
                            } else if let str = value as? Bool {
                                return FlexibleType(String(str), originalType: .bool)
                            } else {
                                return FlexibleType("", originalType: .string)
                            }
                        }
                        paramsDictionary = newDictionary
                    }
                    self.failedPolicies?.append(RawFailedPolicy(propertyName: self.prompt, params: paramsDictionary, policyRequirement: failedPolicy.policyRequirement, failedDescription: failedPolicy.failedDescription()))
                }
            }
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: callback.response, options: .prettyPrinted), let jsonString = String(data: jsonData, encoding: .utf8) {
            self.response = jsonString
        } else {
            self.response = ""
        }
    }
}

/**
 A struct representing a response from the authentication server.
 */
public struct Response: Codable {
    var authId: String?
    var callbacks: [RawCallback]?
    var status: Int?
}

/**
 A struct representing a raw callback.
 */
public struct RawCallback: Codable {
    var type: String?
    var input: [RawInput]?
    var _id: Int?
}

/**
 A struct representing a raw failed policy.
 */
public struct RawPolicy: Codable {
    var name: String?
    var policyRequirements: [String]?
    var policies: [Policy]?
}

/**
 A struct representing a raw failed policy.
 */
public struct RawFailedPolicy: Codable {
    var propertyName: String?
    var params: [String: FlexibleType]?
    var policyRequirement: String?
    var failedDescription: String?
}

/**
 A struct representing a policy.
 */
public struct Policy: Codable {
    var policyId: String?
    var policyRequirements: [String]?
    var params: [String: FlexibleType]?
}

/**
 A struct representing a raw input.
 */
public struct RawInput: Codable {
    var name: String
    var value: FlexibleType?
}

public enum ResponseType {
    case string
    case int
    case double
    case bool
    case typeMismatch
    case notSet
}

/**
 A struct representing a flexible type.
 */
public struct FlexibleType: Codable {
    /// The original type of the value.
    var originalType: ResponseType
    
    /// The value.
    var value: Any
    
    init(_ value: String, originalType: ResponseType = .notSet) {
        self.value = value
        self.originalType = originalType
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // attempt to decode from all JSON primitives
        if let str = try? container.decode(String.self) {
            value = str
            originalType = .string
        } else if let int = try? container.decode(Int.self) {
            value = int
            originalType = .int
        } else if let double = try? container.decode(Double.self) {
            value = double
            originalType = .double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
            originalType = .bool
        } else {
            originalType = .string
            value = ""
        }
    }
    
    /**
     Encodes the flexible type to the given encoder.
     
     - Parameter encoder: The encoder to write data to.
     - Throws: An error if any value throws an error during encoding.
     */
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch originalType {
        case .string:
            try container.encode(value as! String)
        case .int:
            let unwrappedValue = value as? Int ?? Int(value as! String)
            try container.encode(unwrappedValue)
        case .double:
            let unwrappedValue = value as? Double ?? Double(value as! String)
            try container.encode(unwrappedValue)
        case .bool:
            let unwrappedValue = value as? Bool ?? Bool(value as! String)
            try container.encode(unwrappedValue)
        default:
            try container.encode("")
        }
    }
}
