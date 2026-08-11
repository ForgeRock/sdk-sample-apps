// Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/src/main/kotlin/com/pingidentity/flutter/oidc/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.pingidentity.flutter.oidc'),
    swiftOut: 'ios/ping_oidc/Sources/ping_oidc/Messages.g.swift',
    swiftOptions: SwiftOptions(),
    copyrightHeader: 'pigeons/copyright.txt',
    dartPackageName: 'ping_oidc',
  ),
)

/// Explicit OpenID endpoint configuration — the "skip discovery" escape
/// hatch. Mirrors ping_core's `OidcOpenIdConfig` field-for-field.
class OidcOpenIdConfigMessage {
  OidcOpenIdConfigMessage({
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.userinfoEndpoint,
  });

  /// The authorization endpoint URL.
  String authorizationEndpoint;

  /// The token endpoint URL.
  String tokenEndpoint;

  /// The userinfo endpoint URL.
  String userinfoEndpoint;

  /// The end-session endpoint URL, if the provider supports RP-initiated logout.
  String? endSessionEndpoint;

  /// The Ping end-IDP-session endpoint URL, using just the id token.
  String? pingEndIdpSessionEndpoint;

  /// The token revocation endpoint URL.
  String? revocationEndpoint;
}

/// Flat, wire-serializable OIDC client configuration.
///
/// Neither [discoveryEndpoint] nor [openId] is required at the Pigeon-type
/// level — both native SDKs silently defer validation rather than throwing
/// if both are absent, so the bridge itself validates "at least one must be
/// present" in `OidcConfigParser` and throws a typed `OIDC_CONFIGURE_ERROR`.
class OidcConfigMessage {
  OidcConfigMessage({
    required this.clientId,
    required this.redirectUri,
    required this.par,
  });

  /// The OAuth2/OIDC client id.
  String clientId;

  /// The redirect URI registered for this client.
  String redirectUri;

  /// The discovery endpoint URL, if discovery is used instead of an explicit [openId].
  String? discoveryEndpoint;

  /// The explicit OpenID endpoint configuration, if discovery is not used.
  OidcOpenIdConfigMessage? openId;

  /// OAuth2 scopes requested during authorization.
  List<String?>? scopes;

  /// The `acr_values` authorization parameter.
  String? acrValues;

  /// Android-only at apply time — iOS's native `OidcClientConfig` has no
  /// such field.
  String? signOutRedirectUri;

  /// The `state` authorization parameter.
  String? state;

  /// The `nonce` authorization parameter.
  String? nonce;

  /// The `ui_locales` authorization parameter.
  String? uiLocales;

  /// Seconds. Named explicitly to avoid the Journey schema's units ambiguity.
  int? refreshThresholdSeconds;

  /// The `login_hint` authorization parameter.
  String? loginHint;

  /// The `display` authorization parameter.
  String? display;

  /// The `prompt` authorization parameter.
  String? prompt;

  /// Additional authorization parameters.
  Map<String?, String?>? additionalParameters;

  /// Whether to use Pushed Authorization Requests (RFC 9126).
  bool par;
}

/// iOS-only browser presentation knobs. Android ignores every field here —
/// it only has Chrome Custom Tabs, no `BrowserType`/`BrowserMode` equivalent.
class BrowserOptionsMessage {
  BrowserOptionsMessage();

  /// One of `authSession` / `ephemeralAuthSession` (both implemented on iOS
  /// at 2.1.0). `nativeBrowserApp` / `sfViewController` are declared but not
  /// implemented natively — the iOS bridge rejects them rather than passing
  /// through to a silent no-op.
  String? browserType;

  /// One of `login` / `logout` / `custom`.
  String? browserMode;
}

/// A minted OIDC token set. Deliberately excludes the expiry-stamp field
/// (`expireAt` on Android vs `expiresAt` on iOS diverge in both name and
/// visibility) — only `expiresIn` (present, public, on both) crosses the
/// bridge.
class TokenMessage {
  TokenMessage({required this.accessToken, required this.expiresIn});

  /// The OAuth access token.
  String accessToken;

  /// The OAuth token type (e.g. `Bearer`), if the server returned one.
  String? tokenType;

  /// The granted scope string, if the server returned one.
  String? scope;

  /// The number of seconds until [accessToken] expires.
  int expiresIn;

  /// The OAuth refresh token, if the server returned one.
  String? refreshToken;

  /// The OIDC ID token, if the server returned one.
  String? idToken;
}

enum AuthorizeResultType {
  /// The user completed the browser login flow successfully.
  success,

  /// The user dismissed the browser without completing login. Not an error.
  cancel,
}

/// No authorization code, no `state`, no redirect URI ever crosses the
/// bridge — the native SDK captures the redirect and exchanges the code
/// internally on both platforms.
class AuthorizeResultMessage {
  AuthorizeResultMessage({required this.type});

  /// Whether the browser flow completed successfully or was cancelled by the user.
  AuthorizeResultType type;
}

@HostApi()
abstract class PingOidcHostApi {
  /// Builds a native `OidcClient` for [config] and returns its handle id.
  @async
  String configureOidc(OidcConfigMessage config);

  /// Builds a browser-capable `OidcWebClient` from the client identified by [clientId] and
  /// returns its handle id.
  @async
  String createWebClient(String clientId, BrowserOptionsMessage? options);

  /// Opens the system browser for the user to authenticate.
  @async
  AuthorizeResultMessage authorize(String webClientId);

  /// Whether a signed-in user session already exists for this web client.
  @async
  bool hasUser(String webClientId);

  /// The token most recently issued for this web client.
  @async
  TokenMessage token(String webClientId);

  /// Forces a token refresh via the stored refresh token.
  @async
  TokenMessage refresh(String webClientId);

  /// Fetches the userinfo claims for the signed-in user.
  @async
  Map<String?, Object?> userInfo(String webClientId, bool cache);

  /// Revokes the current token.
  @async
  void revoke(String webClientId);

  /// Signs the user out.
  @async
  bool signOff(String webClientId);

  /// Releases the native resources backing [handleId] (either a client or web-client handle).
  @async
  void dispose(String handleId);
}
