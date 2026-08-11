/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.journey.error

/** Stable [com.pingidentity.flutter.journey.FlutterError.code] per bridge operation. */
internal object JourneyErrorCodes {
    const val CONFIGURE = "JOURNEY_CONFIGURE_ERROR"
    const val START = "JOURNEY_START_ERROR"
    const val NEXT = "JOURNEY_NEXT_ERROR"
    const val GET_SESSION = "JOURNEY_GET_SESSION_ERROR"
    const val SIGN_OFF = "JOURNEY_SIGN_OFF_ERROR"
    const val DISPOSE = "JOURNEY_DISPOSE_ERROR"
}
