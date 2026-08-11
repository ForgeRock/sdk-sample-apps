/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.oidc

import com.pingidentity.flutter.oidc.error.OidcErrorCodes
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.runBlocking

/**
 * Unit tests for [OidcHostApiImpl]'s Phase 4 methods.
 *
 * `OidcWebClient` is a concrete native class (not an interface), so there's no seam here to inject
 * a fake `User` in place of a real one — these tests cover only the "no session" failure path,
 * which is reachable via the real (empty) registry with no native scaffolding required. Full
 * method-body coverage against a real signed-in session is exercised at the runtime verification
 * gate instead (see IMPLEMENTATION_PLAN_OIDC.md Phase 4).
 */
class OidcHostApiImplTest {
    private val impl = OidcHostApiImpl()

    // Each real method dispatches its callback via `scope.launch` on a separate `Dispatchers.IO`
    // coroutine, so the callback fires on a different thread than the test's `runBlocking` — these
    // helpers bridge that with a `CompletableDeferred` rather than assuming synchronous completion.

    private suspend fun awaitToken(webClientId: String): Result<TokenMessage> {
        val deferred = CompletableDeferred<Result<TokenMessage>>()
        impl.token(webClientId) { deferred.complete(it) }
        return deferred.await()
    }

    private suspend fun awaitRefresh(webClientId: String): Result<TokenMessage> {
        val deferred = CompletableDeferred<Result<TokenMessage>>()
        impl.refresh(webClientId) { deferred.complete(it) }
        return deferred.await()
    }

    private suspend fun awaitUserInfo(webClientId: String): Result<Map<String?, Any?>> {
        val deferred = CompletableDeferred<Result<Map<String?, Any?>>>()
        impl.userInfo(webClientId, cache = false) { deferred.complete(it) }
        return deferred.await()
    }

    private suspend fun awaitRevoke(webClientId: String): Result<Unit> {
        val deferred = CompletableDeferred<Result<Unit>>()
        impl.revoke(webClientId) { deferred.complete(it) }
        return deferred.await()
    }

    private suspend fun awaitSignOff(webClientId: String): Result<Boolean> {
        val deferred = CompletableDeferred<Result<Boolean>>()
        impl.signOff(webClientId) { deferred.complete(it) }
        return deferred.await()
    }

    @Test
    fun `token surfaces a typed error for an unknown web client id`() = runBlocking {
        val error = awaitToken("unknown-id").exceptionOrNull()
        check(error is FlutterError)
        assertEquals(OidcErrorCodes.TOKEN, error.code)
    }

    @Test
    fun `refresh surfaces a typed error for an unknown web client id`() = runBlocking {
        val error = awaitRefresh("unknown-id").exceptionOrNull()
        check(error is FlutterError)
        assertEquals(OidcErrorCodes.REFRESH, error.code)
    }

    @Test
    fun `userInfo surfaces a typed error for an unknown web client id`() = runBlocking {
        val error = awaitUserInfo("unknown-id").exceptionOrNull()
        check(error is FlutterError)
        assertEquals(OidcErrorCodes.USERINFO, error.code)
    }

    @Test
    fun `revoke surfaces a typed error for an unknown web client id`() = runBlocking {
        val error = awaitRevoke("unknown-id").exceptionOrNull()
        check(error is FlutterError)
        assertEquals(OidcErrorCodes.REVOKE, error.code)
    }

    @Test
    fun `signOff surfaces a typed error for an unknown web client id`() = runBlocking {
        val error = awaitSignOff("unknown-id").exceptionOrNull()
        check(error is FlutterError)
        assertEquals(OidcErrorCodes.SIGN_OFF, error.code)
    }

    @Test
    fun `the missing session is classified as state and names the id`() = runBlocking {
        val error = awaitToken("unknown-id").exceptionOrNull()
        check(error is FlutterError)
        assertEquals("state", error.details)
        assertTrue(error.message?.contains("unknown-id") == true)
    }
}
