/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'callback.dart';

/// Collects free-form text input.
final class TextInputCallback extends Callback {
  /// Creates a text input callback, initializing [text] to [defaultText]
  /// unless an explicit [text] value is provided.
  TextInputCallback({
    required super.type,
    required super.index,
    super.prompt,
    this.defaultText = '',
    String? text,
  }) : text = text ?? defaultText;

  /// The server-suggested initial value for this field.
  final String defaultText;

  /// The current text value, editable by the UI before submission.
  String text;

  @override
  CallbackValueMessage toValue() =>
      CallbackValueMessage(type: type, index: index, value: text);
}
