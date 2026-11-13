/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// Single source of truth for the active PingOne DaVinci environment. Replace the TODO
/// placeholders with values for your tenant before running the app.
///
/// Every value can also be supplied at build time instead of edited here, e.g.
/// `flutter run --dart-define-from-file=../.env`, using the `PINGONE_*` keys named below (the
/// `E2E_*` keys in the same file configure the bridge examples' integration tests, not this app).
/// Nothing secret belongs in this file: a DaVinci flow collects the user's credentials itself.
class Env {
  const Env._();

  // TODO: replace with your PingOne environment's OIDC discovery endpoint, e.g.
  // https://auth.pingone.com/<environment-id>/as/.well-known/openid-configuration
  static const String discoveryEndpoint = String.fromEnvironment(
    'PINGONE_DISCOVERY_ENDPOINT',
    defaultValue: '<discovery-endpoint>',
  );

  // TODO: replace with the client id of the PingOne application that runs your DaVinci flow.
  static const String clientId = String.fromEnvironment(
    'PINGONE_CLIENT_ID',
    defaultValue: '<client-id>',
  );

  // TODO: replace with the redirect URI registered on that application. A DaVinci flow never
  // opens a browser, so nothing is redirected to it, but PingOne still checks it on authorize.
  // Keep its scheme in sync with `appRedirectUriScheme` in `android/app/build.gradle.kts`.
  static const String redirectUri = String.fromEnvironment(
    'PINGONE_REDIRECT_URI',
    defaultValue: 'com.pingidentity.flutter.davinci://oauthredirect',
  );

  // TODO: replace with the scopes your application grants, comma- or space-separated.
  static const String _scopes = String.fromEnvironment(
    'PINGONE_SCOPES',
    defaultValue: 'openid,profile,email',
  );

  // TODO: replace with the `acr_values` that select your DaVinci flow (the flow policy id), or
  // leave empty to run the application's default policy. The start screen can change it per run.
  static const String acrValues = String.fromEnvironment('PINGONE_ACR_VALUES');

  static List<String> get scopes => _scopes
      .split(RegExp(r'[ ,]+'))
      .where((scope) => scope.isNotEmpty)
      .toList();
}
