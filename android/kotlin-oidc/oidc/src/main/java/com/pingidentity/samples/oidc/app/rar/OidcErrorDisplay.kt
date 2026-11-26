/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.oidc.app.rar

import com.pingidentity.browser.BrowserCanceledException

/**
 * A message for showing an authorization failure to the user.
 *
 * The raw exception message of an OAuth error redirect is the SDK's
 * "The authorization server returned an error: <code> — <description> (see <error_uri>)".
 * This maps the outcomes a Rich Authorization Requests (RFC 9396) flow commonly ends in to
 * plain language:
 * - `access_denied`: the user declined consent.
 * - `invalid_authorization_details`: the server rejected the `authorization_details`, so the
 *   types allowed on the OAuth client need checking.
 * - `invalid_request`: the server rejected the request, as an OAuth client with Implied
 *   Consent enabled does for `authorization_details`.
 * - Any other OAuth error: the error code.
 * - `BrowserCanceledException`: the user dismissed the sign-in browser.
 *
 * Every other error falls back to the exception's message or `toString()`.
 */
fun Throwable.displayMessage(): String {
    // The user dismissed the sign-in browser.
    if (this is BrowserCanceledException) {
        return "Sign-in was cancelled before it completed."
    }

    // The SDK surfaces an OAuth error redirect (RFC 6749 §4.1.2.1) as an
    // AuthorizeException whose message is built by extractOAuthError.
    val prefix = "The authorization server returned an error: "
    val message = message.orEmpty()
    if (!message.startsWith(prefix)) {
        return message.ifBlank { toString() }
    }

    val rest = message.removePrefix(prefix)
    val code = rest.substringBefore(" — ").substringBefore(" (see ").trim()
    val description = rest.substringAfter(" — ", "").substringBefore(" (see ").trim()
    val errorUri = rest.substringAfter(" (see ", "").removeSuffix(")").trim()

    val headline = when (code) {
        "access_denied" ->
            "Consent was denied. The user declined the authorization request."
        "invalid_authorization_details" ->
            "The server rejected the authorization_details. Check the Authorization Detail " +
                "Type(s) allowed on the OAuth client."
        "invalid_request" -> {
            // The server's description usually names Implied Consent; the note is only added
            // when it does not, so the hint is not shown twice.
            if (description.contains("implied", ignoreCase = true)) {
                "The server rejected the authorization request."
            } else {
                "The server rejected the authorization request. A client with Implied Consent " +
                    "enabled rejects authorization_details."
            }
        }
        else -> "Authorization failed: $code"
    }

    return listOf(headline, description.ifEmpty { null }, errorUri.ifEmpty { null })
        .filterNotNull()
        .joinToString("\n")
}
