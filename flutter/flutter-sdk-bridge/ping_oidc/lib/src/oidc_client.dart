/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ping_core/ping_core.dart';

import 'authorize_result.dart';
import 'messages.g.dart';
import 'oidc_browser_options.dart';
import 'oidc_token.dart';
import 'oidc_user_info.dart';

/// Public Dart facade over the generated [PingOidcHostApi]. Wraps every call so native failures
/// surface as a typed [PingException] rather than a raw [PlatformException].
///
/// The two-handle model (a native `OidcClient` handle plus a browser-capable `OidcWebClient`
/// handle) is kept internal to this class; callers only ever see one [OidcClient].
class OidcClient {
  OidcClient._(this._handleId, this._webHandleId, this._hostApi);

  final String _handleId;
  final String _webHandleId;
  final PingOidcHostApi _hostApi;

  /// Builds the native `OidcClient` for [config], a browser-capable web client from it, and
  /// returns an [OidcClient] bound to both.
  static Future<OidcClient> configure(
    OidcConfig config, {
    OidcBrowserOptions? browserOptions,
    PingOidcHostApi? hostApi,
  }) async {
    final api = hostApi ?? PingOidcHostApi();
    final handleId = await _guard(
      () => api.configureOidc(_toMessage(config)),
    );
    final String webHandleId;
    try {
      webHandleId = await _guard(
        () => api.createWebClient(handleId, browserOptions?.toMessage()),
      );
    } catch (error) {
      // Roll back the already-registered client handle so a createWebClient failure can't
      // leave it orphaned in CoreRuntime.oidcClientRegistry with no caller-reachable dispose().
      try {
        await _guard(() => api.dispose(handleId));
      } catch (rollbackError) {
        // The rollback itself failed, leaking `handleId` in the native registry — surfacing the
        // original `error` below is still correct, but log this so a leaked-handle report has
        // something to point at.
        debugPrint(
          'OidcClient.configure: rollback dispose($handleId) failed after a '
          'createWebClient error: $rollbackError',
        );
      }
      rethrow;
    }
    return OidcClient._(handleId, webHandleId, api);
  }

  /// Builds the wire [OidcConfigMessage] for [config].
  ///
  /// Throws [ArgumentError] if [OidcConfig.redirectUri] is `null` — it's a required field on the
  /// wire, but nullable on [OidcConfig] since `ping_journey`/`ping_davinci` can configure OIDC
  /// through the shared `ping_core` seam without ever needing a standalone redirect URI.
  static OidcConfigMessage _toMessage(OidcConfig config) {
    final redirectUri = config.redirectUri;
    if (redirectUri == null) {
      throw ArgumentError.value(
        null,
        'config.redirectUri',
        'OidcClient.configure requires a non-null redirectUri',
      );
    }
    return OidcConfigMessage(
      clientId: config.clientId,
      redirectUri: redirectUri,
      par: config.par,
    )
      ..discoveryEndpoint = config.discoveryEndpoint
      ..openId = _toOpenIdMessage(config.openId)
      ..scopes = config.scopes
      ..acrValues = config.acrValues
      ..signOutRedirectUri = config.signOutRedirectUri
      ..state = config.state
      ..nonce = config.nonce
      ..uiLocales = config.uiLocales
      ..refreshThresholdSeconds = config.refreshThreshold
      ..loginHint = config.loginHint
      ..display = config.display
      ..prompt = config.prompt
      ..additionalParameters = config.additionalParameters;
  }

  /// Builds the wire [OidcOpenIdConfigMessage] for [openId], or `null` if discovery is used
  /// instead of an explicit OpenID configuration.
  static OidcOpenIdConfigMessage? _toOpenIdMessage(OidcOpenIdConfig? openId) {
    if (openId == null) return null;
    return OidcOpenIdConfigMessage(
      authorizationEndpoint: openId.authorizationEndpoint,
      tokenEndpoint: openId.tokenEndpoint,
      userinfoEndpoint: openId.userinfoEndpoint,
    )
      ..endSessionEndpoint = openId.endSessionEndpoint
      ..pingEndIdpSessionEndpoint = openId.pingEndIdpSessionEndpoint
      ..revocationEndpoint = openId.revocationEndpoint;
  }

  /// Opens the system browser for the user to authenticate. Resolves [AuthorizeCancel] — not an
  /// error — if the user dismisses the browser without completing login.
  Future<AuthorizeResult> authorize() async {
    final result = await _guard(() => _hostApi.authorize(_webHandleId));
    switch (result.type) {
      case AuthorizeResultType.success:
        return const AuthorizeSuccess();
      case AuthorizeResultType.cancel:
        return const AuthorizeCancel();
    }
  }

  /// Whether a signed-in user session already exists for this client.
  Future<bool> hasUser() => _guard(() => _hostApi.hasUser(_webHandleId));

  /// The token most recently issued for this client. Fails with a [PingException] if no
  /// authenticated session exists.
  Future<OidcToken> token() async {
    final message = await _guard(() => _hostApi.token(_webHandleId));
    return OidcToken.fromMessage(message);
  }

  /// Forces a token refresh via the stored refresh token. Fails with a [PingException] if there
  /// is no session or no refresh token to use.
  Future<OidcToken> refresh() async {
    final message = await _guard(() => _hostApi.refresh(_webHandleId));
    return OidcToken.fromMessage(message);
  }

  /// Fetches the userinfo claims for the signed-in user.
  ///
  /// [cache] defaults to `false`: this matches Android's own native default, and a forced fresh
  /// fetch is a safer default failure mode than silently serving a stale cached claim set. Per
  /// the platform-asymmetry note in `IMPLEMENTATION_PLAN_OIDC.md`, the bridge always passes
  /// [cache] to native explicitly regardless of this Dart-level default.
  Future<OidcUserInfo> userInfo({bool cache = false}) async {
    final result = await _guard(() => _hostApi.userInfo(_webHandleId, cache));
    return result.cast<String, Object?>();
  }

  /// Revokes the current token. Native swallows revocation failures internally; this either
  /// completes or throws a [PingException] if the session itself couldn't be resolved.
  Future<void> revoke() => _guard(() => _hostApi.revoke(_webHandleId));

  /// Signs the user out. Returns `true` unless resolving the session itself failed — this is
  /// **not** proof a session existed before the call. See the Phase 4 "Known SDK gap" note in
  /// `IMPLEMENTATION_PLAN_OIDC.md` for why `signOff`'s boolean isn't sourced from the native
  /// SDKs' own `endSession()` semantics.
  Future<bool> signOff() => _guard(() => _hostApi.signOff(_webHandleId));

  /// Releases the native `OidcClient` and `OidcWebClient` resources backing this client.
  ///
  /// Both native `dispose` calls always run, even if one throws — otherwise a failure disposing
  /// [_handleId] would skip disposing [_webHandleId] and leak it in the native registry.
  Future<void> dispose() async {
    final results = await Future.wait<Object?>([
      _guard(() => _hostApi.dispose(_handleId)).then<Object?>((_) => null),
      _guard(() => _hostApi.dispose(_webHandleId)).then<Object?>((_) => null),
    ].map((future) => future.catchError((Object error) => error)));

    final error = results.firstWhere(
      (result) => result != null,
      orElse: () => null,
    );
    if (error != null) throw error;
  }

  static Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PlatformException catch (error) {
      throw PingException(
        error.code,
        error.details is String ? error.details as String : 'unknown',
        error.message ?? 'Unknown OIDC error',
      );
    }
  }
}
