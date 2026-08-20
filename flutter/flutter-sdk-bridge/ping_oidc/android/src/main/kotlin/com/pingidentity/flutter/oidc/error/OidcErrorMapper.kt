/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.oidc.error

import android.content.ActivityNotFoundException
import com.pingidentity.browser.BrowserCanceledException
import com.pingidentity.flutter.oidc.FlutterError
import com.pingidentity.oidc.OidcError

/**
 * Classifies a native failure into a Pigeon [FlutterError] carrying a stable per-operation
 * [FlutterError.code] plus a small `type` classification in [FlutterError.details], surfaced to
 * Dart as `PingException.type` (see `OidcClient._guard`). Mirrors `ping_journey`'s
 * `JourneyErrorMapper` shape.
 */
internal object OidcErrorMapper {
    /** Wraps a caught [Throwable] as a classified [FlutterError], unless it already is one. */
    fun fromThrowable(code: String, throwable: Throwable): FlutterError {
        if (throwable is FlutterError) return throwable
        val type =
            when (throwable) {
                is IllegalArgumentException -> "argument"
                is IllegalStateException -> "state"
                is UnsupportedOperationException -> "unsupported"
                // Defensive only — `OidcHostApiImpl.authorize` intercepts this before the mapper
                // runs, resolving a cancelled browser as `AuthorizeResultMessage.cancel` rather
                // than an error. Kept here in case cancellation ever surfaces from another call
                // path.
                is BrowserCanceledException -> "cancelled"
                is ActivityNotFoundException -> "browser_unavailable"
                else -> "unknown"
            }
        return FlutterError(code, throwable.message ?: throwable.toString(), type)
    }

    /** Classifies an [OidcError] value (not a [Throwable] — returned via `oidc.Result`). */
    fun fromOidcError(code: String, error: OidcError): FlutterError {
        val (type, message) =
            when (error) {
                is OidcError.AuthorizeError ->
                    "auth" to (error.cause.message ?: "Authorization error")
                is OidcError.NetworkError -> "network" to (error.cause.message ?: "Network error")
                is OidcError.ApiError -> "exchange" to "API error ${error.code}: ${error.message}"
                is OidcError.Unknown -> "unknown" to (error.cause.message ?: "Unknown OIDC error")
            }
        return FlutterError(code, message, type)
    }

    /** A stub error for a method not yet implemented in this phase. */
    fun notImplemented(code: String): FlutterError =
        FlutterError(code, "Not implemented until a later phase", "not_implemented")
}

/** Classifies this [Result]'s failure, if any, via [OidcErrorMapper.fromThrowable]. */
internal fun <T> Result<T>.classifyError(code: String): Result<T> {
    val error = exceptionOrNull() ?: return this
    return Result.failure(OidcErrorMapper.fromThrowable(code, error))
}
