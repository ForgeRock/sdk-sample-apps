/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import '../messages.g.dart';
import 'collector.dart';

/// One choice of a single- or multi-select collector.
final class Option {
  /// Creates an option.
  const Option({required this.label, required this.value});

  /// Re-inflates an [OptionMessage].
  Option.fromMessage(OptionMessage message)
    : label = message.label,
      value = message.value;

  /// Display text.
  final String label;

  /// The value submitted when this option is chosen.
  final String value;

  @override
  bool operator ==(Object other) =>
      other is Option && other.label == label && other.value == value;

  @override
  int get hashCode => Object.hash(label, value);

  @override
  String toString() => 'Option($label, $value)';
}

/// A server-supplied regex a text or single-select value must match, with the message to show
/// when it doesn't. The pattern is the server's, unmodified. `DaVinciClient.validate` checks it
/// natively, where the platforms differ for an unanchored pattern: Android needs the whole value
/// to match, iOS only some part of it (see `ValidationError`).
final class Validation {
  /// Creates a validation rule.
  const Validation({required this.regex, required this.errorMessage});

  /// The regex pattern.
  final String regex;

  /// The server's message for a value that doesn't match.
  final String errorMessage;
}

/// The PingOne password policy a [PasswordCollector] enforces, so an app can show the rules
/// before submit. Unbounded limits are `null`.
final class PasswordPolicy {
  /// Creates a password policy.
  const PasswordPolicy({
    this.lengthMin = 0,
    this.lengthMax,
    this.minUniqueCharacters = 0,
    this.maxRepeatedCharacters,
    this.minCharacters = const <String, int>{},
  });

  /// Re-inflates a [PasswordPolicyMessage].
  factory PasswordPolicy.fromMessage(PasswordPolicyMessage message) =>
      PasswordPolicy(
        lengthMin: message.lengthMin ?? 0,
        lengthMax: message.lengthMax,
        minUniqueCharacters: message.minUniqueCharacters ?? 0,
        maxRepeatedCharacters: message.maxRepeatedCharacters,
        minCharacters: <String, int>{
          for (final MapEntry(:key, :value)
              in (message.minCharacters ?? const <String?, int?>{}).entries)
            if (key != null && value != null) key: value,
        },
      );

  /// Minimum length.
  final int lengthMin;

  /// Maximum length, or `null` for none.
  final int? lengthMax;

  /// Minimum number of distinct characters.
  final int minUniqueCharacters;

  /// Maximum number of times one character may repeat, or `null` for no limit.
  final int? maxRepeatedCharacters;

  /// For each character set (keyed by its characters, e.g. `0123456789`), the minimum number of
  /// characters the password must contain from it.
  final Map<String, int> minCharacters;
}

/// A label's text with `{{key}}` placeholders, each standing for a [RichContentReplacement]
/// (typically a link). The bridge passes the structure, not rendered HTML, so the app lays it out
/// with its own widgets.
final class RichContent {
  /// Creates rich content.
  const RichContent({
    required this.content,
    this.replacements = const <String, RichContentReplacement>{},
  });

  /// Re-inflates a [RichContentMessage].
  factory RichContent.fromMessage(RichContentMessage message) => RichContent(
    content: message.content,
    replacements: <String, RichContentReplacement>{
      for (final replacement
          in message.replacements?.whereType<RichContentReplacementMessage>() ??
              const <RichContentReplacementMessage>[])
        replacement.key: RichContentReplacement.fromMessage(replacement),
    },
  );

  /// The text, with `{{key}}` placeholders.
  final String content;

  /// The substitution for each placeholder, keyed by the name between the braces.
  final Map<String, RichContentReplacement> replacements;
}

/// The substitution for one `{{key}}` placeholder of a [RichContent].
final class RichContentReplacement {
  /// Creates a replacement.
  const RichContentReplacement({
    required this.value,
    required this.type,
    this.href,
    this.target,
  });

  /// Re-inflates a [RichContentReplacementMessage].
  RichContentReplacement.fromMessage(RichContentReplacementMessage message)
    : value = message.value ?? '',
      type = message.type ?? '',
      href = message.href,
      target = message.target;

  /// The text shown in place of the placeholder.
  final String value;

  /// The replacement type, e.g. `link`.
  final String type;

  /// The link URL, for a `link`.
  final String? href;

  /// The link's target window, e.g. `_blank`.
  final String? target;
}

/// A phone number's three parts, the value of a [PhoneNumberCollector].
final class PhoneNumberValue {
  /// Creates a phone number value.
  const PhoneNumberValue({
    this.countryCode = '',
    this.phoneNumber = '',
    this.phoneExtension = '',
  });

  /// The country, as the server's code (e.g. `GB`).
  final String countryCode;

  /// The number.
  final String phoneNumber;

  /// The extension. Named to avoid Dart's `extension` keyword.
  final String phoneExtension;

  /// A copy with the given parts replaced.
  PhoneNumberValue copyWith({
    String? countryCode,
    String? phoneNumber,
    String? phoneExtension,
  }) => PhoneNumberValue(
    countryCode: countryCode ?? this.countryCode,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    phoneExtension: phoneExtension ?? this.phoneExtension,
  );

  @override
  bool operator ==(Object other) =>
      other is PhoneNumberValue &&
      other.countryCode == countryCode &&
      other.phoneNumber == phoneNumber &&
      other.phoneExtension == phoneExtension;

  @override
  int get hashCode => Object.hash(countryCode, phoneNumber, phoneExtension);

  @override
  String toString() =>
      'PhoneNumberValue($countryCode, $phoneNumber, $phoneExtension)';
}

/// One MFA device a [DeviceRegistrationCollector] or [DeviceAuthenticationCollector] offers.
final class Device {
  /// Creates a device.
  const Device({
    required this.type,
    this.id,
    this.title,
    this.description,
    this.iconSrc,
    this.isDefault = false,
  });

  /// Re-inflates a [DeviceMessage].
  Device.fromMessage(DeviceMessage message)
    : id = message.id,
      type = message.type,
      title = message.title,
      description = message.deviceDescription,
      iconSrc = message.iconSrc,
      isDefault = message.isDefault ?? false;

  /// The enrolled device's id, for authentication; `null` for registration.
  final String? id;

  /// The device type, e.g. `EMAIL`, `SMS`, `VOICE`, `TOTP`.
  final String type;

  /// Display title.
  final String? title;

  /// Display description.
  final String? description;

  /// Icon URL.
  final String? iconSrc;

  /// Whether this is the user's default device.
  final bool isDefault;

  @override
  bool operator ==(Object other) =>
      other is Device &&
      other.id == id &&
      other.type == type &&
      other.title == title &&
      other.description == description &&
      other.iconSrc == iconSrc &&
      other.isDefault == isDefault;

  @override
  int get hashCode =>
      Object.hash(id, type, title, description, iconSrc, isDefault);

  @override
  String toString() => 'Device($type${id == null ? '' : ', $id'})';
}

/// What the app hands a [MetadataCollector]: [MetadataSuccess] or [MetadataFailure].
sealed class MetadataResult {
  const MetadataResult();
}

/// The connector's success branch, with a JSON [result].
final class MetadataSuccess extends MetadataResult {
  /// Creates a success result.
  const MetadataSuccess(this.result);

  /// The result, as JSON.
  final Map<String, Object?> result;
}

/// The connector's client-error branch.
final class MetadataFailure extends MetadataResult {
  /// Creates a failure result.
  const MetadataFailure({required this.code, required this.message});

  /// A short error code, e.g. `USER_CANCELLED`.
  final String code;

  /// A human-readable description.
  final String message;
}
