/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'callback.dart';

/// Collects a plain-text name (e.g. username at login).
final class NameCallback extends Callback {
  /// Creates a name callback from its wire-message fields.
  NameCallback({
    required super.type,
    required super.index,
    super.prompt,
    this.name = '',
  });

  /// The name (e.g. username) entered by the user.
  String name;

  @override
  CallbackValueMessage toValue() =>
      CallbackValueMessage(type: type, index: index, value: name);
}
