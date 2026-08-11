/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.journey.error

import com.pingidentity.exception.ApiException
import com.pingidentity.flutter.journey.FlutterError
import com.pingidentity.oidc.OidcError
import com.pingidentity.oidc.exception.AuthorizeException

/**
 * Classifies a native failure into a Pigeon [FlutterError] carrying a stable per-operation
 * [FlutterError.code] plus a small `type` classification in [FlutterError.details], surfaced to
 * Dart as `PingException.type` (see `JourneyClient._guard`).
 *
 * Native `Workflow.start()`/`ContinueNode.next()` never throw — failure is always a returned
 * `FailureNode`/`ErrorNode`, already handled by
 * [com.pingidentity.flutter.journey.mapper.JourneyNodeMapper] — so this mapper only needs to
 * classify [OidcError] (from `getSession`'s `Result.Failure`, per
 * `com.pingidentity.oidc.OidcError`'s own `catch` classification) and the handful of exception
 * types the bridge itself can throw (unknown journeyId/node, malformed callback value).
 */
internal object JourneyErrorMapper {
    /** Wraps a caught [Throwable] as a classified [FlutterError], unless it already is one. */
    fun fromThrowable(code: String, throwable: Throwable): FlutterError {
        if (throwable is FlutterError) return throwable
        val type =
            when (throwable) {
                is ApiException -> "exchange"
                is AuthorizeException -> "auth"
                is IllegalArgumentException -> "argument"
                is IllegalStateException -> "state"
                is UnsupportedOperationException -> "unsupported"
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
}

/** Classifies this [Result]'s failure, if any, via [JourneyErrorMapper.fromThrowable]. */
internal fun <T> Result<T>.classifyError(code: String): Result<T> {
    val error = exceptionOrNull() ?: return this
    return Result.failure(JourneyErrorMapper.fromThrowable(code, error))
}
