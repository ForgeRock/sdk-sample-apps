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

  /// Its scheme must match the one registered in the Android host app's manifest. iOS needs no
  /// `Info.plist` registration.
  final String redirectUri;
}

/// Single source of truth for the active Journey environment. Replace the TODO placeholders
/// with values for your tenant before running the app.
///
/// Every value except [useSharedOidcClient] can also be supplied at build time
/// instead of edited here, e.g. `flutter run --dart-define-from-file=../.env`, using the `PINGAIC_*`
/// keys named below. Nothing secret belongs in this file: the Journey collects the user's
/// credentials itself.
class Env {
  const Env._();

  // TODO: replace with your tenant's server URL, e.g. https://openam.example.com/am
  static const String serverUrl = String.fromEnvironment(
    'PINGAIC_SERVER_URL',
    defaultValue: '<server-url>',
  );

  // TODO: replace with your tenant's realm.
  static const String realm = String.fromEnvironment('PINGAIC_REALM', defaultValue: '<realm>');

  // TODO: replace if your tenant uses a non-default session cookie name. The classic default is
  // `iPlanetDirectoryPro`; check `GET <server-url>/json/serverinfo/*` for the configured name.
  static const String cookie = String.fromEnvironment(
    'PINGAIC_COOKIE',
    defaultValue: '<cookie-name>',
  );

  // TODO: replace with your tenant's OIDC discovery endpoint, e.g.
  // https://openam.example.com/am/oauth2/realms/root/.well-known/openid-configuration
  static const String discoveryEndpoint = String.fromEnvironment(
    'PINGAIC_DISCOVERY_ENDPOINT',
    defaultValue: '<discovery-endpoint>',
  );

  // TODO: replace with your OAuth2/OIDC client id.
  static const String clientId = String.fromEnvironment(
    'PINGAIC_CLIENT_ID',
    defaultValue: '<client-id>',
  );

  // TODO: replace with the redirect URI registered for this client. The scheme
  // (`com.pingidentity.flutter.oidc.journey` below) must match the one registered in the
  // Android host app's manifest — see the README. No `Info.plist` change is required on iOS;
  // `ASWebAuthenticationSession`'s callback scheme is set programmatically from this value.
  static const String redirectUri = String.fromEnvironment(
    'PINGAIC_REDIRECT_URI',
    defaultValue: 'com.pingidentity.flutter.oidc.journey://oauthredirect',
  );

  // TODO: replace with the scopes your client grants, comma- or space-separated.
  static const String _scopes = String.fromEnvironment(
    'PINGAIC_SCOPES',
    defaultValue: 'openid,profile,email',
  );

  static List<String> get scopes =>
      _scopes.split(RegExp(r'[ ,]+')).where((scope) => scope.isNotEmpty).toList();

  // TODO: replace with your tenant's OIDC client configuration, or set to null to skip
  // token exchange after a successful Journey. Stays null until [clientId] is configured.
  static final OidcConfig? oidcConfig = clientId == '<client-id>'
      ? null
      : OidcConfig(
          clientId: clientId,
          discoveryEndpoint: discoveryEndpoint,
          scopes: scopes,
          redirectUri: redirectUri,
        );

  /// When true and [oidcConfig] is set, OIDC is configured once via `ping_oidc` and Journey
  /// receives only the resulting handle id (`JourneyConfigMessage.oidcClientId`), instead of
  /// repeating [oidcConfig]'s fields inline. Off by default so the sample's behavior is
  /// unchanged unless explicitly opted into. See `JourneyRepository.startJourney`.
  static const bool useSharedOidcClient = false;
}
