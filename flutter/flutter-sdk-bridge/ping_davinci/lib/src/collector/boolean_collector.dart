/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'collector.dart';

/// How the server asks a [BooleanCollector] to be drawn.
enum BooleanAppearance {
  /// A checkbox (`CHECKBOX`, the default).
  checkbox,

  /// A switch (`SWITCH`).
  toggleSwitch,
}

/// A single yes/no field (`SINGLE_CHECKBOX`), e.g. accepting terms.
final class BooleanCollector extends FieldCollector<bool> {
  BooleanCollector._(CollectorMessage message)
    : appearance = message.appearance == 'SWITCH'
          ? BooleanAppearance.toggleSwitch
          : BooleanAppearance.checkbox,
      errorMessage = message.errorMessage,
      richContent = message.richContent == null
          ? null
          : RichContent.fromMessage(message.richContent!),
      super._(message, message.value as bool? ?? false);

  /// Checkbox or switch.
  final BooleanAppearance appearance;

  /// The message for a required box left unchecked. Android substitutes its own English default
  /// when the server sends none; iOS reports `null`.
  final String? errorMessage;

  /// The label with link placeholders (e.g. "I agree to the {{link1}}"), when the server sends
  /// one. Prefer it over `label`, which holds the same text already flattened.
  final RichContent? richContent;
}
