/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingDeviceProfile
import ping_core

/// The server-registered type of the Journey callback this bridge collects.
let deviceProfileCallbackType = "DeviceProfileCallback"

/// Implements the generated `PingDeviceProfileHostApi`.
///
/// Stateless: the live `DeviceProfileCallback` is resolved on every call from the Journey's handle
/// (`ping_core`'s `ActiveNodeAccess`), under the same lock that serializes the Journey's `next()`.
final class DeviceProfileHostApiImpl: PingDeviceProfileHostApi, @unchecked Sendable {
    func collect(
        journeyId: String,
        callbackIndex: Int64,
        completion: @escaping (Result<[String?: Any?], Error>) -> Void
    ) {
        Task {
            do {
                let handle = try await CoreRuntime.journeyRegistry.requireActiveNode(journeyId)
                let profile = try await handle.withItem(
                    type: deviceProfileCallbackType,
                    index: Int(callbackIndex)
                ) { item in
                    guard let callback = item as? DeviceProfileCallback else {
                        throw DeviceProfileHostApiError.argumentError(
                            "Callback at index \(callbackIndex) is not a DeviceProfileCallback"
                        )
                    }
                    // The native collect() also stores the profile on the callback itself, so the
                    // app only submits the node afterwards with JourneyClient.next.
                    switch await callback.collect() {
                    case .success(let profile):
                        return profile
                    case .failure(let error):
                        throw error
                    }
                }
                let bridged: [String?: Any?] = profile.reduce(into: [:]) { result, entry in
                    result[entry.key] = entry.value
                }
                completion(.success(bridged))
            } catch {
                completion(.failure(DeviceProfileErrorMapper.from(DeviceProfileErrorCodes.collect, error)))
            }
        }
    }
}
