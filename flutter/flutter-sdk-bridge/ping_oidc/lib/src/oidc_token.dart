/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'messages.g.dart';

/// The token set returned by [OidcClient.token]/[OidcClient.refresh].
///
/// Public-facing counterpart of the wire `TokenMessage` — kept as a distinct type so callers
/// aren't coupled to the generated Pigeon class.
class OidcToken {
  /// Creates a token from its already-parsed fields.
  const OidcToken({
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

  /// The number of seconds until [accessToken] expires.
  final int expiresIn;

  /// The OAuth refresh token, if the server returned one.
  final String? refreshToken;

  /// The OIDC ID token, if the server returned one.
  final String? idToken;

  /// Builds an [OidcToken] directly from the generated [TokenMessage]'s typed fields.
  factory OidcToken.fromMessage(TokenMessage message) => OidcToken(
    accessToken: message.accessToken,
    tokenType: message.tokenType,
    scope: message.scope,
    expiresIn: message.expiresIn,
    refreshToken: message.refreshToken,
    idToken: message.idToken,
  );

  /// Parses a JSON-shaped map. Throws [FormatException] if required fields are missing or the
  /// wrong type.
  factory OidcToken.fromJson(Map<String, Object?> json) {
    final accessToken = json['accessToken'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const FormatException(
        'OidcToken.accessToken must be a non-empty string',
      );
    }
    final expiresIn = json['expiresIn'];
    if (expiresIn is! int) {
      throw const FormatException('OidcToken.expiresIn must be an int');
    }
    final tokenType = json['tokenType'];
    if (tokenType != null && tokenType is! String) {
      throw const FormatException(
        'OidcToken.tokenType must be a string when present',
      );
    }
    final scope = json['scope'];
    if (scope != null && scope is! String) {
      throw const FormatException(
        'OidcToken.scope must be a string when present',
      );
    }
    final refreshToken = json['refreshToken'];
    if (refreshToken != null && refreshToken is! String) {
      throw const FormatException(
        'OidcToken.refreshToken must be a string when present',
      );
    }
    final idToken = json['idToken'];
    if (idToken != null && idToken is! String) {
      throw const FormatException(
        'OidcToken.idToken must be a string when present',
      );
    }
    return OidcToken(
      accessToken: accessToken,
      tokenType: tokenType as String?,
      scope: scope as String?,
      expiresIn: expiresIn,
      refreshToken: refreshToken as String?,
      idToken: idToken as String?,
    );
  }

  /// Serializes this token back to a JSON-shaped map.
  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    if (tokenType != null) 'tokenType': tokenType,
    if (scope != null) 'scope': scope,
    'expiresIn': expiresIn,
    if (refreshToken != null) 'refreshToken': refreshToken,
    if (idToken != null) 'idToken': idToken,
  };
}
