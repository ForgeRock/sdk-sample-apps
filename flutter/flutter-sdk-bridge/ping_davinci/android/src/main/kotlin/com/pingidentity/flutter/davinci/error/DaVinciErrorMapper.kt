/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci.error

import com.pingidentity.browser.BrowserCanceledException
import com.pingidentity.exception.ApiException
import com.pingidentity.flutter.davinci.FlutterError
import com.pingidentity.oidc.OidcError
import com.pingidentity.oidc.exception.AuthorizeException
import com.pingidentity.storage.exception.StorageException
import kotlinx.serialization.SerializationException

/**
 * Classifies a native failure into a Pigeon [FlutterError] carrying a stable per-operation
 * [FlutterError.code] plus a small `type` classification in [FlutterError.details], surfaced to
 * Dart as `PingException.type`. Same contract as `ping_journey`'s `JourneyErrorMapper`.
 *
 * Native `Workflow.start()`/`ContinueNode.next()` never throw — failure is a returned
 * `FailureNode`/`ErrorNode` — so this covers the exceptions raised around the flow (OIDC token
 * exchange, storage, response decoding) and the ones the bridge throws itself. Android has no
 * `PollingError` type: polling failures arrive as a `PollingStatus.Error` value, not a throw.
 */
internal object DaVinciErrorMapper {
    /** Wraps a caught [Throwable] as a classified [FlutterError], unless it already is one. */
    fun fromThrowable(code: String, throwable: Throwable): FlutterError {
        if (throwable is FlutterError) return throwable
        val type =
            when (throwable) {
                is ApiException -> "exchange"
                is AuthorizeException -> "auth"
                is BrowserCanceledException -> "cancelled"
                is StorageException -> "storage"
                // Before IllegalArgumentException: SerializationException extends it.
                is SerializationException -> "serialization"
                is IllegalArgumentException -> "argument"
                // Also what the SDK throws when an ErrorNode can't rewind to its ContinueNode.
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

/** Classifies this [Result]'s failure, if any, via [DaVinciErrorMapper.fromThrowable]. */
internal fun <T> Result<T>.classifyError(code: String): Result<T> {
    val error = exceptionOrNull() ?: return this
    return Result.failure(DaVinciErrorMapper.fromThrowable(code, error))
}
