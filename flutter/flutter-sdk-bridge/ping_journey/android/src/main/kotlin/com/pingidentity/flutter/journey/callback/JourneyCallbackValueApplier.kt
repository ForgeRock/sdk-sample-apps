/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.journey.callback

import com.pingidentity.flutter.journey.CallbackValueMessage
import com.pingidentity.journey.callback.BooleanAttributeInputCallback
import com.pingidentity.journey.callback.ChoiceCallback
import com.pingidentity.journey.callback.KbaCreateCallback
import com.pingidentity.journey.callback.NameCallback
import com.pingidentity.journey.callback.NumberAttributeInputCallback
import com.pingidentity.journey.callback.PasswordCallback
import com.pingidentity.journey.callback.StringAttributeInputCallback
import com.pingidentity.journey.callback.TermsAndConditionsCallback
import com.pingidentity.journey.callback.TextInputCallback
import com.pingidentity.journey.callback.ValidatedPasswordCallback
import com.pingidentity.journey.callback.ValidatedUsernameCallback
import com.pingidentity.journey.plugin.AbstractCallback
import com.pingidentity.journey.plugin.Callback
import com.pingidentity.journey.plugin.callbacks
import com.pingidentity.orchestrate.ContinueNode
import kotlinx.serialization.json.jsonPrimitive

/**
 * Applies Dart-submitted [CallbackValueMessage]s back onto a cached native [ContinueNode]'s live
 * callbacks, addressed by `{type, index}`. Trimmed to the v1 callback set (no
 * integration-gated/output-only mutation attempts to reject — the Dart side never submits a
 * value for [com.pingidentity.journey.callback.TextOutputCallback], and no v1 type requires
 * additional native integration).
 */
internal object JourneyCallbackValueApplier {
    fun apply(node: ContinueNode, values: List<CallbackValueMessage>) {
        val callbacksByType = node.callbacks.groupBy(::callbackType)
        for (value in values) {
            val callback =
                callbacksByType[value.type]?.getOrNull(value.index.toInt())
                    ?: throw IllegalArgumentException(
                        "No active callback found for type ${value.type} at index ${value.index}"
                    )
            applyValue(callback, value)
        }
    }

    /**
     * The server-registered `"type"` string from [AbstractCallback.json], stable across R8/proguard
     * minification — unlike [Any.javaClass]'s `simpleName`, which is obfuscated in a minified build.
     */
    private fun callbackType(callback: Callback): String =
        (callback as AbstractCallback).json["type"]?.jsonPrimitive?.content
            ?: throw IllegalStateException("Callback is missing a \"type\" field: $callback")

    private fun applyValue(callback: Callback, value: CallbackValueMessage) {
        when (callback) {
            is NameCallback -> callback.name = asString(value)
            is PasswordCallback -> callback.password = asString(value)
            is ValidatedUsernameCallback -> callback.username = asString(value)
            is ValidatedPasswordCallback -> callback.password = asString(value)
            is TextInputCallback -> callback.text = asString(value)
            is StringAttributeInputCallback -> callback.value = asString(value)
            is NumberAttributeInputCallback -> callback.value = asDouble(value)
            is BooleanAttributeInputCallback -> callback.value = asBoolean(value)
            is ChoiceCallback -> callback.selectedIndex = asInt(value)
            is TermsAndConditionsCallback -> callback.accepted = asBoolean(value)
            is KbaCreateCallback -> applyKba(callback, value)
            else ->
                throw UnsupportedOperationException(
                    "Callback type ${value.type} is not supported for value mutation"
                )
        }
    }

    private fun applyKba(callback: KbaCreateCallback, value: CallbackValueMessage) {
        val map = asMap(value)
        callback.selectedQuestion =
            map["selectedQuestion"] as? String
                ?: throw IllegalArgumentException("${value.type} expects a String selectedQuestion")
        callback.selectedAnswer =
            map["selectedAnswer"] as? String
                ?: throw IllegalArgumentException("${value.type} expects a String selectedAnswer")
        callback.allowUserDefinedQuestions =
            map["allowUserDefinedQuestions"] as? Boolean
                ?: throw IllegalArgumentException(
                    "${value.type} expects a Boolean allowUserDefinedQuestions"
                )
    }

    private fun asString(value: CallbackValueMessage): String =
        value.value as? String
            ?: throw IllegalArgumentException("${value.type} expects a String value")

    private fun asBoolean(value: CallbackValueMessage): Boolean =
        value.value as? Boolean
            ?: throw IllegalArgumentException("${value.type} expects a Boolean value")

    private fun asInt(value: CallbackValueMessage): Int =
        (value.value as? Number)?.toInt()
            ?: throw IllegalArgumentException("${value.type} expects a numeric value")

    private fun asDouble(value: CallbackValueMessage): Double =
        (value.value as? Number)?.toDouble()
            ?: throw IllegalArgumentException("${value.type} expects a numeric value")

    @Suppress("UNCHECKED_CAST")
    private fun asMap(value: CallbackValueMessage): Map<String, Any?> =
        value.value as? Map<String, Any?>
            ?: throw IllegalArgumentException("${value.type} expects an object value")
}
