/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.deviceprofile

import com.pingidentity.device.profile.DeviceProfileCallback
import com.pingidentity.device.profile.DeviceProfileConfig
import com.pingidentity.flutter.core.CoreRuntime
import com.pingidentity.flutter.core.node.ActiveNodeAccess
import com.pingidentity.flutter.core.registry.NativeHandle
import com.pingidentity.flutter.deviceprofile.error.DeviceProfileErrorCodes
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonArray
import kotlinx.serialization.json.putJsonObject
import org.mockito.kotlin.any
import org.mockito.kotlin.mock
import org.mockito.kotlin.wheneverBlocking

/**
 * Unit tests for [DeviceProfileHostApiImpl.collect]: profile mapping, typed error classification,
 * and that the journey's registry entry is looked up per call.
 */
class DeviceProfileHostApiImplTest {

    private val impl = DeviceProfileHostApiImpl()

    private val registeredIds = mutableListOf<String>()

    @AfterTest
    fun cleanUp() {
        registeredIds.forEach { CoreRuntime.journeyRegistry.remove(it) }
    }

    /** Registers a fake [ActiveNodeAccess] whose block receives [item]; returns its journey id. */
    private fun registerAccessReturning(item: Any?): String {
        val access = object : ActiveNodeAccess {
            override suspend fun <T> withItem(
                type: String,
                index: Int,
                block: suspend (item: Any) -> T,
            ): T = when (item) {
                null -> throw IllegalStateException("No active ContinueNode")
                is Throwable -> throw item
                else -> block(item)
            }
        }
        val id = CoreRuntime.journeyRegistry.register(access)
        registeredIds += id
        return id
    }

    private suspend fun awaitCollect(
        journeyId: String,
        callbackIndex: Long = 0,
    ): Result<Map<String?, Any?>> {
        val deferred = CompletableDeferred<Result<Map<String?, Any?>>>()
        impl.collect(journeyId, callbackIndex) { deferred.complete(it) }
        return deferred.await()
    }

    private fun mockProfileCallback(profileJson: String): DeviceProfileCallback {
        val callback = mock<DeviceProfileCallback>()
        // wheneverBlocking is mockito-kotlin's suspend-aware stubbing: it aligns the matchers
        // across the compiled (lambda, Continuation) signature, which mockito-core can't do.
        wheneverBlocking { callback.collect(any()) }.thenReturn(
            kotlin.Result.success(Json.parseToJsonElement(profileJson).jsonObject)
        )
        return callback
    }

    @Test
    fun `collect returns the profile mapped to plain Dart types`() = runBlocking {
        val callback = mockProfileCallback(
            buildJsonObject {
                put("identifier", "device-123")
                put("metadata", buildJsonObject { put("model", "Pixel 8") })
                putJsonArray("sensors") { add(buildJsonObject { put("name", "gps") }) }
                put("battery", 87)
                put("charging", true)
            }.toString()
        )
        val journeyId = registerAccessReturning(callback)

        val result = awaitCollect(journeyId)

        val profile = result.getOrThrow()
        assertEquals("device-123", profile["identifier"])
        assertEquals("Pixel 8", (profile["metadata"] as Map<*, *>)["model"])
        assertEquals("gps", (profile["sensors"] as List<*>).first().let { (it as Map<*, *>)["name"] })
        assertEquals(87L, profile["battery"])
        assertEquals(true, profile["charging"])
    }

    @Test
    fun `collect addresses the DeviceProfileCallback by type and index`() = runBlocking {
        var requestedType: String? = null
        var requestedIndex: Int? = null
        val callback = mockProfileCallback("""{"identifier":"x"}""")
        val access = object : ActiveNodeAccess {
            @Suppress("UNCHECKED_CAST")
            override suspend fun <T> withItem(
                type: String,
                index: Int,
                block: suspend (item: Any) -> T,
            ): T {
                requestedType = type
                requestedIndex = index
                return block(callback)
            }
        }
        val id = CoreRuntime.journeyRegistry.register(access)
        registeredIds += id

        awaitCollect(id, callbackIndex = 2)

        assertEquals("DeviceProfileCallback", requestedType)
        assertEquals(2, requestedIndex)
    }

    @Test
    fun `collect surfaces a typed state error for an unknown journey id`() = runBlocking {
        val result = awaitCollect("missing-journey")

        val error = result.exceptionOrNull() as FlutterError
        assertEquals(DeviceProfileErrorCodes.COLLECT, error.code)
        assertEquals("state", error.details)
        assertTrue(error.message.orEmpty().contains("missing-journey"))
    }

    @Test
    fun `collect surfaces a typed state error when there is no active node`() = runBlocking {
        val journeyId = registerAccessReturning(null)

        val result = awaitCollect(journeyId)

        assertEquals("state", (result.exceptionOrNull() as FlutterError).details)
    }

    @Test
    fun `collect surfaces a typed state error when the handle has no item access`() = runBlocking {
        val id = CoreRuntime.journeyRegistry.register(PlainHandle())
        registeredIds += id

        val result = awaitCollect(id)

        assertEquals("state", (result.exceptionOrNull() as FlutterError).details)
        assertTrue((result.exceptionOrNull() as FlutterError).message.orEmpty().contains(id))
    }

    @Test
    fun `collect surfaces a typed argument error when the item is not a DeviceProfileCallback`() =
        runBlocking {
            val journeyId = registerAccessReturning(Any())

            val result = awaitCollect(journeyId)

            assertEquals("argument", (result.exceptionOrNull() as FlutterError).details)
        }

    @Test
    fun `collect surfaces a typed permission error when the collection is denied`() = runBlocking {
        val callback = mock<DeviceProfileCallback>()
        wheneverBlocking { callback.collect(any()) }.thenReturn(kotlin.Result.failure(SecurityException("denied")))
        val journeyId = registerAccessReturning(callback)

        val result = awaitCollect(journeyId)

        val error = result.exceptionOrNull() as FlutterError
        assertEquals("permission", error.details)
        assertEquals("denied", error.message)
    }

    @Test
    fun `collect surfaces an unknown error for a non-permission collection failure`() = runBlocking {
        val callback = mock<DeviceProfileCallback>()
        wheneverBlocking { callback.collect(any()) }.thenReturn(kotlin.Result.failure(RuntimeException("boom")))
        val journeyId = registerAccessReturning(callback)

        val result = awaitCollect(journeyId)

        assertEquals("unknown", (result.exceptionOrNull() as FlutterError).details)
    }

    @Test
    fun `collect releases the journey lock when the collection throws`() = runBlocking {
        val callback = mock<DeviceProfileCallback>()
        wheneverBlocking { callback.collect(any()) }.thenReturn(kotlin.Result.failure(RuntimeException("boom")))
        val journeyId = registerAccessReturning(callback)
        awaitCollect(journeyId)

        val second = awaitCollect(journeyId)

        assertEquals("unknown", (second.exceptionOrNull() as FlutterError).details)
    }

    /** A registered handle without item access — the shape of a Journey from before the seam. */
    private class PlainHandle : NativeHandle
}
