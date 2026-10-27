/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci.mapper

import com.pingidentity.davinci.collector.InvalidLength
import com.pingidentity.davinci.collector.MaxRepeat
import com.pingidentity.davinci.collector.MinCharacters
import com.pingidentity.davinci.collector.RegexError
import com.pingidentity.davinci.collector.Required
import com.pingidentity.davinci.collector.UniqueCharacter
import com.pingidentity.davinci.collector.ValidationError
import com.pingidentity.davinci.collector.Validator
import com.pingidentity.davinci.plugin.Collector
import com.pingidentity.flutter.davinci.ValidationErrorKind
import com.pingidentity.flutter.davinci.ValidationErrorMessage

/**
 * Runs the SDK's own local validation and maps each [ValidationError] structurally: the kind and
 * its parameters, never a rendered message, so Dart can localize it. An unbounded `max`
 * (`Int.MAX_VALUE`, the SDK's password-policy default) becomes `null`, as in
 * [DaVinciCollectorMapper]. Mirrors the iOS mapper; where the two SDKs' validators disagree, the
 * disagreement is passed through, not corrected (see the iOS mapper for the known cases, filed as
 * SDKS-5537, SDKS-5538 and SDKS-5539).
 */
internal object DaVinciValidationMapper {
    /**
     * `validate()` on every [Validator] among [collectors], in collector order, each error
     * addressed by the collector's `{type, index}`. Collectors that don't validate (labels,
     * images) contribute nothing.
     */
    fun validate(collectors: List<Collector<*>>): List<ValidationErrorMessage> =
        collectors.flatMapIndexed { index, collector ->
            val validator = collector as? Validator ?: return@flatMapIndexed emptyList()
            val type = collectorType(collector)
            validator.validate().map { map(it, type, index) }
        }

    fun map(error: ValidationError, type: String, index: Int): ValidationErrorMessage {
        val message = ValidationErrorMessage(type, index.toLong(), ValidationErrorKind.REQUIRED)
        return when (error) {
            Required -> message
            is RegexError -> message.copy(kind = ValidationErrorKind.REGEX, message = error.message)
            is InvalidLength ->
                message.copy(
                    kind = ValidationErrorKind.INVALID_LENGTH,
                    min = error.min.toLong(),
                    max = error.max.bounded(),
                )
            is UniqueCharacter ->
                message.copy(kind = ValidationErrorKind.UNIQUE_CHARACTER, min = error.min.toLong())
            is MaxRepeat -> message.copy(kind = ValidationErrorKind.MAX_REPEAT, max = error.max.bounded())
            is MinCharacters ->
                message.copy(
                    kind = ValidationErrorKind.MIN_CHARACTERS,
                    min = error.min.toLong(),
                    character = error.character,
                )
        }
    }

    private fun Int.bounded(): Long? = if (this == Int.MAX_VALUE) null else toLong()
}
