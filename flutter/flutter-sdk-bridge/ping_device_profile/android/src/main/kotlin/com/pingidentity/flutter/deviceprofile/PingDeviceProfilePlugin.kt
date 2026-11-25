/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.deviceprofile

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** Registers the generated [PingDeviceProfileHostApi] Pigeon channel. */
class PingDeviceProfilePlugin : FlutterPlugin {
    private var api: DeviceProfileHostApiImpl? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        api = DeviceProfileHostApiImpl()
        PingDeviceProfileHostApi.setUp(binding.binaryMessenger, api)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        PingDeviceProfileHostApi.setUp(binding.binaryMessenger, null)
        api?.shutdown()
        api = null
    }
}
