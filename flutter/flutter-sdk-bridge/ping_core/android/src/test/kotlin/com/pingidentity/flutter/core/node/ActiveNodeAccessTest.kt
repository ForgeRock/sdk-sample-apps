/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.core.node

import com.pingidentity.flutter.core.registry.NativeHandle
import com.pingidentity.flutter.core.registry.SimpleRegistry
import kotlin.test.Test
import kotlin.test.assertFailsWith
import kotlin.test.assertSame
import kotlin.test.assertTrue

/** Unit tests for [requireActiveNode]: the resolve-and-cast lookup every add-on will use. */
class ActiveNodeAccessTest {

    private class FakeAccess : ActiveNodeAccess {
        override suspend fun <T> withItem(
            type: String,
            index: Int,
            block: suspend (item: Any) -> T,
        ): T = block(Any())
    }

    private class PlainHandle : NativeHandle

    @Test
    fun `requireActiveNode returns a registered handle that supports item access`() {
        val registry = SimpleRegistry()
        val handle = FakeAccess()
        val id = registry.register(handle)

        assertSame(handle, registry.requireActiveNode(id))
    }

    @Test
    fun `requireActiveNode throws for an unknown id and names it`() {
        val error =
            assertFailsWith<IllegalStateException> {
                SimpleRegistry().requireActiveNode("missing")
            }

        assertTrue("missing" in error.message.orEmpty())
    }

    @Test
    fun `requireActiveNode throws for a handle without item access`() {
        val registry = SimpleRegistry()
        val id = registry.register(PlainHandle())

        assertFailsWith<IllegalStateException> { registry.requireActiveNode(id) }
    }
}
