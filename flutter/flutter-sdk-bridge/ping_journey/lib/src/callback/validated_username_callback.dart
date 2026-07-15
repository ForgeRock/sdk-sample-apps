/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'callback.dart';

/// Collects a username validated against server-defined policies (e.g. self-registration).
final class ValidatedUsernameCallback extends Callback {
  /// Creates a validated username callback from its wire-message fields.
  ValidatedUsernameCallback({
    required super.type,
    required super.index,
    super.prompt,
    this.username = '',
    this.validateOnly = false,
    this.policies,
    this.failedPolicies = const [],
  });

  /// The username entered by the user.
  String username;

  /// Read-only: reflects the native value at the time this node was mapped.
  /// There is no wire path to send an updated value back to native.
  final bool validateOnly;

  /// Server-defined username policies applicable to this field, if any.
  final Map<String, Object?>? policies;

  /// Policies that the current [username] failed validation against.
  final List<Map<String, Object?>> failedPolicies;

  @override
  CallbackValueMessage toValue() =>
      CallbackValueMessage(type: type, index: index, value: username);
}
