/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:ping_oidc/ping_oidc.dart';

/// Single source of truth for the active OIDC environment. Replace the TODO placeholders with
/// values for your tenant's OAuth2/OIDC client before running the app.
///
/// Every value can also be supplied at build time instead of edited here, e.g.
/// `flutter run --dart-define-from-file=../.env`, using the `PINGAIC_*` keys named below. Nothing
/// secret belongs in this file: the browser login collects the user's credentials itself.
class Env {
  const Env._();

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
  // (`com.pingidentity.flutter.oidc` below) must match the one registered in the Android host
  // app's manifest — see the README. No `Info.plist` change is required on iOS;
  // `ASWebAuthenticationSession`'s callback scheme is set programmatically from this value.
  static const String redirectUri = String.fromEnvironment(
    'PINGAIC_REDIRECT_URI',
    defaultValue: 'com.pingidentity.flutter.oidc://oauthredirect',
  );

  // TODO: replace if your tenant expects a non-default sign-out redirect; empty means none.
  static const String _signOutRedirectUri = String.fromEnvironment('PINGAIC_SIGN_OUT_REDIRECT_URI');
  static const String? signOutRedirectUri = _signOutRedirectUri == '' ? null : _signOutRedirectUri;

  // TODO: replace with the scopes your client grants, comma- or space-separated.
  static const String _scopes = String.fromEnvironment(
    'PINGAIC_SCOPES',
    defaultValue: 'openid,profile,email',
  );

  static List<String> get scopes =>
      _scopes.split(RegExp(r'[ ,]+')).where((scope) => scope.isNotEmpty).toList();

  /// The active [OidcConfig], built from the values above.
  static final OidcConfig oidcConfig = OidcConfig(
    clientId: clientId,
    discoveryEndpoint: discoveryEndpoint,
    redirectUri: redirectUri,
    signOutRedirectUri: signOutRedirectUri,
    scopes: scopes,
  );
}
