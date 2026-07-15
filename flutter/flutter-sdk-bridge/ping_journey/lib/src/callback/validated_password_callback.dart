/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'callback.dart';

/// Collects a password validated against server-defined policies (e.g. self-registration).
final class ValidatedPasswordCallback extends Callback {
  /// Creates a validated password callback from its wire-message fields.
  ValidatedPasswordCallback({
    required super.type,
    required super.index,
    super.prompt,
    this.password = '',
    this.echoOn = false,
    this.validateOnly = false,
    this.policies,
    this.failedPolicies = const [],
  });

  /// The password entered by the user, set locally by the UI.
  String password;

  /// Whether the server requests the entered characters be displayed rather than masked.
  final bool echoOn;

  /// Read-only: reflects the native value at the time this node was mapped.
  /// There is no wire path to send an updated value back to native.
  final bool validateOnly;

  /// Server-defined password policies applicable to this field, if any.
  final Map<String, Object?>? policies;

  /// Policies that the current [password] failed validation against.
  final List<Map<String, Object?>> failedPolicies;

  @override
  CallbackValueMessage toValue() =>
      CallbackValueMessage(type: type, index: index, value: password);
}
