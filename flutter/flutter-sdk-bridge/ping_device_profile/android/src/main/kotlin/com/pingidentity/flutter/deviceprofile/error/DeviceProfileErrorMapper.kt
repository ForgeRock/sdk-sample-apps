/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.deviceprofile.error

import com.pingidentity.flutter.deviceprofile.FlutterError

/**
 * Classifies a native failure into a Pigeon [FlutterError] carrying a stable per-operation
 * [FlutterError.code] plus a small `type` classification in [FlutterError.details], surfaced to
 * Dart as `PingException.type`. Mirrors the sibling modules' mappers.
 */
internal object DeviceProfileErrorMapper {
    /** Wraps a caught [Throwable] as a classified [FlutterError], unless it already is one. */
    fun fromThrowable(code: String, throwable: Throwable): FlutterError {
        if (throwable is FlutterError) return throwable
        val type =
            when (throwable) {
                is IllegalArgumentException -> "argument"
                is IllegalStateException -> "state"
                is SecurityException -> "permission"
                is UnsupportedOperationException -> "unsupported"
                else -> "unknown"
            }
        return FlutterError(code, throwable.message ?: throwable.toString(), type)
    }
}

/** Classifies this [Result]'s failure, if any, via [DeviceProfileErrorMapper.fromThrowable]. */
internal fun <T> Result<T>.classifyError(code: String): Result<T> {
    val error = exceptionOrNull() ?: return this
    return Result.failure(DeviceProfileErrorMapper.fromThrowable(code, error))
}
