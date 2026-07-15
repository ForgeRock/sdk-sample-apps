/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.journey

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** Registers the generated [PingJourneyHostApi] Pigeon channel. */
class PingJourneyPlugin : FlutterPlugin {
    private var api: JourneyHostApiImpl? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        api = JourneyHostApiImpl()
        PingJourneyHostApi.setUp(binding.binaryMessenger, api)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        PingJourneyHostApi.setUp(binding.binaryMessenger, null)
        api?.shutdown()
        api = null
    }
}
