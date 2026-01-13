/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.userprofile

import com.pingidentity.oidc.OidcError
import kotlinx.serialization.json.JsonObject

enum class DeviceType {
    OATH,
    PUSH,
    BOUND,
    WEBAUTHN,
    PROFILE
}

data class UserProfileState(
    var user: JsonObject? = null,
    var error: OidcError? = null,
    var deviceList: List<String> = emptyList(),
    var showDeviceInfo: Boolean = false,
    var selectedDeviceType: DeviceType = DeviceType.OATH,
    var isLoading: Boolean = false,
    var showEditDialog: Boolean = false,
    var deviceToEdit: String? = null,
    var newDeviceName: String = ""
)
