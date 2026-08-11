/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// OIDC configuration for a Journey environment, applied when a token exchange follows Journey
/// completion. Fields are optional at the wire layer, but a real deployment sets them all.
class OidcConfig {
  const OidcConfig({
    required this.clientId,
    required this.discoveryEndpoint,
    required this.scopes,
    required this.redirectUri,
  });

  final String clientId;
  final String discoveryEndpoint;
  final List<String> scopes;

  /// Must match the native URL scheme registered in both the Android and iOS host apps.
  final String redirectUri;
}

/// Single source of truth for the active Journey environment. Replace the TODO placeholders
/// with values for your tenant before running the app.
class Env {
  const Env._();

  // TODO: replace with your tenant's server URL, e.g. https://openam.example.com/am
  static const String serverUrl = '<server-url>';

  // TODO: replace with your tenant's realm.
  static const String realm = '<realm>';

  // TODO: replace if your tenant uses a non-default session cookie name.
  static const String cookie = '<cookie-name>';

  // TODO: replace with your tenant's OIDC client configuration, or set to null to skip
  // token exchange after a successful Journey.
  static const OidcConfig? oidcConfig = null;
}
