/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.deviceprofile

import com.pingidentity.device.profile.DeviceProfileCallback
import com.pingidentity.flutter.core.CoreRuntime
import com.pingidentity.flutter.core.mapper.JsonBridgeMapper
import com.pingidentity.flutter.core.node.requireActiveNode
import com.pingidentity.flutter.deviceprofile.error.DeviceProfileErrorCodes
import com.pingidentity.flutter.deviceprofile.error.classifyError
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/** The server-registered type of the Journey callback this bridge collects. */
internal const val DEVICE_PROFILE_CALLBACK_TYPE = "DeviceProfileCallback"

/**
 * Implements the generated [PingDeviceProfileHostApi].
 *
 * Stateless: the live `DeviceProfileCallback` is resolved on every call from the Journey's handle
 * (`ping_core`'s `ActiveNodeAccess`), under the same lock that serializes the Journey's `next()`.
 */
class DeviceProfileHostApiImpl : PingDeviceProfileHostApi {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun collect(
        journeyId: String,
        callbackIndex: Long,
        callback: (Result<Map<String?, Any?>>) -> Unit
    ) {
        scope.launch {
            val result =
                runCatching {
                    val handle = CoreRuntime.journeyRegistry.requireActiveNode(journeyId)
                    handle.withItem(DEVICE_PROFILE_CALLBACK_TYPE, callbackIndex.toInt()) { item ->
                        val profileCallback =
                            item as? DeviceProfileCallback
                                ?: throw IllegalArgumentException(
                                    "Callback at index $callbackIndex is not a DeviceProfileCallback"
                                )
                        // The native collect() also stores the profile on the callback itself, so
                        // the app only submits the node afterwards with JourneyClient.next.
                        // getOrThrow() rethrows a failed collection's exception for the mapper.
                        val profile = profileCallback.collect().getOrThrow()
                        JsonBridgeMapper.encodeJsonElement(profile) as? Map<String?, Any?>
                            ?: throw IllegalStateException(
                                "Device profile did not encode to a JSON object"
                            )
                    }
                }
            callback(result.classifyError(DeviceProfileErrorCodes.COLLECT))
        }
    }

    /** Cancels all in-flight coroutines. Called from [PingDeviceProfilePlugin.onDetachedFromEngine]. */
    fun shutdown() {
        scope.cancel()
    }
}
