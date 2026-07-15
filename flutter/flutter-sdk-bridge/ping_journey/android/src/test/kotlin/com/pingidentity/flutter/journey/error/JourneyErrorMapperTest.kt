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
