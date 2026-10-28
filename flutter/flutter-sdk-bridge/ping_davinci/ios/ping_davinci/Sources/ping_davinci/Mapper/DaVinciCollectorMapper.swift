/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingDavinci
import PingDavinciPlugin

/// Maps native collectors to `CollectorMessage`s: the fields every collector shares, its current
/// value, and the per-class fields of each of the sixteen core classes. Switches on the concrete class,
/// never on the `type` string — `PASSWORD`/`PASSWORD_VERIFY` share a class, and `ACTION` (plus the
/// iOS-only `FLOW_BUTTON`/`FLOW_LINK` aliases) is `FlowCollector`. The class is reported as
/// `CollectorMessage.kind`.
///
/// `CollectorMessage.index` is the collector's position in `ContinueNode.collectors`, and together
/// with `collectorType(_:)` it is how `next()` finds the collector again.
///
/// Values that the two SDKs default differently are normalized so both platforms send the same
/// message: an empty rich-content `href`/`target`, an empty polling `challenge` and an empty
/// device `title`/`description`/`iconSrc` become `nil`, a device's missing `default` becomes
/// `false`, and a password-policy bound left at the SDK's "unbounded" default (`Int.max` here,
/// `Int.MAX_VALUE` on Android) becomes `nil`.
/// Mirrors the Android mapper.
enum DaVinciCollectorMapper {
    static func map(_ collectors: [any Collector]) -> [CollectorMessage] {
        collectors.enumerated().map { index, collector in map(collector, index: Int64(index)) }
    }

    private static func map(_ collector: any Collector, index: Int64) -> CollectorMessage {
        let field = fieldInfo(collector)
        var message = CollectorMessage(
            type: collectorType(collector),
            kind: kind(collector),
            index: index,
            id: collector.id,
            key: field?.key ?? displayKey(collector),
            label: field?.label,
            required: field?.required,
            value: value(collector)
        )
        if let validated = collector as? ValidatedCollector,
           let pattern = validated.validation?.regex?.pattern, !pattern.isEmpty {
            message.validationRegex = pattern
            message.validationErrorMessage = validated.validation?.errorMessage
        }
        switch collector {
        case let password as PasswordCollector:
            message.passwordPolicy = password.passwordPolicy().map(passwordPolicy)
        case let single as SingleSelectCollector:
            message.options = options(single.options)
        case let multi as MultiSelectCollector:
            message.options = options(multi.options)
        case let boolean as BooleanCollector:
            message.appearance = boolean.appearance.rawValue
            message.errorMessage = boolean.errorMessage
            message.richContent = boolean.richContent.map(richContent)
        case let phone as PhoneNumberCollector:
            message.defaultCountryCode = phone.defaultCountryCode
            message.validatePhoneNumber = phone.validatePhoneNumber
            message.showExtension = phone.showExtension
            message.extensionLabel = phone.extensionLabel
            message.countryCode = phone.countryCode
            message.phoneNumber = phone.phoneNumber
            message.phoneExtension = phone.extension
        case let label as LabelCollector:
            message.content = label.content
            message.richContent = label.richContent.map(richContent)
        case let readOnly as ReadOnlyTextCollector:
            message.content = readOnly.content
            message.title = readOnly.title
            message.titleEnabled = readOnly.titleEnabled
            message.enabled = readOnly.enabled
            message.agreementId = readOnly.agreementId
            message.useDynamicAgreement = readOnly.useDynamicAgreement
        case let image as ImageCollector:
            message.imageUrl = image.imageUrl
            message.imageDescription = image.description
            message.hyperlinkUrl = image.hyperlinkUrl
        // The data URI itself (2.2.0, SDKS-5299), never the decoded `imageData`: Dart decodes it.
        case let qrCode as QRCodeCollector:
            message.content = qrCode.content
            message.fallbackText = qrCode.fallbackText
        case let polling as PollingCollector:
            message.pollIntervalMillis = Int64(polling.pollInterval)
            message.pollRetries = Int64(polling.pollRetries)
            message.retriesAllowed = Int64(polling.retriesAllowed)
            message.pollChallengeStatus = polling.pollChallengeStatus
            message.challenge = nonEmpty(polling.challenge)
        case let registration as DeviceRegistrationCollector:
            message.devices = devices(registration.devices)
        case let authentication as DeviceAuthenticationCollector:
            message.devices = devices(authentication.devices)
        case let metadata as MetadataCollector:
            // `JSONSerialization` output (strings, numbers, `NSNull`, arrays, dictionaries), which
            // the standard codec carries as is.
            message.metadata = Dictionary(uniqueKeysWithValues: metadata.metadata.map { ($0.key as String?, $0.value as Any?) })
        default:
            break
        }
        return message
    }

    /// The type a collector is addressed by: the server's field `type` (e.g. `DROPDOWN`, which the
    /// factory resolved via its `inputType` `SINGLE_SELECT`), or the registry key for the display
    /// collectors that carry none.
    static func collectorType(_ collector: any Collector) -> String {
        let type: String
        if let field = fieldInfo(collector) {
            type = field.type
        } else {
            switch collector {
            case let readOnly as ReadOnlyTextCollector: type = readOnly.type
            case let metadata as MetadataCollector: type = metadata.type
            case is LabelCollector: type = "LABEL"
            case is QRCodeCollector: type = "QR_CODE"
            case is ImageCollector: type = "IMAGE"
            default: type = ""
            }
        }
        return type.isEmpty ? String(describing: Swift.type(of: collector)) : type
    }

    /// The stable name of `collector`'s class, which picks the Dart subtype. Subclasses before
    /// their bases: `PollingCollector`, `SubmitCollector` and `FlowCollector` all extend
    /// `SingleValueCollector`. A class the bridge doesn't know reports its own name.
    private static func kind(_ collector: any Collector) -> String {
        switch collector {
        case is TextCollector: return "text"
        case is PasswordCollector: return "password"
        case is SingleSelectCollector: return "singleSelect"
        case is SubmitCollector: return "submit"
        case is FlowCollector: return "flow"
        case is PollingCollector: return "polling"
        case is MultiSelectCollector: return "multiSelect"
        case is BooleanCollector: return "boolean"
        case is PhoneNumberCollector: return "phoneNumber"
        case is LabelCollector: return "label"
        case is ReadOnlyTextCollector: return "readOnlyText"
        case is ImageCollector: return "image"
        case is QRCodeCollector: return "qrCode"
        case is DeviceRegistrationCollector: return "deviceRegistration"
        case is DeviceAuthenticationCollector: return "deviceAuthentication"
        case is MetadataCollector: return "metadata"
        default: return String(describing: Swift.type(of: collector))
        }
    }

    /// `FieldCollector<T>` is generic and `AnyFieldCollector` doesn't expose these, so each
    /// specialization the SDK uses is tried in turn.
    private static func fieldInfo(_ collector: any Collector) -> (type: String, key: String, label: String, required: Bool)? {
        if let field = collector as? FieldCollector<String> { return (field.type, field.key, field.label, field.required) }
        if let field = collector as? FieldCollector<Bool> { return (field.type, field.key, field.label, field.required) }
        if let field = collector as? FieldCollector<[String]> { return (field.type, field.key, field.label, field.required) }
        if let field = collector as? FieldCollector<[String: Any]> { return (field.type, field.key, field.label, field.required) }
        return nil
    }

    /// Display collectors carry a key but aren't `FieldCollector`s.
    private static func displayKey(_ collector: any Collector) -> String? {
        switch collector {
        case let label as LabelCollector: return label.key
        case let readOnly as ReadOnlyTextCollector: return readOnly.key
        case let image as ImageCollector: return image.key
        case let qrCode as QRCodeCollector: return qrCode.key
        case let metadata as MetadataCollector: return metadata.key
        default: return nil
        }
    }

    /// The current value, in the type `next()` accepts back. Passwords are never sent to Dart, and
    /// polling has no app-supplied value. A phone number travels in its three own fields; a
    /// device or metadata collector has no value until the app picks a device or sets a result.
    private static func value(_ collector: any Collector) -> Any? {
        switch collector {
        case is PasswordCollector, is PollingCollector: return nil
        case let single as SingleValueCollector: return single.value
        case let boolean as BooleanCollector: return boolean.value
        case let multi as MultiSelectCollector: return multi.value
        default: return nil
        }
    }

    private static func devices(_ devices: [Device]) -> [DeviceMessage?] {
        devices.map {
            DeviceMessage(
                id: $0.id,
                type: $0.type,
                title: nonEmpty($0.title),
                deviceDescription: nonEmpty($0.description),
                iconSrc: nonEmpty($0.iconSrc.absoluteString),
                isDefault: $0.isDefault ?? false
            )
        }
    }

    private static func options(_ options: [Option]) -> [OptionMessage?] {
        options.map { OptionMessage(label: $0.label, value: $0.value) }
    }

    private static func passwordPolicy(_ policy: PasswordPolicy) -> PasswordPolicyMessage {
        PasswordPolicyMessage(
            lengthMin: Int64(policy.length.min),
            lengthMax: bounded(policy.length.max),
            minUniqueCharacters: Int64(policy.minUniqueCharacters),
            maxRepeatedCharacters: bounded(policy.maxRepeatedCharacters),
            minCharacters: policy.minCharacters.reduce(into: [String?: Int64?]()) { $0[$1.key] = Int64($1.value) }
        )
    }

    private static func bounded(_ value: Int) -> Int64? {
        value == Int.max ? nil : Int64(value)
    }

    /// Replacements keep their `{{key}}`, sorted so both platforms send the same order.
    private static func richContent(_ richContent: RichContent) -> RichContentMessage {
        RichContentMessage(
            content: richContent.content,
            replacements: richContent.replacements.sorted { $0.key < $1.key }.map { key, replacement in
                RichContentReplacementMessage(
                    key: key,
                    value: replacement.value,
                    href: nonEmpty(replacement.href),
                    type: replacement.type,
                    target: nonEmpty(replacement.target)
                )
            }
        )
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }
}
