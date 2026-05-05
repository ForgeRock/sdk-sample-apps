/*
 * Copyright (c) 2022 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import FRAuth
import FRCore
import Flutter

/**
 A struct that holds the configuration constants for the authentication journey.
 */
struct Configuration {
    /// The main authentication journey name.
    static let mainAuthenticationJourney = "[YOUR_MAIN_AUTHENTICATION_JOURNEY_NAME]"
    /// The URL of the authentication server.
    static let amURL = "[YOUR_AM_URL]"
    /// The name of the cookie used for authentication.
    static let cookieName = "[COOKIE NAME]"
    /// The realm used for authentication.
    static let realm = "[REALM NAME]"
    /// The OAuth client ID.
    static let oauthClientId = "[OAUTH_CLIENT_ID]"
    /// The OAuth redirect URI.
    static let oauthRedirectURI = "[OAUTH_REDIRECT_URI]"
    /// The OAuth scopes.
    static let oauthScopes = "[OAUTH_SCOPES]"
    /// The discovery endpoint for OAuth configuration.
    static let discoveryEndpoint = "[DISCOVERY_ENDPOINT]"
}

/**
 A class that bridges the FRAuth functionality to Flutter.
 */
public class FRAuthSampleBridge {
    /// The current authentication node.
    var currentNode: Node?
    /// The URL session used for network requests.
    private let session = URLSession(configuration: .default)
    
    /**
     Starts the FRAuth authentication process.
     
     - Parameter result: The result callback to be called upon completion.
     */
    @objc func frAuthStart(result: @escaping FlutterResult) {
        // Set log level according to your needs
        FRLog.setLogLevel([.all])
        
        do {
            
            let options = FROptions(url: Configuration.amURL, realm: Configuration.realm, cookieName: Configuration.cookieName, authServiceName: Configuration.mainAuthenticationJourney, oauthClientId: Configuration.oauthClientId, oauthRedirectUri: Configuration.oauthRedirectURI, oauthScope: Configuration.oauthScopes)
            try FRAuth.start(options: options)
            result("SDK Initialised")
            FRUser.currentUser?.logout()
        }
        catch {
            FRLog.e(error.localizedDescription)
            result(FlutterError(code: "SDK Init Failed",
                                message: error.localizedDescription,
                                details: nil))
        }
    }
    
    /**
     Logs in the user.
     
     - Parameter result: The result callback to be called upon completion.
     */
    @objc func login(result: @escaping FlutterResult) {
        FRUser.login { (user, node, error) in
            self.handleNode(user, node, error, completion: result)
        }
    }
    
    /**
     Registers a new user.
     
     - Parameter result: The result callback to be called upon completion.
     */
    @objc func register(result: @escaping FlutterResult) {
        FRUser.register { (user, node, error) in
            self.handleNode(user, node, error, completion: result)
        }
    }
    
    /**
     Logs out the current user from FRAuth.
     
     - Parameter result: The result callback to be called upon completion.
     */
    @objc func frLogout(result: @escaping FlutterResult) {
        FRUser.currentUser?.logout()
        result("User logged out")
    }
    
    /**
     Retrieves the current user's information.
     
     - Parameter result: The result callback to be called upon completion.
     */
    @objc func getUserInfo(result: @escaping FlutterResult) {
        FRUser.currentUser?.getUserInfo(completion: { userInfo, error in
            if (error != nil) {
                result(FlutterError(code: "Error",
                                    message: error?.localizedDescription,
                                    details: nil))
            } else {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                if let userInfo = userInfo?.userInfo, let userInfoJson = try? userInfo.toJson() {
                    result(userInfoJson)
                } else {
                    result(FlutterError(code: "Error",
                                        message: "User info encoding failed",
                                        details: nil))
                }
                
            }
        })
    }
    
    /**
     Proceeds to the next step in the authentication journey.
     
     - Parameter result: The result callback to be called upon completion.
     */
    @objc func next(_ response: String, completion: @escaping FlutterResult) {
        let decoder = JSONDecoder()
        let jsonData = Data(response.utf8)
        if let node = self.currentNode {
            var responseObject: Response?
            do {
                responseObject = try decoder.decode(Response.self, from: jsonData)
            } catch  {
                print(String(describing: error))
                completion(FlutterError(code: "Error",
                                        message: error.localizedDescription,
                                        details: nil))
                return
            }
            
            let callbacksArray = responseObject?.callbacks ?? []
            // If the array is empty there are no user inputs. This can happen in callbacks like the DeviceProfileCallback, that do not require user interaction.
            // Other callbacks like SingleValueCallback, will return the user inputs in an array of dictionaries [[String:String]] with the keys: identifier and text
            if callbacksArray.count == 0 {
                for nodeCallback in node.callbacks {
                    if let thisCallback = nodeCallback as? DeviceProfileCallback {
                        let semaphore = DispatchSemaphore(value: 1)
                        semaphore.wait()
                        thisCallback.execute { _ in
                            semaphore.signal()
                        }
                    }
                }
            } else {
                for (outerIndex, nodeCallback) in node.callbacks.enumerated() {
                    if let thisCallback = nodeCallback as? KbaCreateCallback {
                        for (innerIndex, rawCallback) in callbacksArray.enumerated() {
                            if let inputsArray = rawCallback.input, outerIndex == innerIndex {
                                for input in inputsArray {
                                    if let value = input.value?.value as? String {
                                        if input.name.contains("question") {
                                            thisCallback.setQuestion(value)
                                        } else {
                                            thisCallback.setAnswer(value)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if let thisCallback = nodeCallback as? SingleValueCallback {
                        for (innerIndex, rawCallback) in callbacksArray.enumerated() {
                            if let inputsArray = rawCallback.input, outerIndex == innerIndex, let value = inputsArray.first?.value {
                                switch value.originalType {
                                case .string:
                                    thisCallback.setValue(value.value as? String)
                                case .int:
                                    thisCallback.setValue(value.value as? Int)
                                case .double:
                                    thisCallback.setValue(value.value as? Double)
                                case .bool:
                                    thisCallback.setValue(value.value as? Bool)
                                default:
                                    break
                                }
                            }
                        }
                    }
                }
            }
            
            //Call node.next
            node.next(completion: { (user: FRUser?, node, error) in
                if let node = node {
                    //Handle node and return
                    self.handleNode(user, node, error, completion: completion)
                } else {
                    if let error = error {
                        //Send the error back in the rejecter - nextStep.type === 'LoginFailure'
                        completion(FlutterError(code: "LoginFailure",
                                                message: error.localizedDescription,
                                                details: nil))
                        return
                    }
                    //Transform the response for the nextStep.type === 'LoginSuccess'
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    do {
                        if let user = user, let token = user.token, let data = try? encoder.encode(token), let jsonAccessToken = String(data: data, encoding: .utf8) {
                            FRLog.i("LoginSuccess - sessionToken: \(jsonAccessToken)")
                            completion(try ["type": "LoginSuccess", "sessionToken": jsonAccessToken].toJson())
                        } else {
                            FRLog.i("LoginSuccess")
                            completion(try ["type": "LoginSuccess", "sessionToken": ""].toJson())
                        }
                    }
                    catch {
                        completion(FlutterError(code: "Serializing Response failed",
                                                message: error.localizedDescription,
                                                details: nil))
                    }
                }
            })
            
        } else {
            completion(FlutterError(code: "Error",
                                    message: "UnkownError",
                                    details: nil))
        }
    }
    
    /**
     Calls a specified endpoint.
     
     - Parameters:
     - endpoint: The endpoint to call.
     - completion: The completion callback to be called upon completion.
     */
    @objc func callEndpoint(_ endpoint: String, method: String, payload: String, completion: @escaping FlutterResult) {
        // Invoke API
        FRUser.currentUser?.getAccessToken { (user, error) in
            
            //  AM 6.5.2 - 7.0.0
            //
            //  Endpoint: /oauth2/realms/userinfo
            //  API Version: resource=2.1,protocol=1.0
            
            var header: [String: String] = [:]
            
            if error == nil, let user = user {
                header["Authorization"] = user.buildAuthHeader()
            }
            
            let request = Request(url: endpoint, method: Request.HTTPMethod(rawValue: method) ?? .GET, headers: header, bodyParams: payload.convertToDictionary() ?? [:], urlParams: [:], requestType: .json, responseType: .json)
            self.session.dataTask(with: request.build()!) { (data, response, error) in
                guard let responseData = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                    completion(FlutterError(code: "API Error",
                                            message: error?.localizedDescription,
                                            details: nil))
                    return
                }
                
                if (200 ..< 303) ~= httpResponse.statusCode {
                    completion(String(data: responseData, encoding: .utf8))
                } else {
                    completion(FlutterError(code: "Error: statusCode",
                                            message: httpResponse.statusCode.description,
                                            details: nil))
                }
            }.resume()
        }
    }
    
    /**
     Handles the current authentication node.
     
     - Parameters:
     - result: The result of the previous step.
     - node: The current authentication node.
     - error: Any error that occurred during the previous step.
     - completion: The completion callback to be called upon completion.
     */
    private func handleNode(_ result: Any?, _ node: Node?, _ error: Error?, completion: @escaping FlutterResult) {
        if let node = node {
            self.currentNode = node
            let frNode = FRNode(node: node)
            do {
                completion(try frNode.resolve())
            }
            catch {
                completion(FlutterError(code: "Serializing Node failed",
                                        message: error.localizedDescription,
                                        details: nil))
            }
        } else {
            completion(FlutterError(code: "Error",
                                    message: "No node present",
                                    details: nil))
        }
    }
}

extension FRAuthSampleBridge {
    func setUpChannels(_ window: UIWindow?) {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            print("Could not resolve FlutterViewController from window?.rootViewController")
            return
        }
        let bridgeChannel = FlutterMethodChannel(name: "forgerock.com/SampleBridge",
                                                 binaryMessenger: controller.binaryMessenger)
        
        
        bridgeChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "frAuthStart":
                self.frAuthStart(result: result)
            case "login":
                self.login(result: result)
            case "register":
                self.register(result: result)
            case "logout":
                self.frLogout(result: result)
            case "next":
                if let response = call.arguments as? String {
                    self.next(response, completion: result)
                } else {
                    result(FlutterError(code: "500", message: "Arguments not parsed correctly", details: nil))
                }
            case "callEndpoint":
                if let arguments = call.arguments as? [String] {
                    self.callEndpoint(arguments[0], method: arguments[1], payload: arguments[2], completion: result)
                } else {
                    result(FlutterError(code: "500", message: "Arguments not parsed correctly", details: nil))
                }
            case "getUserInfo":
                self.getUserInfo(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        })
    }
}
