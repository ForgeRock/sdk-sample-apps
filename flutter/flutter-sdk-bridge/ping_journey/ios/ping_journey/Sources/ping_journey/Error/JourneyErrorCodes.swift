/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// Stable `FlutterError.code` per bridge operation.
enum JourneyErrorCodes {
    static let configure = "JOURNEY_CONFIGURE_ERROR"
    static let start = "JOURNEY_START_ERROR"
    static let next = "JOURNEY_NEXT_ERROR"
    static let getSession = "JOURNEY_GET_SESSION_ERROR"
    static let signOff = "JOURNEY_SIGN_OFF_ERROR"
    static let dispose = "JOURNEY_DISPOSE_ERROR"
}
