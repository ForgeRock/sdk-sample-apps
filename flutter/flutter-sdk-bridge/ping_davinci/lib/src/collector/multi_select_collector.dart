/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'collector.dart';

/// Any number of choices from [options] (`CHECKBOX`, `COMBOBOX`); [value] holds the chosen
/// options' [Option.value]s.
///
/// Unlike [SingleSelectCollector] this is not a [ValidatedCollector] — on both native SDKs it has
/// a different base, with no regex validation.
final class MultiSelectCollector extends FieldCollector<List<String>> {
  MultiSelectCollector._(CollectorMessage message)
    : options = _options(message),
      super._(
        message,
        List<String>.unmodifiable(
          (message.value as List<Object?>?)?.whereType<String>() ??
              const <String>[],
        ),
      );

  /// The choices, in display order.
  final List<Option> options;

  /// The chosen values. Unmodifiable: assign a new list to change the selection.
  @override
  List<String> get value => super.value;

  @override
  set value(List<String> newValue) =>
      super.value = List<String>.unmodifiable(newValue);
}
