/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'callback.dart';

/// Classification of a [TextOutputCallback]'s message, mirroring the native
/// `TextOutputCallbackMessageType`/`MessageType` enums.
enum TextOutputMessageType {
  /// A general informational message.
  information,

  /// A warning that doesn't block the Journey from continuing.
  warning,

  /// An error message reported by the server.
  error,

  /// A script payload to be executed by the client (e.g. reCAPTCHA/device profiling).
  script,

  /// A message type not recognized by this bridge.
  unknown,
}

/// Displays a message to the user; contributes no value on `next()`.
final class TextOutputCallback extends Callback {
  /// Creates a text output callback, parsing [messageType] into a
  /// [TextOutputMessageType].
  TextOutputCallback({
    required super.type,
    required super.index,
    this.message = '',
    String? messageType,
  }) : messageType = _parseMessageType(messageType);

  /// The message text to display to the user.
  final String message;

  /// The classification of [message] (information, warning, error, etc.).
  final TextOutputMessageType messageType;

  /// Native platforms disagree on case: Android sends the Kotlin enum name
  /// (`"INFORMATION"`), iOS sends the Swift enum case description (`"information"`).
  static TextOutputMessageType _parseMessageType(String? value) {
    switch (value?.toLowerCase()) {
      case 'information':
        return TextOutputMessageType.information;
      case 'warning':
        return TextOutputMessageType.warning;
      case 'error':
        return TextOutputMessageType.error;
      case 'script':
        return TextOutputMessageType.script;
      default:
        return TextOutputMessageType.unknown;
    }
  }

  @override
  CallbackValueMessage? toValue() => null;
}
