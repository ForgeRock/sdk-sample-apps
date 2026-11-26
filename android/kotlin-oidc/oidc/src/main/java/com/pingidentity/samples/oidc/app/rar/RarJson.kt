/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.oidc.app.rar

import com.pingidentity.oidc.AuthorizationDetail
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.decodeFromJsonElement
import kotlinx.serialization.json.jsonPrimitive

/**
 * Thrown when the user-entered `authorization_details` text cannot be turned into
 * [AuthorizationDetail] values. The message is phrased for display next to the editor.
 */
class RarDecodeException(message: String) : Exception(message)

/**
 * Parses a user-entered `authorization_details` JSON array (RFC 9396 §2) into the typed
 * values the SDK accepts.
 *
 * The text goes through `Json.parseToJsonElement` and [AuthorizationDetail.serializer] rather
 * than a plain data-class decoder, so type-specific members (for example `instructedAmount`
 * of a `payment_initiation` entry) are carried through [AuthorizationDetail.additionalFields]
 * instead of failing the decode.
 */
object RarJson {

    private val json = Json { ignoreUnknownKeys = true }

    /**
     * Parses [text] as a JSON array of `authorization_details` objects.
     *
     * Fails when the text is not valid JSON, is not an array, is an empty array, or contains
     * an entry that is not an object with a non-empty string `type`.
     *
     * @throws RarDecodeException describing the first problem found.
     */
    fun decode(text: String): List<AuthorizationDetail> {
        val element = try {
            json.parseToJsonElement(text)
        } catch (e: Exception) {
            throw RarDecodeException(
                "Invalid JSON: ${e.message?.lineSequence()?.firstOrNull() ?: "syntax error"}"
            )
        }

        if (element !is JsonArray) {
            throw RarDecodeException(
                "The top-level value must be a JSON array of authorization_details objects."
            )
        }
        if (element.isEmpty()) {
            throw RarDecodeException("At least one authorization_details object is required.")
        }

        return element.map { entry ->
            if (entry !is JsonObject) {
                throw RarDecodeException(
                    "Every authorization_details entry must be a JSON object."
                )
            }
            val type = runCatching { entry["type"]?.jsonPrimitive?.content }.getOrNull()
            if (type.isNullOrEmpty()) {
                throw RarDecodeException(
                    "authorization_details entries require a non-empty 'type' field."
                )
            }
            try {
                json.decodeFromJsonElement(AuthorizationDetail.serializer(), entry)
            } catch (e: Exception) {
                throw RarDecodeException(
                    "Malformed authorization_details entry: ${e.message ?: "unexpected value"}"
                )
            }
        }
    }
}

/**
 * Ready-made `authorization_details` payloads offered as starting points in the editor.
 */
enum class RarPreset(val label: String, val json: String) {
    PAYMENT_INITIATION(
        "payment_initiation",
        """
        [
          {
            "type": "payment_initiation",
            "locations": ["https://example.com/payments"],
            "instructedAmount": {"currency": "EUR", "amount": "123.50"},
            "creditorName": "Merchant A",
            "creditorAccount": {"iban": "DE02100100109307118603"},
            "remittanceInformationUnstructured": "Ref Number Merchant"
          }
        ]
        """.trimIndent(),
    ),
    ACCOUNT_INFORMATION(
        "account_information",
        """
        [
          {
            "type": "account_information",
            "actions": ["list_accounts", "read_balances"],
            "locations": ["https://example.com/accounts"],
            "datatypes": ["balances"]
          }
        ]
        """.trimIndent(),
    ),
    CUSTOM(
        "Custom",
        """
        [
          {
            "type": ""
          }
        ]
        """.trimIndent(),
    ),
}
