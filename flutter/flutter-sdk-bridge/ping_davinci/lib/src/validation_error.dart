/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'collector/collector.dart';
import 'messages.g.dart';

/// One local validation failure, from `DaVinciClient.validate`: which [collector] failed, and why,
/// as a subtype per rule with its parameters.
///
/// Sealed, so an app can `switch` over it to render its own (localized) text. [message] is an
/// English default for apps that don't. The native SDKs' own messages are not used: iOS's are
/// hardcoded English.
///
/// The rules are the native SDKs' own, run natively, and they differ between platforms in a few
/// cases (ping-android-sdk / ping-ios-sdk 2.2.0), passed through unchanged:
/// - A regex must match the whole value on Android, but only somewhere in it on iOS, so an
///   unanchored server pattern accepts more on iOS.
/// - A required [BooleanCollector] left unchecked is a [RequiredError] on Android, but a
///   [RegexError] carrying the collector's `errorMessage` on iOS when the server sent one.
/// - Password lengths and character counts are in UTF-16 code units on Android and in characters
///   on iOS, so they differ for emoji.
sealed class ValidationError {
  const ValidationError._(this.collector);

  /// Re-inflates [message] for [collector], the collector it addresses.
  factory ValidationError.fromMessage(
    ValidationErrorMessage message,
    Collector collector,
  ) => switch (message.kind) {
    ValidationErrorKind.required => RequiredError._(collector),
    ValidationErrorKind.regex => RegexError._(collector, message.message ?? ''),
    ValidationErrorKind.invalidLength => InvalidLengthError._(
      collector,
      message.min ?? 0,
      message.max,
    ),
    ValidationErrorKind.uniqueCharacter => UniqueCharacterError._(
      collector,
      message.min ?? 0,
    ),
    ValidationErrorKind.maxRepeat => MaxRepeatError._(collector, message.max),
    ValidationErrorKind.minCharacters => MinCharactersError._(
      collector,
      message.character ?? '',
      message.min ?? 0,
    ),
  };

  /// The collector whose value failed.
  final Collector collector;

  /// An English description of the failure.
  String get message;

  @override
  String toString() => '$runtimeType(${collector.key}): $message';
}

/// A required field has no value: empty text, no selection, an unchecked box, or a phone number
/// missing its country code or number.
final class RequiredError extends ValidationError {
  const RequiredError._(super.collector) : super._();

  @override
  String get message => 'This field is required.';
}

/// The value doesn't match the server's regex; see [ValidatedCollector.validation].
final class RegexError extends ValidationError {
  const RegexError._(super.collector, this.message) : super._();

  /// The server's message for the rule.
  @override
  final String message;
}

/// A password's length is outside the policy's range.
final class InvalidLengthError extends ValidationError {
  const InvalidLengthError._(super.collector, this.min, this.max) : super._();

  /// The minimum length.
  final int min;

  /// The maximum length, or `null` when the policy sets none.
  final int? max;

  @override
  String get message => max == null
      ? 'Must be at least $min characters long.'
      : 'Must be between $min and $max characters long.';
}

/// A password has too few distinct characters.
final class UniqueCharacterError extends ValidationError {
  const UniqueCharacterError._(super.collector, this.min) : super._();

  /// The minimum number of distinct characters.
  final int min;

  @override
  String get message => 'Must contain at least $min different characters.';
}

/// A password repeats one character too often.
final class MaxRepeatError extends ValidationError {
  const MaxRepeatError._(super.collector, this.max) : super._();

  /// The most times one character may appear. Never `null` in practice: an unbounded policy
  /// can't be violated.
  final int? max;

  @override
  String get message =>
      'Must not use any character more than ${max ?? 0} times.';
}

/// A password has too few characters from one of the policy's character sets.
final class MinCharactersError extends ValidationError {
  const MinCharactersError._(super.collector, this.characters, this.min)
    : super._();

  /// The character set, e.g. `0123456789`.
  final String characters;

  /// How many characters from [characters] are needed.
  final int min;

  @override
  String get message =>
      'Must contain at least $min of these characters: $characters';
}
