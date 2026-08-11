/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.core

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Trivial [FlutterPlugin] registration so the `ping_core` module loads and links
 * [CoreRuntime] into the app's classloader. Carries no Pigeon/method channel of its own.
 */
class PingCorePlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {}

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
}
