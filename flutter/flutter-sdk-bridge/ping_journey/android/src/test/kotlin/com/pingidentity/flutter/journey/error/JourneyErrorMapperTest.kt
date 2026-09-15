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
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertSame

/**
 * Unit tests for [JourneyErrorMapper]'s classification logic and the [classifyError] `Result`
 * extension.
 */
class JourneyErrorMapperTest {

    private val code = "JOURNEY_TEST_ERROR"

    // --- fromThrowable -----------------------------------------------------------------------

    @Test
    fun `fromThrowable returns the same FlutterError unchanged`() {
        val original = FlutterError("SOME_CODE", "already classified", "state")

        val result = JourneyErrorMapper.fromThrowable(code, original)

        assertSame(original, result)
    }

    @Test
    fun `fromThrowable classifies ApiException as exchange`() {
        val error = ApiException(500, "server error")

        val result = JourneyErrorMapper.fromThrowable(code, error)

        assertEquals(code, result.code)
        assertEquals("exchange", result.details)
        assertEquals("server error", result.message)
    }

    @Test
    fun `fromThrowable classifies AuthorizeException as auth`() {
        val error = AuthorizeException("authorization failed")

        val result = JourneyErrorMapper.fromThrowable(code, error)

        assertEquals("auth", result.details)
        assertEquals("authorization failed", result.message)
    }

    @Test
    fun `fromThrowable classifies IllegalArgumentException as argument`() {
        val error = IllegalArgumentException("bad argument")

        val result = JourneyErrorMapper.fromThrowable(code, error)

        assertEquals("argument", result.details)
    }

    @Test
    fun `fromThrowable classifies IllegalStateException as state`() {
        val error = IllegalStateException("bad state")

        val result = JourneyErrorMapper.fromThrowable(code, error)

        assertEquals("state", result.details)
        assertEquals("bad state", result.message)
    }

    @Test
    fun `fromThrowable classifies UnsupportedOperationException as unsupported`() {
        val error = UnsupportedOperationException("not supported")

        val result = JourneyErrorMapper.fromThrowable(code, error)

        assertEquals("unsupported", result.details)
    }

    @Test
    fun `fromThrowable classifies unrecognized exception types as unknown`() {
        val error = RuntimeException("mystery failure")

        val result = JourneyErrorMapper.fromThrowable(code, error)

        assertEquals("unknown", result.details)
        assertEquals("mystery failure", result.message)
    }

    @Test
    fun `fromThrowable falls back to toString when message is null`() {
        val error = RuntimeException()

        val result = JourneyErrorMapper.fromThrowable(code, error)

        assertEquals(error.toString(), result.message)
    }

    @Test
    fun `fromThrowable preserves the given code`() {
        val error = IllegalStateException("bad state")

        val result = JourneyErrorMapper.fromThrowable("JOURNEY_NEXT_ERROR", error)

        assertEquals("JOURNEY_NEXT_ERROR", result.code)
    }

    // --- fromOidcError -------------------------------------------------------------------------

    @Test
    fun `fromOidcError classifies AuthorizeError as auth`() {
        val error = OidcError.AuthorizeError(RuntimeException("auth failed"))

        val result = JourneyErrorMapper.fromOidcError(code, error)

        assertEquals("auth", result.details)
        assertEquals("auth failed", result.message)
    }

    @Test
    fun `fromOidcError AuthorizeError surfaces ApiException status and body`() {
        // The native session agent's exact failure shape: AuthorizeException(message, cause) where
        // cause is the ApiException carrying the server's HTTP status and response body.
        val cause = AuthorizeException(
            "Authorize failed, session is discarded. Please start Journey flow to authenticate.",
            ApiException(403, "{\"error\":\"access_denied\"}"),
        )
        val error = OidcError.AuthorizeError(cause)

        val result = JourneyErrorMapper.fromOidcError(code, error)

        assertEquals("auth", result.details)
        assertEquals(
            "Authorize failed: API error 403: {\"error\":\"access_denied\"}",
            result.message,
        )
    }

    @Test
    fun `fromOidcError AuthorizeError on a blank-body redirect explains the ambiguity`() {
        // sessionAgent.authorize()'s exact "redirected without a code" shape: status 302, and a
        // redirect never carries a body, so ApiException.content is always blank here.
        val cause = AuthorizeException(
            "Authorize failed, session is discarded. Please start Journey flow to authenticate.",
            ApiException(302, ""),
        )
        val error = OidcError.AuthorizeError(cause)

        val result = JourneyErrorMapper.fromOidcError(code, error)
        val message = result.message
        check(message != null) { "expected a non-null message" }

        assertEquals("auth", result.details)
        assert(message.startsWith("Authorize failed: API error 302:")) {
            "expected message to start with the status prefix, was: $message"
        }
        assert(message.contains("session wasn't accepted as authenticated")) {
            "expected message to explain the ambiguous cause, was: $message"
        }
        assert(message.contains("serverinfo")) {
            "expected message to point at serverinfo's cookieName field, was: $message"
        }
    }

    @Test
    fun `fromOidcError AuthorizeError on a blank-body non-redirect status stays plain`() {
        val cause = AuthorizeException("boom", ApiException(500, ""))
        val error = OidcError.AuthorizeError(cause)

        val result = JourneyErrorMapper.fromOidcError(code, error)

        assertEquals("Authorize failed: API error 500: (no response body)", result.message)
    }

    @Test
    fun `fromOidcError AuthorizeError with non-ApiException cause keeps its message`() {
        val error = OidcError.AuthorizeError(IllegalStateException("some other failure"))

        val result = JourneyErrorMapper.fromOidcError(code, error)

        assertEquals("auth", result.details)
        assertEquals("some other failure", result.message)
    }

    @Test
    fun `fromOidcError AuthorizeError falls back to default message when cause has none`() {
        val error = OidcError.AuthorizeError(RuntimeException())

        val result = JourneyErrorMapper.fromOidcError(code, error)

        assertEquals("Authorization error", result.message)
    }

    @Test
    fun `fromOidcError classifies NetworkError as network`() {
        val error = OidcError.NetworkError(RuntimeException("no connection"))

        val result = JourneyErrorMapper.fromOidcError(code, error)

        assertEquals("network", result.details)
        assertEquals("no connection", result.message)
    }

    @Test
    fun `fromOidcError classifies ApiError as exchange with code and message`() {
        val error = OidcError.ApiError(code = 403, message = "forbidden")

        val result = JourneyErrorMapper.fromOidcError(code, error)

        assertEquals("exchange", result.details)
        assertEquals("API error 403: forbidden", result.message)
    }

    @Test
    fun `fromOidcError classifies Unknown as unknown`() {
        val error = OidcError.Unknown(RuntimeException("mystery"))

        val result = JourneyErrorMapper.fromOidcError(code, error)

        assertEquals("unknown", result.details)
        assertEquals("mystery", result.message)
    }

    // --- classifyError Result extension --------------------------------------------------------

    @Test
    fun `classifyError returns the original Result on success`() {
        val success = Result.success("value")

        val result = success.classifyError(code)

        assertEquals(success, result)
    }

    @Test
    fun `classifyError wraps a failure's exception as a classified FlutterError`() {
        val failure = Result.failure<String>(IllegalStateException("bad state"))

        val result = failure.classifyError(code)

        val error = result.exceptionOrNull()
        check(error is FlutterError)
        assertEquals(code, error.code)
        assertEquals("state", error.details)
    }
}
