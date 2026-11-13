/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// The OIDC tokens of a signed-in DaVinci user, returned by `DaVinciClient.getToken()`.
///
/// A read-only snapshot. The native SDK owns the tokens: it stores them in platform secure storage
/// and refreshes them when `getToken()` finds them expired, so call `getToken()` again rather than
/// keeping this object, and don't persist it.
class DaVinciToken {
  /// Creates a token set from its already-parsed fields.
  const DaVinciToken({
    required this.accessToken,
    this.tokenType,
    this.scope,
    required this.expiresIn,
    this.refreshToken,
    this.idToken,
  });

  /// The OAuth access token.
  final String accessToken;

  /// The OAuth token type (e.g. `Bearer`), if the server returned one.
  final String? tokenType;

  /// The granted scope string, if the server returned one.
  final String? scope;

  /// The access token's lifetime in seconds, as issued.
  final int expiresIn;

  /// The OAuth refresh token, if the server returned one.
  final String? refreshToken;

  /// The OIDC ID token, if the server returned one.
  final String? idToken;

  /// Parses a JSON-shaped map (e.g. built from a `TokenMessage`). Throws [FormatException] if a
  /// required field is missing or any field has the wrong type.
  factory DaVinciToken.fromJson(Map<String, Object?> json) {
    final accessToken = json['accessToken'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const FormatException(
        'DaVinciToken.accessToken must be a non-empty string',
      );
    }
    final expiresIn = json['expiresIn'];
    if (expiresIn is! int) {
      throw const FormatException('DaVinciToken.expiresIn must be an int');
    }
    return DaVinciToken(
      accessToken: accessToken,
      tokenType: _optionalString(json, 'tokenType'),
      scope: _optionalString(json, 'scope'),
      expiresIn: expiresIn,
      refreshToken: _optionalString(json, 'refreshToken'),
      idToken: _optionalString(json, 'idToken'),
    );
  }

  /// Serializes this token set back to a JSON-shaped map.
  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    if (tokenType != null) 'tokenType': tokenType,
    if (scope != null) 'scope': scope,
    'expiresIn': expiresIn,
    if (refreshToken != null) 'refreshToken': refreshToken,
    if (idToken != null) 'idToken': idToken,
  };

  static String? _optionalString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value != null && value is! String) {
      throw FormatException('DaVinciToken.$key must be a string when present');
    }
    return value as String?;
  }
}
