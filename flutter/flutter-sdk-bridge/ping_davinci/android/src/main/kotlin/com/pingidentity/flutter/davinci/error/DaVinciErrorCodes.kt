/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci.error

/** Stable [com.pingidentity.flutter.davinci.FlutterError.code] per bridge operation. */
internal object DaVinciErrorCodes {
    const val CONFIGURE = "DAVINCI_CONFIGURE_ERROR"
    const val START = "DAVINCI_START_ERROR"
    const val NEXT = "DAVINCI_NEXT_ERROR"
    const val VALIDATE = "DAVINCI_VALIDATE_ERROR"
    const val GET_SESSION = "DAVINCI_GET_SESSION_ERROR"
    const val GET_TOKEN = "DAVINCI_GET_TOKEN_ERROR"
    const val USERINFO = "DAVINCI_USERINFO_ERROR"
    const val SIGN_OFF = "DAVINCI_SIGN_OFF_ERROR"
    const val DISPOSE = "DAVINCI_DISPOSE_ERROR"
    const val REGISTERED_COLLECTOR_TYPES = "DAVINCI_REGISTERED_COLLECTOR_TYPES_ERROR"
    const val START_POLLING = "DAVINCI_START_POLLING_ERROR"
    const val CANCEL_POLLING = "DAVINCI_CANCEL_POLLING_ERROR"
    const val ACTIVE_POLL_COUNT = "DAVINCI_ACTIVE_POLL_COUNT_ERROR"
}
