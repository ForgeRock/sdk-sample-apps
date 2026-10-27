/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'collector.dart';

/// A string collector the server can attach a regex [validation] to: [TextCollector],
/// [PasswordCollector], and [SingleSelectCollector], as in both native SDKs.
sealed class ValidatedCollector extends FieldCollector<String> {
  ValidatedCollector._(super.message, super.value)
    : validation = message.validationRegex == null
          ? null
          : Validation(
              regex: message.validationRegex!,
              errorMessage: message.validationErrorMessage ?? '',
            ),
      super._();

  /// The server's regex rule, or `null` when there is none.
  final Validation? validation;
}

/// A free-text field (`TEXT`).
final class TextCollector extends ValidatedCollector {
  TextCollector._(CollectorMessage message)
    : super._(message, message.value as String? ?? '');
}

/// A password field, for both `PASSWORD` and `PASSWORD_VERIFY` (one native class).
///
/// [value] always starts empty: a password never crosses the bridge from native, even when the
/// server sends a default. The native collector wipes its own copy once submitted.
final class PasswordCollector extends ValidatedCollector {
  PasswordCollector._(CollectorMessage message)
    : passwordPolicy = message.passwordPolicy == null
          ? null
          : PasswordPolicy.fromMessage(message.passwordPolicy!),
      super._(message, '');

  /// The policy the password must satisfy — the field's own, or the node's — or `null`.
  final PasswordPolicy? passwordPolicy;
}

/// A single choice from [options] (`DROPDOWN`, `RADIO`); [value] is the chosen option's
/// [Option.value].
final class SingleSelectCollector extends ValidatedCollector {
  SingleSelectCollector._(CollectorMessage message)
    : options = _options(message),
      super._(message, message.value as String? ?? '');

  /// The choices, in display order.
  final List<Option> options;
}

List<Option> _options(CollectorMessage message) => List<Option>.unmodifiable(
  message.options?.whereType<OptionMessage>().map(Option.fromMessage) ??
      const <Option>[],
);
