/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'callback.dart';

/// Collects a password. The native wire value is always sent back as `""` — the actual
/// characters are never round-tripped through native, only set locally by the UI.
final class PasswordCallback extends Callback {
  /// Creates a password callback from its wire-message fields.
  PasswordCallback({
    required super.type,
    required super.index,
    super.prompt,
    this.password = '',
  });

  /// The password entered by the user, set locally by the UI.
  String password;

  @override
  CallbackValueMessage toValue() =>
      CallbackValueMessage(type: type, index: index, value: password);
}
