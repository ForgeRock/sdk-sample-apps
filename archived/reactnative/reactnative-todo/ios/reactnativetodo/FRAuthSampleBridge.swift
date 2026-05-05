/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import FRAuth
import FRCore

/**
 * A Swift module as a sample bridge implementation for providing a middle-layer
 * connecting the ForgeRock iOS SDK with the React Native layer.
 *
 * Types (structs & enums) for the below code are located in `FRAuthSampleTypes.swift`
 */

@objc(FRAuthSampleBridge)
public class FRAuthSampleBridge: NSObject {
  var currentNode: Node?

  @objc static func requiresMainQueueSetup() -> Bool {
    return false
  }

  /**
   * Method for calling the start method on the ForgeRock iOS SDK. This must be called
   * as soon as possible, prior to calling any other method within the SDK.
   */
  @objc func start(
    _ resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
    /**
     * Set log level according to your needs
     * Options are ...
     * - none
     * - verbose
     * - info
     * - network
     * - warning
     * - error
     * - all 
     */
    FRLog.setLogLevel([.all])
    DispatchQueue.main.async {
      do {
        /** *************************************************************************
         * SDK INTEGRATION POINT
         * Summary: Initialize the SDK
         * --------------------------------------------------------------------------
         * Details: This initializes the iOS SDK. It can take a moment to resolve,
         * so we add a slight delay to ensure no other SDK methods are called before
         * the SDK is ready.
         ************************************************************************* */
        let config = Configuration()
        let options = FROptions(
          url: config.amURL,
          realm: config.realm,
          cookieName: config.cookieName,
          authServiceName: config.mainAuthenticationJourney,
          oauthClientId: config.oauthClientId,
          oauthRedirectUri: config.oauthRedirectURI,
          oauthScope: config.oauthScopes
        )
        try FRAuth.start(options: options)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
          /**
           * Check for FRAuth.shared. If it exists, the SDK is good to go. If not,
           */
          if FRAuth.shared != nil {
            resolve("SDK initialized")
          } else {
            reject("Error", "SDK not initialized; please check the log for details", nil)
          }
        }
      }
      catch {
        FRLog.e(error.localizedDescription)
        reject("Error", "SDK failed during the initialization process", error)
      }
    }
  }
  
  /**
   * Method for the initial call to the journey/tree defined in `forgerock_auth_service_name` within the FRAuthConfig.
   */
  @objc func login(
    _ resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock) {
      
      /** *************************************************************************
       * SDK INTEGRATION POINT
       * Summary: Make initial request to the journey/tree for login
       * --------------------------------------------------------------------------
       * Details: This calls the tree assigned to login within the FRAuthConfig.
       * It returns a `node`, which is also known as a "step". This `node` is a
       * collection of "callbacks", which represent a request for atomic
       * information.
       ************************************************************************* */
      FRUser.login { (user, node, error) in
        self.handleNode(user, node, error, resolve: resolve, rejecter: reject)
      }
    }

  /**
   * Method for the initial call to the journey/tree defined in `forgerock_registration_service_name`
   * within the FRAuthConfig.
   */
  @objc func register(
    _ resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock) {

    /** *************************************************************************
     * SDK INTEGRATION POINT
     * Summary: Make initial request to the journey/tree for registration
     * --------------------------------------------------------------------------
     * Details: This calls the tree assigned to registration within the
     * FRAuthConfig. It returns a `node`, which is also known as a "step". This
     * `node` is a collection of "callbacks", which represent a request for
     * atomic information
     ************************************************************************* */
    FRUser.register { (user, node, error) in
      self.handleNode(user, node, error, resolve: resolve, rejecter: reject)
    }
  }

  /**
   * Method for continuing the iterative requests to a journey/tree, regardless of use of method above,
   * login or register.
   */
  @objc func next(
    _ response: String,
    resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock) {

    /**
     * Serialized JSON response will need to be preped for parsing.
     */
    let decoder = JSONDecoder()
    let jsonData = Data(response.utf8)

    /**
     * First, let's check to see if we have an existing `node` (aka a "step"). If we don't, this is an error condition
     * as this should be a continuation of a previous journey/tree.
     *
     * If we have a `node`, let's prepare it with the new inputs from the UI layer before we submit it.
     */
    if let node = self.currentNode {
      var responseObject: Response?

      do {
        /**
         * Parse JSON into response object. Throw if parsing fails.
         */
        responseObject = try decoder.decode(Response.self, from: jsonData)
      } catch  {
        let errorMsg = "Failed to parse the JSON received from UI layer"
        FRLog.e(errorMsg)
        reject("Error", errorMsg, error)
      }

      let callbacksArray = responseObject?.callbacks ?? []

      /**
       * Loop over each item within `callbacks`
       */
      for (outerIndex, nodeCallback) in node.callbacks.enumerated() {
        /**
         * The KBA callback requires special treatment as it has multiple inputs: Question and Answer,
         * which requires two loops.
         */
        if let thisCallback = nodeCallback as? KbaCreateCallback {
          for (innerIndex, rawCallback) in callbacksArray.enumerated() {
            if let inputsArray = rawCallback.input, outerIndex == innerIndex {
              for input in inputsArray {
                if let value = input.value!.value as? String {

                  /** *************************************************************************
                   * SDK INTEGRATION POINT
                   * Summary: Convenience methods for setting values on callbacks
                   * --------------------------------------------------------------------------
                   * Details: Each callback has unique methods for getting and setting data on
                   * itself. These are convenience methods to help dealing with the callback's
                   * unique data attributes.
                   ************************************************************************* */
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

        /**
         * DeviceProfileCallback inherits from HiddenValueCallback, which itself inherits from SingleValueCallback.
         * To prevent the input value from being overwritten by SingleValueCallback logic,
         * we must handle DeviceProfileCallback first.
         */

        else if let thisCallback = nodeCallback as? DeviceProfileCallback {
          handleDeviceProfileCallback(thisCallback, node: node, resolve: resolve, rejecter: reject)
          return //prevent duplicate promise resolution
        }

        /**
         * This detects the "common" callback with a single input value.
         */
        else if let thisCallback = nodeCallback as? SingleValueCallback {
          for (innerIndex, rawCallback) in callbacksArray.enumerated() {
            if let inputsArray = rawCallback.input, outerIndex == innerIndex,
              let value = inputsArray.first?.value {

              /** *************************************************************************
               * SDK INTEGRATION POINT
               * Summary: Convenience methods for setting values on callbacks
               * --------------------------------------------------------------------------
               * Details: Each callback has unique methods for getting and setting data on
               * itself. These are convenience methods to help dealing with the callback's
               * unique data attributes.
               ************************************************************************* */
              switch value.originalType {
              case .string:
                thisCallback.setValue(value.value as! String)
              case .int:
                thisCallback.setValue(value.value as! Int)
              case .double:
                thisCallback.setValue(value.value as! Double)
              case .bool:
                thisCallback.setValue(value.value as! Bool)
              default:
                break
              }

            }
          }
        }

        /**
         * If the callback is neither KBA or single value callback, then it's currently unsupported or there's been a failure
         */
        else {
          reject("Error", "Received an unsupported callback", nil)
        }
      }

      /** *************************************************************************
       * SDK INTEGRATION POINT
       * Summary: Call `next` on the `node` to continue the journey/tree
       * --------------------------------------------------------------------------
       * Details: This `node` is what's returned from `FRAuth.login` or
       * `FRAuth.reqister`. Calling `next` submits the data to ForgeRock and either
       * completes the journey/tree as success or failure, OR it returns another
       * `node` with more callbacks to handle.
       ************************************************************************* */
      next(node: node, resolve: resolve, rejecter: reject)

    } else {
          print("UnkownError --------->")
      reject("Error", "UnkownError", nil)
    }
  }
  
  func next(node: Node, resolve: @escaping RCTPromiseResolveBlock,
            rejecter reject: @escaping RCTPromiseRejectBlock) {
    node.next(completion: { (user: FRUser?, node, error) in
      if let node = node {
        /**
         * Process our new node (aka "step") and resolve the promise
         */
        self.handleNode(user, node, error, resolve: resolve, rejecter: reject)
      } else {
        if let error = error {
          reject("Error", "LoginFailure", error)
          return
        }
        print("User --------->: \(String(describing: user.debugDescription))")
        
        /**
         * This journey/tree has completed without error, resolve promise with user tokens
         */
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let user = user,
          let token = user.token,
          let data = try? encoder.encode(token),
          let jsonAccessToken = String(data: data, encoding: .utf8) {

          resolve(["type": "LoginSuccess", "tokens": jsonAccessToken])
        } else {
          resolve(["type": "LoginSuccess", "tokens": ""])
        }
      }
    })
  }

  /**
   * Method for logging the user out.
   */
  @objc func logout() {

    /** *************************************************************************
     * SDK INTEGRATION POINT
     * Summary: Logout the currently authenticated user
     * --------------------------------------------------------------------------
     * Details: This `logout` method ends the users session as well as revokes
     * the associated OAuth/OIDC tokens.
     ************************************************************************* */
    FRUser.currentUser?.logout()
  }

  /**
   * Method for calling the `getUserInfo` to retrieve the user information from the OIDC endpoint
   */
  @objc func getUserInfo(
    _ resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock) {

    /** *************************************************************************
     * SDK INTEGRATION POINT
     * Summary: Confirm an authenticated user exists
     * --------------------------------------------------------------------------
     * Details: This method returns a local user object from the SDK.
     ************************************************************************* */
    guard let user = FRUser.currentUser else {
      /**
       * If no currently, authenticated user is found, log error and return
       */
      let errorMsg = "Invalid SDK state: No current user for which to request user info"
      reject("error", errorMsg, nil)
      return
    }

    /** *************************************************************************
     * SDK INTEGRATION POINT
     * Summary: Request current user information
     * --------------------------------------------------------------------------
     * Details: This method calls the standard OIDC endpoint `/userinfo`. The
     * endpoint will return the claims associated with the scopes granted when
     * the access token was requested.
     ************************************************************************* */
    user.getUserInfo { (userInfo, error) in
      if let error = error {
        FRLog.e(String(describing: error))
        reject("error", error.localizedDescription, error)
      }
      else if let userInfo = userInfo {
        FRLog.i(userInfo.debugDescription)
        resolve(userInfo.userInfo)
      }
      else {
        let errorMsg = "Invalid SDK state: userInfo returned no result"
        FRLog.e(errorMsg)
        reject("error", errorMsg, nil)
      }
    }
  }

  /**
   * Method for retreiving the OAuth/OIDC tokens for an authenticated user.
   */
  @objc func getAccessToken(
    _ resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock) {

    /** *************************************************************************
     * SDK INTEGRATION POINT
     * Summary: Confirm an authenticated user exists
     * --------------------------------------------------------------------------
     * Details: This method returns a local user object from the SDK.
     ************************************************************************* */
    guard let user = FRUser.currentUser else {
      /**
       * If no currently authenticated user is found, log error.
       */
      let errorMsg = "Invalid SDK state: No current user for which to request access tokens"
      FRLog.e(errorMsg)
      reject("error", errorMsg, nil)
      return
    }

    /** *************************************************************************
     * SDK INTEGRATION POINT
     * Summary: Request current user's access tokens
     * --------------------------------------------------------------------------
     * Details: This method calls the standard OAuth 2.0 endpoints using the
     * Authorization Code Flow with PKCE for requesting OAuth/OIDC tokens.
     ************************************************************************* */
    user.getAccessToken { user, error in
      if let error = error {
        FRLog.e(String(describing: error))
        reject("error", error.localizedDescription, error)
      }
      else if let user = user, let accessToken = user.token {
        let encoder = JSONEncoder()

        do {
          let data = try encoder.encode(accessToken)
          let string = String(data: data, encoding: .utf8)
          FRLog.i(string ?? "Encoding of token failed")
          resolve(string)
        } catch {
          reject("Error", "Serialization of tokens failed", error)
        }
      }
      else {
        let errorMsg = "Invalid SDK state: getAccessToken returned no result"
        FRLog.e(errorMsg)
        reject("error", errorMsg, nil)
      }
    }
  }

  /**
   * Method for handling Device Profile Callback.
   * This callback is used to collect device information, such as location and metadata.
   *
   * ⚠️ Important:
   * For this to function as expected make sure you have added the required
   * privacy usage description keys in your Info.plist:
   *
   * - NSBluetoothAlwaysUsageDescription
   * - NSFaceIDUsageDescription
   * - NSLocationWhenInUseUsageDescription
   */
   private func handleDeviceProfileCallback(
    _ callback: DeviceProfileCallback,
    node: Node,
    resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock) {
    
    // Execute the device profile collection
    callback.execute { collectedData in
      guard 
        !collectedData.isEmpty
      else {
        let errorMsg = "Device profile callback handler: Collectors returned no device profile data"
        FRLog.e(errorMsg)
        reject("Error", errorMsg, nil)
        return
      }
      FRLog.i("Device profile data collected")

      // Continue to the next node after collecting device profile data
      self.next(node: node, resolve: resolve, rejecter: reject)
    }
  }



  /**
   * Private method for preparing a node returned from the iOS SDK for the React Native layer.
   * This serializes the node in a way that allows the use of `FRStep` from the ForgeRock JavaScript SDK,
   * which adds better "ergonomics" within the JavaScript layer of React Native.
   */
  private func handleNode(
    _ result: Any?,
    _ node: Node?,
    _ error: Error?,
    resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock) {

    if let node = node {
      self.currentNode = node
      extract(node: node, resolve: resolve, rejecter: reject)
    } else {
      if let error = error {
        FRLog.e(String(describing: error))
        reject("Error", error.localizedDescription, error)
      } else {
        let errorMsg = "Unknown node handling failure";
        FRLog.e(errorMsg)
        reject("Error", errorMsg, nil)
      }
    }
  }
  
  func extract(node: Node, resolve: @escaping RCTPromiseResolveBlock,
               rejecter reject: @escaping RCTPromiseRejectBlock) {
    for (outerIndex, nodeCallback) in node.callbacks.enumerated() {
        if let thisCallback = nodeCallback as? WebAuthnRegistrationCallback {
          DispatchQueue.main.async {
          thisCallback.register(node: node, usePasskeysIfAvailable: true, onSuccess: { (attestation) in
            
            self.next(node: node, resolve: resolve, rejecter: reject)
            
          }) { (error) in
            self.next(node: node, resolve: resolve, rejecter: reject)
          }
          
        }
          return
      }
      if let thisCallback = nodeCallback as? WebAuthnAuthenticationCallback{
        DispatchQueue.main.async {
          thisCallback.authenticate(node: node, usePasskeysIfAvailable: true, onSuccess: { (attestation) in
            self.next(node: node, resolve: resolve, rejecter: reject)
          }) { (error) in
            self.next(node: node, resolve: resolve, rejecter: reject)
          }
          
        }
        return
      }
    }
    let frNode = FRNode(node: node)
    do {
      resolve(try frNode.resolve())
    }
    catch {
      reject("Error", "Serialization of node failed", error)
    }
    
  }
}
