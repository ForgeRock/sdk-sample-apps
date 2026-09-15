/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:ping_oidc/ping_oidc.dart';

/// Single source of truth for the active OIDC environment. Replace the TODO placeholders with
/// values for your tenant's OAuth2/OIDC client before running the app.
class Env {
  const Env._();

  // TODO: replace with your tenant's OIDC discovery endpoint, e.g.
  // https://openam.example.com/am/oauth2/realms/root/.well-known/openid-configuration
  static const String discoveryEndpoint = '<discovery-endpoint>';

  // TODO: replace with your OAuth2/OIDC client id.
  static const String clientId = '<client-id>';

  // TODO: replace with the redirect URI registered for this client. The scheme
  // (`com.pingidentity.flutter.oidc` below) must match the one registered in both the Android
  // and iOS host apps — see the README for the exact manifest/Info.plist configuration this
  // requires, and update both places together if you change it.
  static const String redirectUri = 'com.pingidentity.flutter.oidc://oauthredirect';

  // TODO: replace if your tenant expects a non-default sign-out redirect.
  static const String? signOutRedirectUri = null;

  static const List<String> scopes = ['openid', 'profile', 'email'];

  /// The active [OidcConfig], built from the values above.
  static const OidcConfig oidcConfig = OidcConfig(
    clientId: clientId,
    discoveryEndpoint: discoveryEndpoint,
    redirectUri: redirectUri,
    signOutRedirectUri: signOutRedirectUri,
    scopes: scopes,
  );
}
