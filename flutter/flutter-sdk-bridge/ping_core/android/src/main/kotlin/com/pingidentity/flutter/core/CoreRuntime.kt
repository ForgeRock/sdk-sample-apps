/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.core

import com.pingidentity.flutter.core.registry.Registry
import com.pingidentity.flutter.core.registry.SimpleRegistry

/**
 * Central place to hold process-wide registries and shared helpers used by the core module.
 *
 * Keeps native handles alive across calls from the Flutter bridge. Every future native module
 * (oidc, davinci, storage, ...) shares this same object, so it must live in `ping_core` rather
 * than in any single feature plugin.
 */
object CoreRuntime {
    /** Registry for Journey client instances. */
    val journeyRegistry: Registry = SimpleRegistry()
}
