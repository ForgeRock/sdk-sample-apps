//
//  KeylessView.swift
//  JourneyModuleSample
//
//  Created by george bafaloukas on 08/01/2026.
//

import PingJourney
import SwiftUI
import KeylessSDK

struct KeylessView: View {
    //    let viewModel = KeylessViewModel()
    let callback: HiddenValueCallback
    let onNext: () -> Void
    
    var body: some View {
        VStack {
            Text("Device Signing")
                .font(.title)
            Text("Please wait while we sign the challenge.")
                .font(.body)
                .padding()
            ProgressView()
        }
        .onAppear(perform: handleKeyless)
    }
    
    func keylessConfigure() async throws {
        let setupConfig = SetupConfig(
            apiKey: <#apiKey#>,
            hosts: [<#host#>]
        )
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.main.async {
                Keyless.configure(setupConfiguration: setupConfig) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
            
            
        }
    }
    
    func isUserEnrolledOnDevice() async throws -> Bool {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            Keyless.validateUserDeviceActive(
                completionHandler: { error in
                    if let error = error {
                        print("Keyless User or device deactivated: performing a reset")
                        // error code 1131 = user is not enrolled on the device (not even locally so did not check on backend)
                        // error code 534 = user not found or deactivated on backend
                        // error code 535 = device not found or deactivated on backend
                        
                        continuation.resume(returning: (false))
                    } else {
                        print("Keyless User and device active")
                        continuation.resume(returning: (true))
                    }
                }
            )
        }
    }
    
    func keylessEnroll() async throws -> KeylessResponse? {
        Keyless.reset()
        let jwtSigningInfo = JwtSigningInfo(claimTransactionData: "test")
        let configuration = BiomEnrollConfig(jwtSigningInfo: jwtSigningInfo, generatingClientState: .backup)
        let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<KeylessResponse, Error>) in
            DispatchQueue.main.async {
                Keyless.enroll(
                    configuration: configuration,
                    onCompletion: { result in
                        switch result {
                        case .success(let enrollmentSuccess):
                            print("Enrollment finished successfully. UserID: \(enrollmentSuccess.keylessId)")
                            let response = KeylessResponse(jwt: enrollmentSuccess.signedJwt, clientState: enrollmentSuccess.clientState, error: nil)
                            continuation.resume(returning: (response))
                        case .failure(let error):
                            continuation.resume(throwing: error)
                            print("Enrollment finished with error: \(error.message)")
                        }
                    })
            }
        }
        return response
    }
    
    func keylessAuthenticate(clientState: String?) async throws -> KeylessResponse? {
        do {
            let enrolled = try await isUserEnrolledOnDevice()
            let jwtSigningInfo = JwtSigningInfo(claimTransactionData: "test")
            if enrolled {
                let configuration = BiomAuthConfig(jwtSigningInfo: jwtSigningInfo)
                let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<KeylessResponse, Error>) in
                    DispatchQueue.main.async {
                        Keyless.authenticate(
                            configuration: configuration,
                            onCompletion: { result in
                                switch result {
                                case .success(let enrollmentSuccess):
                                    print("Authentication finished successfully.")
                                    let response = KeylessResponse(jwt: enrollmentSuccess.signedJwt, clientState: nil, error: nil)
                                    continuation.resume(returning: (response))
                                case .failure(let error):
                                    continuation.resume(throwing: error)
                                    print("Authentication finished with error: \(error.message)")
                                }
                            })
                    }
                }
                return response
            } else {
                let configuration = BiomEnrollConfig(clientState: clientState, jwtSigningInfo: jwtSigningInfo)
                let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<KeylessResponse, Error>) in
                    DispatchQueue.main.async {
                        Keyless.enroll(
                            configuration: configuration,
                            onCompletion: { result in
                                switch result {
                                case .success(let enrollmentSuccess):
                                    print("Authentication finished successfully.")
                                    let response = KeylessResponse(jwt: enrollmentSuccess.signedJwt, clientState: nil, error: nil)
                                    continuation.resume(returning: (response))
                                case .failure(let error):
                                    continuation.resume(throwing: error)
                                    print("Authentication finished with error: \(error.message)")
                                }
                            })
                    }
                }
                return response
            }
        } catch {
            return nil
        }
    }
    
    func handleKeyless() -> Void {
        Task { @MainActor in
            do {
                try await keylessConfigure()
                
                if (callback.valueId == "keylessEnrolment") {
                    let keylessPayload = try await keylessEnroll()
                    if let jsonData = try? JSONEncoder().encode(keylessPayload),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        print(jsonString)
                        callback.setValue(jsonString)
                        onNext()
                    }
                } else if (callback.valueId == "keylessAuthentication") {
                    let keylessPayload = try await keylessAuthenticate(clientState: callback.value)
                    if let jsonData = try? JSONEncoder().encode(keylessPayload),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        print(jsonString)
                        callback.setValue(jsonString)
                        onNext()
                    }
                }
            } catch {
                print("Keyless Error: \(error)")
                let keylessPayload: KeylessResponse = KeylessResponse(jwt: nil, clientState: nil, error: error.localizedDescription)
                if let jsonData = try? JSONEncoder().encode(keylessPayload),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString)
                    callback.setValue(jsonString)
                    onNext()
                }
            }
        }
    }
}

struct KeylessPayload: Codable {
    let keylessAPIKey: String
    let keylessHost: String
    let op_id: String
}

struct KeylessResponse: Codable {
    let jwt: String?
    let clientState: String?
    let error: String?
}
