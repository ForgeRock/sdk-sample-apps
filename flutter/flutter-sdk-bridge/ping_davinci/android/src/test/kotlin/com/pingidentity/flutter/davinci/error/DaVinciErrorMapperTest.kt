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
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertSame

class DaVinciErrorMapperTest {
    private fun typeOf(throwable: Throwable): Any? =
        DaVinciErrorMapper.fromThrowable(DaVinciErrorCodes.CONFIGURE, throwable).details

    @Test
    fun `fromThrowable returns the same FlutterError unchanged`() {
        val error = FlutterError("CODE", "message", "state")
        assertSame(error, DaVinciErrorMapper.fromThrowable(DaVinciErrorCodes.START, error))
    }

    @Test
    fun `fromThrowable classifies every mapped exception type`() {
        assertEquals("exchange", typeOf(ApiException(400, "bad")))
        assertEquals("auth", typeOf(AuthorizeException("denied")))
        assertEquals("cancelled", typeOf(BrowserCanceledException()))
        assertEquals("storage", typeOf(StorageException("io")))
        assertEquals("argument", typeOf(IllegalArgumentException("bad arg")))
        assertEquals("state", typeOf(IllegalStateException("rewind failed")))
        assertEquals("unsupported", typeOf(UnsupportedOperationException()))
        assertEquals("unknown", typeOf(RuntimeException("other")))
    }

    @Test
    fun `fromThrowable classifies SerializationException before its IllegalArgumentException base`() {
        assertEquals("serialization", typeOf(SerializationException("bad json")))
    }

    @Test
    fun `fromThrowable keeps the operation code and message`() {
        val error =
            DaVinciErrorMapper.fromThrowable(DaVinciErrorCodes.CONFIGURE, IllegalArgumentException("nope"))
        assertEquals("DAVINCI_CONFIGURE_ERROR", error.code)
        assertEquals("nope", error.message)
    }

    @Test
    fun `fromOidcError classifies each OidcError case`() {
        val cause = RuntimeException("why")
        fun type(error: OidcError) = DaVinciErrorMapper.fromOidcError(DaVinciErrorCodes.GET_TOKEN, error).details
        assertEquals("auth", type(OidcError.AuthorizeError(cause)))
        assertEquals("network", type(OidcError.NetworkError(cause)))
        assertEquals("exchange", type(OidcError.ApiError(500, "boom")))
        assertEquals("unknown", type(OidcError.Unknown(cause)))
    }
}
