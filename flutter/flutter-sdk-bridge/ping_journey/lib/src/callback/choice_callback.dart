/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'callback.dart';

/// Collects a single choice from a fixed list of options.
final class ChoiceCallback extends Callback {
  /// Creates a choice callback, defaulting the selection to [defaultChoice]
  /// unless [selectedIndex] is provided.
  ChoiceCallback({
    required super.type,
    required super.index,
    super.prompt,
    this.choices = const [],
    this.defaultChoice = 0,
    int? selectedIndex,
  }) : selectedIndex = selectedIndex ?? defaultChoice;

  /// The list of options the user can choose from.
  final List<String> choices;

  /// The index into [choices] the server suggests as the initial selection.
  final int defaultChoice;

  /// The index into [choices] currently selected by the user.
  int selectedIndex;

  @override
  CallbackValueMessage toValue() =>
      CallbackValueMessage(type: type, index: index, value: selectedIndex);
}
