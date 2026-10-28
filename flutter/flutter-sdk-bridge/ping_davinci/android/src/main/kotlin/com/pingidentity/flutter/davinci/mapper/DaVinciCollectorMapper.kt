/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci.mapper

import com.pingidentity.davinci.RichContent
import com.pingidentity.davinci.collector.BooleanCollector
import com.pingidentity.davinci.collector.Device
import com.pingidentity.davinci.collector.DeviceAuthenticationCollector
import com.pingidentity.davinci.collector.DeviceRegistrationCollector
import com.pingidentity.davinci.collector.FieldCollector
import com.pingidentity.davinci.collector.FlowCollector
import com.pingidentity.davinci.collector.ImageCollector
import com.pingidentity.davinci.collector.LabelCollector
import com.pingidentity.davinci.collector.MetadataCollector
import com.pingidentity.davinci.collector.MultiSelectCollector
import com.pingidentity.davinci.collector.Option
import com.pingidentity.davinci.collector.PasswordCollector
import com.pingidentity.davinci.collector.PhoneNumberCollector
import com.pingidentity.davinci.collector.PollingCollector
import com.pingidentity.davinci.collector.QRCodeCollector
import com.pingidentity.davinci.collector.ReadOnlyTextCollector
import com.pingidentity.davinci.collector.SingleSelectCollector
import com.pingidentity.davinci.collector.SingleValueCollector
import com.pingidentity.davinci.collector.SubmitCollector
import com.pingidentity.davinci.collector.TextCollector
import com.pingidentity.davinci.collector.ValidatedCollector
import com.pingidentity.davinci.plugin.Collector
import com.pingidentity.flutter.core.mapper.JsonBridgeMapper
import com.pingidentity.flutter.davinci.CollectorMessage
import com.pingidentity.flutter.davinci.DeviceMessage
import com.pingidentity.flutter.davinci.OptionMessage
import com.pingidentity.flutter.davinci.PasswordPolicyMessage
import com.pingidentity.flutter.davinci.RichContentMessage
import com.pingidentity.flutter.davinci.RichContentReplacementMessage
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/**
 * Maps native collectors to [CollectorMessage]s: the fields every collector shares, its current
 * value, and the per-class fields of each of the sixteen core classes. Switches on the concrete class,
 * never on the `type` string — `PASSWORD`/`PASSWORD_VERIFY` share a class, and `ACTION` is
 * [FlowCollector]. The class is reported as [CollectorMessage.kind].
 *
 * [CollectorMessage.index] is the collector's position in `ContinueNode.collectors`, and together
 * with [collectorType] it is how `next()` finds the collector again.
 *
 * Values that the two SDKs default differently are normalized so both platforms send the same
 * message: an empty validation regex, empty rich-content `href`/`target`, an empty polling
 * `challenge` and empty device `title`/`description`/`iconSrc` become `null`, and a
 * password-policy bound left at the SDK's "unbounded" default (`Int.MAX_VALUE` here, `Int.max` on
 * iOS) becomes `null`.
 */
internal object DaVinciCollectorMapper {
    /**
     * [input] is the node's raw JSON, used only to repair a value the SDK loses: see
     * [phoneExtensionLabel].
     */
    fun map(collectors: List<Collector<*>>, input: JsonObject? = null): List<CollectorMessage> =
        collectors.mapIndexed { index, collector -> map(collector, index.toLong(), input) }

    private fun map(collector: Collector<*>, index: Long, input: JsonObject?): CollectorMessage {
        val field = collector as? FieldCollector<*>
        val validation = (collector as? ValidatedCollector)?.validation
        val regex = validation?.regex?.pattern?.ifEmpty { null }
        val base =
            CollectorMessage(
                type = collectorType(collector),
                index = index,
                kind = kind(collector),
                id = collector.id(),
                key = field?.key ?: displayKey(collector),
                label = field?.label,
                required = field?.required,
                value = value(collector),
                validationRegex = regex,
                validationErrorMessage = validation?.errorMessage?.takeIf { regex != null },
            )
        return when (collector) {
            is PasswordCollector -> base.copy(passwordPolicy = passwordPolicy(collector))
            is SingleSelectCollector -> base.copy(options = options(collector.options))
            is MultiSelectCollector -> base.copy(options = options(collector.options))
            is BooleanCollector ->
                base.copy(
                    appearance = collector.appearance.value,
                    errorMessage = collector.errorMessage,
                    richContent = collector.richContent?.let(::richContent),
                )
            is PhoneNumberCollector ->
                base.copy(
                    defaultCountryCode = collector.defaultCountryCode,
                    validatePhoneNumber = collector.validatePhoneNumber,
                    showExtension = collector.showExtension,
                    extensionLabel = phoneExtensionLabel(collector, input),
                    countryCode = collector.countryCode,
                    phoneNumber = collector.phoneNumber,
                    phoneExtension = collector.extension,
                )
            is LabelCollector ->
                base.copy(
                    content = collector.content,
                    richContent = collector.richContent?.let(::richContent),
                )
            is ReadOnlyTextCollector ->
                base.copy(
                    content = collector.content,
                    title = collector.title,
                    titleEnabled = collector.titleEnabled,
                    enabled = collector.enabled,
                    agreementId = collector.agreementId,
                    useDynamicAgreement = collector.useDynamicAgreement,
                )
            is ImageCollector ->
                base.copy(
                    imageUrl = collector.imageUrl,
                    imageDescription = collector.description,
                    hyperlinkUrl = collector.hyperlinkUrl,
                )
            // The data URI itself, never the decoded Bitmap: Dart decodes it.
            is QRCodeCollector ->
                base.copy(content = collector.content, fallbackText = collector.fallbackText)
            // Android keeps the interval and retries as the server's strings; iOS parses them.
            is PollingCollector ->
                base.copy(
                    pollIntervalMillis = collector.pollInterval.toLongOrNull(),
                    pollRetries = collector.pollRetries.toLongOrNull(),
                    retriesAllowed = collector.retriesAllowed.toLong(),
                    pollChallengeStatus = collector.pollChallengeStatus,
                    challenge = collector.challenge.ifEmpty { null },
                )
            is DeviceRegistrationCollector -> base.copy(devices = devices(collector.devices))
            is DeviceAuthenticationCollector -> base.copy(devices = devices(collector.devices))
            is MetadataCollector -> base.copy(metadata = jsonMap(collector.metadata))
            else -> base
        }
    }

    /**
     * The stable name of [collector]'s class, which picks the Dart subtype. Subclasses before
     * their bases: [PollingCollector], [SubmitCollector] and [FlowCollector] all extend
     * [SingleValueCollector]. A class the bridge doesn't know reports its own name.
     */
    private fun kind(collector: Collector<*>): String =
        when (collector) {
            is TextCollector -> "text"
            is PasswordCollector -> "password"
            is SingleSelectCollector -> "singleSelect"
            is SubmitCollector -> "submit"
            is FlowCollector -> "flow"
            is PollingCollector -> "polling"
            is MultiSelectCollector -> "multiSelect"
            is BooleanCollector -> "boolean"
            is PhoneNumberCollector -> "phoneNumber"
            is LabelCollector -> "label"
            is ReadOnlyTextCollector -> "readOnlyText"
            is ImageCollector -> "image"
            is QRCodeCollector -> "qrCode"
            is DeviceRegistrationCollector -> "deviceRegistration"
            is DeviceAuthenticationCollector -> "deviceAuthentication"
            is MetadataCollector -> "metadata"
            else -> collector::class.simpleName ?: "unknown"
        }

    /** Display collectors carry a key but aren't [FieldCollector]s. */
    private fun displayKey(collector: Collector<*>): String? =
        when (collector) {
            is LabelCollector -> collector.key
            is ReadOnlyTextCollector -> collector.key
            is ImageCollector -> collector.key
            is QRCodeCollector -> collector.key
            else -> null
        }

    /**
     * The current value, in the type `next()` accepts back. Passwords are never sent to Dart, and
     * polling has no app-supplied value. A phone number travels in its three own fields; a
     * device or metadata collector has no value until the app picks a device or sets a result.
     */
    private fun value(collector: Collector<*>): Any? =
        when (collector) {
            is PasswordCollector, is PollingCollector -> null
            is SingleValueCollector -> collector.value
            is BooleanCollector -> collector.value
            is MultiSelectCollector -> collector.value.toList()
            else -> null
        }

    /**
     * ping-android-sdk 2.2.0 bug (SDKS-5073): `PhoneNumberCollector.init(JsonElement)`, which
     * applies the `formData` default, also overwrites `extensionLabel` from that value, where it
     * is never present, so any prefilled phone field loses its label. iOS keeps it. The field's
     * own `extensionLabel` is read back from [input] when the collector's is empty.
     */
    // TODO(SDKS-5073): use collector.extensionLabel directly once the SDK stops overwriting it.
    private fun phoneExtensionLabel(collector: PhoneNumberCollector, input: JsonObject?): String {
        if (collector.extensionLabel.isNotEmpty() || input == null) return collector.extensionLabel
        val form = input["form"] as? JsonObject
        val fields = (form?.get("components") as? JsonObject)?.get("fields") as? JsonArray
        val field =
            fields?.firstNotNullOfOrNull { element ->
                (element as? JsonObject)?.takeIf { (it["key"] as? JsonPrimitive)?.content == collector.key }
            }
        return (field?.get("extensionLabel") as? JsonPrimitive)?.content ?: collector.extensionLabel
    }

    /** A JSON object always encodes to a map. */
    @Suppress("UNCHECKED_CAST")
    private fun jsonMap(json: JsonObject): Map<String?, Any?> =
        JsonBridgeMapper.encodeJsonElement(json) as Map<String?, Any?>

    private fun devices(devices: List<Device>): List<DeviceMessage?> =
        devices.map {
            DeviceMessage(
                id = it.id,
                type = it.type,
                title = it.title.ifEmpty { null },
                deviceDescription = it.description.ifEmpty { null },
                iconSrc = it.iconSrc.ifEmpty { null },
                isDefault = it.default,
            )
        }

    private fun options(options: List<Option>): List<OptionMessage?> =
        options.map { OptionMessage(label = it.label, value = it.value) }

    /**
     * `passwordPolicy()` falls back to the `ContinueNode`'s input, which needs the node the
     * factory injects. A collector built outside a node has none, so it maps as "no policy".
     */
    private fun passwordPolicy(collector: PasswordCollector): PasswordPolicyMessage? {
        val policy = runCatching { collector.passwordPolicy() }.getOrNull() ?: return null
        return PasswordPolicyMessage(
            lengthMin = policy.length.min.toLong(),
            lengthMax = policy.length.max.bounded(),
            minUniqueCharacters = policy.minUniqueCharacters.toLong(),
            maxRepeatedCharacters = policy.maxRepeatedCharacters.bounded(),
            minCharacters = policy.minCharacters.mapValues { it.value.toLong() },
        )
    }

    private fun Int.bounded(): Long? = if (this == Int.MAX_VALUE) null else toLong()

    /** Replacements keep their `{{key}}`, sorted so both platforms send the same order. */
    private fun richContent(richContent: RichContent): RichContentMessage =
        RichContentMessage(
            content = richContent.content,
            replacements =
                richContent.replacements.toSortedMap().map { (key, replacement) ->
                    RichContentReplacementMessage(
                        key = key,
                        value = replacement.value,
                        href = replacement.href.ifEmpty { null },
                        type = replacement.type,
                        target = replacement.target.ifEmpty { null },
                    )
                },
        )
}

/**
 * The type a collector is addressed by: the server's field `type` (e.g. `DROPDOWN`, which the
 * factory resolved via its `inputType` `SINGLE_SELECT`), or the registry key for the display
 * collectors that carry none.
 */
internal fun collectorType(collector: Collector<*>): String {
    val type =
        when (collector) {
            is FieldCollector<*> -> collector.type
            is ReadOnlyTextCollector -> collector.type
            is LabelCollector -> "LABEL"
            is QRCodeCollector -> "QR_CODE"
            is ImageCollector -> "IMAGE"
            else -> ""
        }
    return type.ifEmpty { collector::class.simpleName ?: "UNKNOWN" }
}
