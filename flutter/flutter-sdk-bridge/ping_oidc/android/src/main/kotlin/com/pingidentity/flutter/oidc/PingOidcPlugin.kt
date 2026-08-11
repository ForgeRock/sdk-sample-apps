/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.oidc

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** Registers the generated [PingOidcHostApi] Pigeon channel. */
class PingOidcPlugin : FlutterPlugin {
    private var api: OidcHostApiImpl? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        api = OidcHostApiImpl()
        PingOidcHostApi.setUp(binding.binaryMessenger, api)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        PingOidcHostApi.setUp(binding.binaryMessenger, null)
        api?.shutdown()
        api = null
    }
}
