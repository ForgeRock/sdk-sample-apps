/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'oidc_open_id_config.dart';

/// Flat configuration for a native OIDC client.
///
/// Consumed by `ping_oidc` to construct a real client, and by `ping_journey`/`ping_davinci` to
/// configure OIDC through the shared `ping_core` seam instead of duplicating every field.
class OidcConfig {
  /// Creates an OIDC client configuration.
  const OidcConfig({
    required this.clientId,
    this.discoveryEndpoint,
    this.openId,
    this.redirectUri,
    this.scopes = const [],
    this.acrValues,
    this.signOutRedirectUri,
    this.state,
    this.nonce,
    this.uiLocales,
    this.refreshThreshold,
    this.loginHint,
    this.display,
    this.prompt,
    this.additionalParameters = const {},
    this.par = false,
  });

  /// The OAuth2/OIDC client id.
  final String clientId;

  /// The discovery endpoint URL, if discovery is used instead of an explicit [openId].
  final String? discoveryEndpoint;

  /// The explicit OpenID endpoint configuration, if discovery is not used.
  final OidcOpenIdConfig? openId;

  /// The redirect URI registered for this client.
  final String? redirectUri;

  /// OAuth2 scopes requested during authorization.
  final List<String> scopes;

  /// The `acr_values` authorization parameter.
  final String? acrValues;

  /// The sign-out redirect URI. Applied on Android only — no equivalent field on iOS.
  final String? signOutRedirectUri;

  /// The `state` authorization parameter.
  final String? state;

  /// The `nonce` authorization parameter.
  final String? nonce;

  /// The `ui_locales` authorization parameter.
  final String? uiLocales;

  /// Token refresh threshold, in seconds. `null` if unset (native applies its own default).
  final int? refreshThreshold;

  /// The `login_hint` authorization parameter.
  final String? loginHint;

  /// The `display` authorization parameter.
  final String? display;

  /// The `prompt` authorization parameter.
  final String? prompt;

  /// Additional authorization parameters.
  final Map<String, String> additionalParameters;

  /// Whether to use Pushed Authorization Requests (RFC 9126).
  final bool par;

  /// Parses a JSON-shaped map. Throws [FormatException] if a required field is missing or the
  /// wrong type.
  factory OidcConfig.fromJson(Map<String, Object?> json) {
    final clientId = json['clientId'];
    if (clientId is! String || clientId.isEmpty) {
      throw const FormatException('OidcConfig.clientId must be a non-empty string');
    }
    final openIdJson = json['openId'];
    if (openIdJson != null && openIdJson is! Map) {
      throw const FormatException('OidcConfig.openId must be a map when present');
    }
    final scopesJson = json['scopes'];
    if (scopesJson != null && scopesJson is! List) {
      throw const FormatException('OidcConfig.scopes must be a list when present');
    }
    final refreshThreshold = json['refreshThreshold'];
    if (refreshThreshold != null && refreshThreshold is! int) {
      throw const FormatException('OidcConfig.refreshThreshold must be an int when present');
    }
    final additionalParametersJson = json['additionalParameters'];
    if (additionalParametersJson != null && additionalParametersJson is! Map) {
      throw const FormatException(
        'OidcConfig.additionalParameters must be a map when present',
      );
    }
    final par = json['par'];
    if (par != null && par is! bool) {
      throw const FormatException('OidcConfig.par must be a bool when present');
    }
    return OidcConfig(
      clientId: clientId,
      discoveryEndpoint: json['discoveryEndpoint'] as String?,
      openId: openIdJson == null
          ? null
          : OidcOpenIdConfig.fromJson((openIdJson as Map).cast<String, Object?>()),
      redirectUri: json['redirectUri'] as String?,
      scopes: (scopesJson as List?)?.cast<String>() ?? const [],
      acrValues: json['acrValues'] as String?,
      signOutRedirectUri: json['signOutRedirectUri'] as String?,
      state: json['state'] as String?,
      nonce: json['nonce'] as String?,
      uiLocales: json['uiLocales'] as String?,
      refreshThreshold: refreshThreshold as int?,
      loginHint: json['loginHint'] as String?,
      display: json['display'] as String?,
      prompt: json['prompt'] as String?,
      additionalParameters:
          (additionalParametersJson as Map?)?.cast<String, String>() ?? const {},
      par: par as bool? ?? false,
    );
  }

  /// Serializes this configuration back to a JSON-shaped map.
  Map<String, Object?> toJson() => {
    'clientId': clientId,
    if (discoveryEndpoint != null) 'discoveryEndpoint': discoveryEndpoint,
    if (openId != null) 'openId': openId!.toJson(),
    if (redirectUri != null) 'redirectUri': redirectUri,
    'scopes': scopes,
    if (acrValues != null) 'acrValues': acrValues,
    if (signOutRedirectUri != null) 'signOutRedirectUri': signOutRedirectUri,
    if (state != null) 'state': state,
    if (nonce != null) 'nonce': nonce,
    if (uiLocales != null) 'uiLocales': uiLocales,
    if (refreshThreshold != null) 'refreshThreshold': refreshThreshold,
    if (loginHint != null) 'loginHint': loginHint,
    if (display != null) 'display': display,
    if (prompt != null) 'prompt': prompt,
    'additionalParameters': additionalParameters,
    'par': par,
  };
}
