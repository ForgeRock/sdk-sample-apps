/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:ping_journey/ping_journey.dart';
import 'package:ping_oidc/ping_oidc.dart' as oidc;

import 'package:flutter_journey/config/env.dart';

/// Single source of truth for Journey state, wrapping the plugin's [JourneyClient]. ViewModels
/// depend on this rather than the plugin directly, per the app's layered-MVVM architecture.
class JourneyRepository {
  JourneyClient? _client;

  /// The AM session token from the last successful Journey node, when one was established.
  /// Cached here (not in a ViewModel) because the success screen reads it synchronously and
  /// the token crosses the bridge on `start`/`next`, not via a dedicated call. Cleared on
  /// sign-off and dispose — a stale token must never survive into a subsequent run.
  String? _sessionToken;

  /// The shared `ping_oidc` client backing the current Journey when [Env.useSharedOidcClient]
  /// is on. `null` when the inline OIDC path is used instead (the default) or OIDC isn't
  /// configured at all.
  oidc.OidcClient? _sharedOidcClient;

  /// The AM session token established by the last completed Journey step, if any.
  String? get sessionToken => _sessionToken;

  /// Builds the native `Journey` for [Env] and starts [journeyName], returning the first node.
  ///
  /// Disposes any previously configured client first — the app's ViewModels are long-lived
  /// (created once at the root, not per-route), so a restart (Try Again / sign-off then log in
  /// again) calls this while a stale `_client` is still registered natively; without disposing
  /// it first, its native `Journey` + cached `ContinueNode` would leak in the core registry.
  Future<JourneyNode> startJourney(String journeyName) async {
    await dispose();
    final oidcConfig = Env.oidcConfig;

    String? oidcClientId;
    if (Env.useSharedOidcClient && oidcConfig != null) {
      // Configure OIDC once via `ping_oidc` and hand Journey the resulting handle id, instead of
      // repeating oidcConfig's fields inline below.
      _sharedOidcClient = await oidc.OidcClient.configure(
        oidc.OidcConfig(
          clientId: oidcConfig.clientId,
          discoveryEndpoint: oidcConfig.discoveryEndpoint,
          redirectUri: oidcConfig.redirectUri,
          scopes: oidcConfig.scopes,
        ),
      );
      oidcClientId = _sharedOidcClient!.handleId;
    }

    _client = await JourneyClient.configure(
      JourneyConfigMessage(
        serverUrl: Env.serverUrl,
        realm: Env.realm,
        cookie: Env.cookie,
        oidcClientId: oidcClientId,
        clientId: oidcClientId == null ? oidcConfig?.clientId : null,
        discoveryEndpoint: oidcClientId == null
            ? oidcConfig?.discoveryEndpoint
            : null,
        redirectUri: oidcClientId == null ? oidcConfig?.redirectUri : null,
        scopes: oidcClientId == null ? oidcConfig?.scopes : null,
      ),
    );
    return _captureNode(await _client!.start(journeyName));
  }

  Future<JourneyNode> next(ContinueNode node) async {
    return _captureNode(await _requireClient().next(node));
  }

  Future<Session?> user() => _requireClient().user();

  Future<Session> refresh() => _requireClient().refresh();

  Future<void> revoke() => _requireClient().revoke();

  Future<Map<String, Object?>?> userInfo({bool cache = false}) =>
      _requireClient().userInfo(cache: cache);

  Future<bool> signOff() async {
    final success = await _requireClient().signOff();
    if (success) {
      _sessionToken = null;
    }
    return success;
  }

  Future<void> dispose() async {
    _sessionToken = null;

    final client = _client;
    _client = null;
    await client?.dispose();

    final sharedOidcClient = _sharedOidcClient;
    _sharedOidcClient = null;
    await sharedOidcClient?.dispose();
  }

  /// Caches the AM session token off a successful node so the success screen can display it
  /// even when the Journey has no OIDC configuration (where `user()` returns null by design).
  JourneyNode _captureNode(JourneyNode node) {
    if (node is SuccessNode && node.sessionToken != null) {
      _sessionToken = node.sessionToken;
    }
    return node;
  }

  JourneyClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError(
        'startJourney() must complete before calling this method',
      );
    }
    return client;
  }
}
