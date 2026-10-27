/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Registers the generated [PingDaVinciHostApi] Pigeon channel and the `pollingEvents` event
 * channel. The event channel goes with the engine's messenger on detach.
 */
class PingDaVinciPlugin : FlutterPlugin {
    private var api: DaVinciHostApiImpl? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val api = DaVinciHostApiImpl()
        this.api = api
        PingDaVinciHostApi.setUp(binding.binaryMessenger, api)
        PollingEventsStreamHandler.register(binding.binaryMessenger, api.pollingEvents)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        PingDaVinciHostApi.setUp(binding.binaryMessenger, null)
        api?.shutdown()
        api = null
    }
}
