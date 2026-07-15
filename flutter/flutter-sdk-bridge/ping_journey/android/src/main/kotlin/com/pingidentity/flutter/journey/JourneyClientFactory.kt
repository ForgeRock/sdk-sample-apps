/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.journey

import com.pingidentity.flutter.core.CoreRuntime
import com.pingidentity.flutter.core.registry.NativeHandle
import com.pingidentity.journey.Journey

/**
 * Wraps a live native [Journey] so it can be stored in [CoreRuntime.journeyRegistry].
 *
 * [hasOidc] records whether the [JourneyConfigMessage] this journey was built from actually
 * configured an Oidc module — [Journey.user] unconditionally calls `oidcClient()` internally,
 * which throws `IllegalStateException` when no Oidc module was registered, so callers must
 * check this flag *before* touching `user()`/`token()` on a session-only Journey.
 */
internal class JourneyHandle(val journey: Journey, val hasOidc: Boolean) : NativeHandle

/**
 * Builds a native [Journey] from a [JourneyConfigMessage] and registers it in the shared
 * core registry, returning the generated `journeyId`.
 */
internal object JourneyClientFactory {
    fun create(config: JourneyConfigMessage): String {
        val journey = JourneyConfigParser.parse(config)
        return CoreRuntime.journeyRegistry.register(
            JourneyHandle(journey, hasOidc = JourneyConfigParser.hasOidcConfig(config))
        )
    }
}
