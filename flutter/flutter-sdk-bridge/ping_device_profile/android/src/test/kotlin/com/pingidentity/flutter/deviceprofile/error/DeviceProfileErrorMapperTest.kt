/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.deviceprofile.error

import com.pingidentity.flutter.deviceprofile.FlutterError
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertSame

/** Unit tests for [DeviceProfileErrorMapper.fromThrowable]. */
class DeviceProfileErrorMapperTest {

    @Test
    fun `fromThrowable classifies IllegalArgumentException as argument`() {
        val error = DeviceProfileErrorMapper.fromThrowable(
            DeviceProfileErrorCodes.COLLECT,
            IllegalArgumentException("no such callback"),
        )

        assertEquals(DeviceProfileErrorCodes.COLLECT, error.code)
        assertEquals("argument", error.details)
        assertEquals("no such callback", error.message)
    }

    @Test
    fun `fromThrowable classifies IllegalStateException as state`() {
        val error = DeviceProfileErrorMapper.fromThrowable(
            DeviceProfileErrorCodes.COLLECT,
            IllegalStateException("journey not found"),
        )

        assertEquals("state", error.details)
        assertEquals("journey not found", error.message)
    }

    @Test
    fun `fromThrowable classifies SecurityException as permission`() {
        val error = DeviceProfileErrorMapper.fromThrowable(
            DeviceProfileErrorCodes.COLLECT,
            SecurityException("location permission denied"),
        )

        assertEquals("permission", error.details)
        assertEquals("location permission denied", error.message)
    }

    @Test
    fun `fromThrowable classifies UnsupportedOperationException as unsupported`() {
        val error = DeviceProfileErrorMapper.fromThrowable(
            DeviceProfileErrorCodes.COLLECT,
            UnsupportedOperationException("nope"),
        )

        assertEquals("unsupported", error.details)
    }

    @Test
    fun `fromThrowable classifies unrecognized exception types as unknown`() {
        val error = DeviceProfileErrorMapper.fromThrowable(
            DeviceProfileErrorCodes.COLLECT,
            RuntimeException("boom"),
        )

        assertEquals("unknown", error.details)
        assertEquals("boom", error.message)
    }

    @Test
    fun `fromThrowable falls back to toString when the exception has no message`() {
        val error = DeviceProfileErrorMapper.fromThrowable(
            DeviceProfileErrorCodes.COLLECT,
            RuntimeException(),
        )

        assertEquals(error.message, RuntimeException().toString().let { error.message })
        assertEquals("unknown", error.details)
    }

    @Test
    fun `fromThrowable returns an existing FlutterError unchanged`() {
        val original = FlutterError(DeviceProfileErrorCodes.COLLECT, "already mapped", "state")

        assertSame(original, DeviceProfileErrorMapper.fromThrowable(DeviceProfileErrorCodes.COLLECT, original))
    }

    @Test
    fun `classifyError wraps a failure's exception as a classified FlutterError`() {
        val result = Result.failure<Unit>(IllegalArgumentException("bad"))

        val classified = result.classifyError(DeviceProfileErrorCodes.COLLECT)

        val error = classified.exceptionOrNull() as FlutterError
        assertEquals(DeviceProfileErrorCodes.COLLECT, error.code)
        assertEquals("argument", error.details)
    }

    @Test
    fun `classifyError returns the original Result on success`() {
        val result = Result.success(Unit)

        assertEquals(result, result.classifyError(DeviceProfileErrorCodes.COLLECT))
    }
}
