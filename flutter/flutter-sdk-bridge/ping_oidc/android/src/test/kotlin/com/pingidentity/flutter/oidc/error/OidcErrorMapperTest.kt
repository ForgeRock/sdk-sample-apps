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
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertSame

/**
 * Unit tests for [OidcErrorMapper]'s classification logic and the [classifyError] `Result`
 * extension.
 */
class OidcErrorMapperTest {

    private val code = "OIDC_TEST_ERROR"

    // --- fromThrowable -----------------------------------------------------------------------

    @Test
    fun `fromThrowable returns the same FlutterError unchanged`() {
        val original = FlutterError("SOME_CODE", "already classified", "state")

        val result = OidcErrorMapper.fromThrowable(code, original)

        assertSame(original, result)
    }

    @Test
    fun `fromThrowable classifies IllegalArgumentException as argument`() {
        val error = IllegalArgumentException("bad argument")

        val result = OidcErrorMapper.fromThrowable(code, error)

        assertEquals("argument", result.details)
        assertEquals("bad argument", result.message)
    }

    @Test
    fun `fromThrowable classifies IllegalStateException as state`() {
        val error = IllegalStateException("bad state")

        val result = OidcErrorMapper.fromThrowable(code, error)

        assertEquals("state", result.details)
    }

    @Test
    fun `fromThrowable classifies UnsupportedOperationException as unsupported`() {
        val error = UnsupportedOperationException("not supported")

        val result = OidcErrorMapper.fromThrowable(code, error)

        assertEquals("unsupported", result.details)
    }

    @Test
    fun `fromThrowable classifies unrecognized exception types as unknown`() {
        val error = RuntimeException("mystery failure")

        val result = OidcErrorMapper.fromThrowable(code, error)

        assertEquals("unknown", result.details)
        assertEquals("mystery failure", result.message)
    }

    @Test
    fun `fromThrowable classifies BrowserCanceledException as cancelled`() {
        val error = BrowserCanceledException()

        val result = OidcErrorMapper.fromThrowable(code, error)

        assertEquals("cancelled", result.details)
    }

    @Test
    fun `fromThrowable classifies ActivityNotFoundException as browser_unavailable`() {
        val error = ActivityNotFoundException("no browser")

        val result = OidcErrorMapper.fromThrowable(code, error)

        assertEquals("browser_unavailable", result.details)
    }

    @Test
    fun `fromThrowable falls back to toString when message is null`() {
        val error = RuntimeException()

        val result = OidcErrorMapper.fromThrowable(code, error)

        assertEquals(error.toString(), result.message)
    }

    @Test
    fun `fromThrowable preserves the given code`() {
        val error = IllegalStateException("bad state")

        val result = OidcErrorMapper.fromThrowable("OIDC_CONFIGURE_ERROR", error)

        assertEquals("OIDC_CONFIGURE_ERROR", result.code)
    }

    // --- fromOidcError -------------------------------------------------------------------------

    @Test
    fun `fromOidcError classifies AuthorizeError as auth`() {
        val error = OidcError.AuthorizeError(RuntimeException("auth failed"))

        val result = OidcErrorMapper.fromOidcError(code, error)

        assertEquals("auth", result.details)
        assertEquals("auth failed", result.message)
    }

    @Test
    fun `fromOidcError classifies NetworkError as network`() {
        val error = OidcError.NetworkError(RuntimeException("no connection"))

        val result = OidcErrorMapper.fromOidcError(code, error)

        assertEquals("network", result.details)
        assertEquals("no connection", result.message)
    }

    @Test
    fun `fromOidcError classifies ApiError as exchange with code and message`() {
        val error = OidcError.ApiError(code = 403, message = "forbidden")

        val result = OidcErrorMapper.fromOidcError(code, error)

        assertEquals("exchange", result.details)
        assertEquals("API error 403: forbidden", result.message)
    }

    @Test
    fun `fromOidcError classifies Unknown as unknown`() {
        val error = OidcError.Unknown(RuntimeException("mystery"))

        val result = OidcErrorMapper.fromOidcError(code, error)

        assertEquals("unknown", result.details)
        assertEquals("mystery", result.message)
    }

    // --- notImplemented ------------------------------------------------------------------------

    @Test
    fun `notImplemented returns a stable not_implemented classification`() {
        val result = OidcErrorMapper.notImplemented(OidcErrorCodes.AUTHORIZE)

        assertEquals(OidcErrorCodes.AUTHORIZE, result.code)
        assertEquals("not_implemented", result.details)
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
