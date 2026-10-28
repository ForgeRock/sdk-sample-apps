/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// Stable `FlutterError.code` per bridge operation.
enum DaVinciErrorCodes {
    static let configure = "DAVINCI_CONFIGURE_ERROR"
    static let start = "DAVINCI_START_ERROR"
    static let next = "DAVINCI_NEXT_ERROR"
    static let validate = "DAVINCI_VALIDATE_ERROR"
    static let getSession = "DAVINCI_GET_SESSION_ERROR"
    static let getToken = "DAVINCI_GET_TOKEN_ERROR"
    static let getUserInfo = "DAVINCI_USERINFO_ERROR"
    static let signOff = "DAVINCI_SIGN_OFF_ERROR"
    static let dispose = "DAVINCI_DISPOSE_ERROR"
    static let registeredCollectorTypes = "DAVINCI_REGISTERED_COLLECTOR_TYPES_ERROR"
    static let startPolling = "DAVINCI_START_POLLING_ERROR"
    static let cancelPolling = "DAVINCI_CANCEL_POLLING_ERROR"
    static let activePollCount = "DAVINCI_ACTIVE_POLL_COUNT_ERROR"
    static let retainedState = "DAVINCI_RETAINED_STATE_ERROR"
}
