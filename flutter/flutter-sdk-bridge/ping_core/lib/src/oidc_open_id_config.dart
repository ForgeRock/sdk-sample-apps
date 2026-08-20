/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// Explicit OpenID endpoint configuration, used in place of a discovery document.
///
/// Mirrors both native SDKs' `OpenIdConfiguration`, narrowed to the fields needed to skip
/// discovery — PAR and device-flow endpoints are out of scope for this seam.
class OidcOpenIdConfig {
  /// Creates an explicit OpenID endpoint configuration.
  const OidcOpenIdConfig({
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.userinfoEndpoint,
    this.endSessionEndpoint,
    this.pingEndIdpSessionEndpoint,
    this.revocationEndpoint,
  });

  /// The authorization endpoint URL.
  final String authorizationEndpoint;

  /// The token endpoint URL.
  final String tokenEndpoint;

  /// The userinfo endpoint URL.
  final String userinfoEndpoint;

  /// The end-session endpoint URL, if the provider supports RP-initiated logout.
  final String? endSessionEndpoint;

  /// The Ping end-IDP-session endpoint URL, using just the id token.
  final String? pingEndIdpSessionEndpoint;

  /// The token revocation endpoint URL.
  final String? revocationEndpoint;

  /// Parses a JSON-shaped map. Throws [FormatException] if a required field is missing or the
  /// wrong type.
  factory OidcOpenIdConfig.fromJson(Map<String, Object?> json) {
    final authorizationEndpoint = json['authorizationEndpoint'];
    if (authorizationEndpoint is! String || authorizationEndpoint.isEmpty) {
      throw const FormatException(
        'OidcOpenIdConfig.authorizationEndpoint must be a non-empty string',
      );
    }
    final tokenEndpoint = json['tokenEndpoint'];
    if (tokenEndpoint is! String || tokenEndpoint.isEmpty) {
      throw const FormatException(
        'OidcOpenIdConfig.tokenEndpoint must be a non-empty string',
      );
    }
    final userinfoEndpoint = json['userinfoEndpoint'];
    if (userinfoEndpoint is! String || userinfoEndpoint.isEmpty) {
      throw const FormatException(
        'OidcOpenIdConfig.userinfoEndpoint must be a non-empty string',
      );
    }
    for (final key in [
      'endSessionEndpoint',
      'pingEndIdpSessionEndpoint',
      'revocationEndpoint',
    ]) {
      final value = json[key];
      if (value != null && value is! String) {
        throw FormatException('OidcOpenIdConfig.$key must be a string when present');
      }
    }
    return OidcOpenIdConfig(
      authorizationEndpoint: authorizationEndpoint,
      tokenEndpoint: tokenEndpoint,
      userinfoEndpoint: userinfoEndpoint,
      endSessionEndpoint: json['endSessionEndpoint'] as String?,
      pingEndIdpSessionEndpoint: json['pingEndIdpSessionEndpoint'] as String?,
      revocationEndpoint: json['revocationEndpoint'] as String?,
    );
  }

  /// Serializes this configuration back to a JSON-shaped map.
  Map<String, Object?> toJson() => {
    'authorizationEndpoint': authorizationEndpoint,
    'tokenEndpoint': tokenEndpoint,
    'userinfoEndpoint': userinfoEndpoint,
    if (endSessionEndpoint != null) 'endSessionEndpoint': endSessionEndpoint,
    if (pingEndIdpSessionEndpoint != null)
      'pingEndIdpSessionEndpoint': pingEndIdpSessionEndpoint,
    if (revocationEndpoint != null) 'revocationEndpoint': revocationEndpoint,
  };
}
