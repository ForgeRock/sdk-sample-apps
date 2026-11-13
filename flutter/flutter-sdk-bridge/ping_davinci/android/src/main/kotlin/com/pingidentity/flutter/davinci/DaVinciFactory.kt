/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci

import com.pingidentity.flutter.core.CoreRuntime
import com.pingidentity.flutter.core.registry.NativeHandle
import com.pingidentity.orchestrate.Workflow

/** Wraps a live native DaVinci [Workflow] so it can be stored in [CoreRuntime.davinciRegistry]. */
internal class DaVinciHandle(val daVinci: Workflow) : NativeHandle

/**
 * Builds a native DaVinci workflow from a [DaVinciConfigMessage] and registers it in the shared
 * core registry, returning the generated `daVinciId`.
 *
 * Unlike iOS, nothing needs awaiting here: the SDK's `CollectorRegistry` is a `ModuleInitializer`
 * that AndroidX Startup runs eagerly at process start, so every core collector is registered
 * before any `DaVinci` exists.
 */
internal object DaVinciFactory {
    fun create(config: DaVinciConfigMessage): String =
        CoreRuntime.davinciRegistry.register(DaVinciHandle(DaVinciConfigParser.parse(config)))
}
