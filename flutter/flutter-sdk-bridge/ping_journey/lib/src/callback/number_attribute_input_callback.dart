/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'callback.dart';

/// Collects a single numeric identity attribute, validated against server-defined policies.
final class NumberAttributeInputCallback extends Callback {
  /// Creates a number attribute input callback from its wire-message fields.
  NumberAttributeInputCallback({
    required super.type,
    required super.index,
    super.prompt,
    this.name = '',
    this.required = false,
    this.value = 0,
    this.validateOnly = false,
    this.policies,
    this.failedPolicies = const [],
  });

  /// The identity attribute name this callback collects a value for.
  final String name;

  /// Whether the server requires a value to be submitted for this attribute.
  final bool required;

  /// The current numeric value, editable by the UI before submission.
  double value;

  /// Read-only: reflects the native value at the time this node was mapped.
  /// There is no wire path to send an updated value back to native.
  final bool validateOnly;

  /// Server-defined validation policies applicable to this attribute, if any.
  final Map<String, Object?>? policies;

  /// Policies that the current [value] failed validation against.
  final List<Map<String, Object?>> failedPolicies;

  @override
  CallbackValueMessage toValue() =>
      CallbackValueMessage(type: type, index: index, value: value);
}
