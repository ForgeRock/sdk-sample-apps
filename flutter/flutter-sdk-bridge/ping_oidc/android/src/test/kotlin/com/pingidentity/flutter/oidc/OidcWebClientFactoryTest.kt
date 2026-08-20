/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.oidc

import kotlin.test.Test
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

/** Unit tests for [OidcWebClientFactory]'s handle-resolution validation. */
class OidcWebClientFactoryTest {

    @Test
    fun `create throws IllegalStateException for an unknown client handle id`() {
        val error =
            assertFailsWith<IllegalStateException> {
                OidcWebClientFactory.create("unknown-id", options = null)
            }

        assertTrue(error.message?.contains("unknown-id") == true)
    }
}
