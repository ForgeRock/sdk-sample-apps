/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'callback.dart';

/// Collects the user's acceptance of terms and conditions.
final class TermsAndConditionsCallback extends Callback {
  /// Creates a terms and conditions callback from its wire-message fields.
  TermsAndConditionsCallback({
    required super.type,
    required super.index,
    this.version = '',
    this.terms = '',
    this.createDate = '',
    this.accepted = false,
  });

  /// The version identifier of the terms being presented.
  final String version;

  /// The full text of the terms and conditions to display.
  final String terms;

  /// The date this version of the terms was created, as supplied by the server.
  final String createDate;

  /// Whether the user has accepted the terms.
  bool accepted;

  @override
  CallbackValueMessage toValue() =>
      CallbackValueMessage(type: type, index: index, value: accepted);
}
