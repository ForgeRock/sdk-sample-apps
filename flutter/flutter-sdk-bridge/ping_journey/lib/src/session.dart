/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// The tokens and userinfo returned on a successful Journey (`JourneyClient.user()`).
///
/// Public-facing counterpart of the wire `SessionMessage` — kept as a distinct type (rather than
/// exposing the Pigeon message directly) so callers get plain `Map`/JSON-shaped values, with
/// manual `fromJson`/`toJson`.
class Session {
  /// Creates a session from its already-parsed fields.
  const Session({
    required this.accessToken,
    this.refreshToken,
    required this.expiresIn,
    this.userInfo = const {},
  });

  /// The OAuth access token issued for the completed Journey.
  final String accessToken;

  /// The OAuth refresh token issued for the completed Journey, if the server returned one.
  final String? refreshToken;

  /// The number of seconds until [accessToken] expires.
  final int expiresIn;

  /// The userinfo claims returned alongside the tokens.
  final Map<String, Object?> userInfo;

  /// Parses a JSON-shaped map (e.g. decoded from `SessionMessage`). Throws [FormatException] if
  /// required fields are missing or the wrong type.
  factory Session.fromJson(Map<String, Object?> json) {
    final accessToken = json['accessToken'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const FormatException(
        'Session.accessToken must be a non-empty string',
      );
    }
    final expiresIn = json['expiresIn'];
    if (expiresIn is! int) {
      throw const FormatException('Session.expiresIn must be an int');
    }
    final refreshToken = json['refreshToken'];
    if (refreshToken != null && refreshToken is! String) {
      throw const FormatException(
        'Session.refreshToken must be a string when present',
      );
    }
    final userInfo = json['userInfo'];
    if (userInfo != null && userInfo is! Map) {
      throw const FormatException(
        'Session.userInfo must be a map when present',
      );
    }
    return Session(
      accessToken: accessToken,
      refreshToken: refreshToken as String?,
      expiresIn: expiresIn,
      userInfo: (userInfo as Map?)?.cast<String, Object?>() ?? const {},
    );
  }

  /// Serializes this session back to a JSON-shaped map.
  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    if (refreshToken != null) 'refreshToken': refreshToken,
    'expiresIn': expiresIn,
    'userInfo': userInfo,
  };
}
