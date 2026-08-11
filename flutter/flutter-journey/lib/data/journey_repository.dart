/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:ping_journey/ping_journey.dart';

import 'package:flutter_journey/config/env.dart';

/// Single source of truth for Journey state, wrapping the plugin's [JourneyClient]. ViewModels
/// depend on this rather than the plugin directly, per the app's layered-MVVM architecture.
class JourneyRepository {
  JourneyClient? _client;

  /// Builds the native `Journey` for [Env] and starts [journeyName], returning the first node.
  ///
  /// Disposes any previously configured client first — the app's ViewModels are long-lived
  /// (created once at the root, not per-route), so a restart (Try Again / sign-off then log in
  /// again) calls this while a stale `_client` is still registered natively; without disposing
  /// it first, its native `Journey` + cached `ContinueNode` would leak in the core registry.
  Future<JourneyNode> startJourney(String journeyName) async {
    await dispose();
    final oidc = Env.oidcConfig;
    _client = await JourneyClient.configure(
      JourneyConfigMessage(
        serverUrl: Env.serverUrl,
        realm: Env.realm,
        cookie: Env.cookie,
        clientId: oidc?.clientId,
        discoveryEndpoint: oidc?.discoveryEndpoint,
        redirectUri: oidc?.redirectUri,
        scopes: oidc?.scopes,
      ),
    );
    return _client!.start(journeyName);
  }

  Future<JourneyNode> next(ContinueNode node) => _requireClient().next(node);

  Future<Session?> user() => _requireClient().user();

  Future<bool> signOff() => _requireClient().signOff();

  Future<void> dispose() async {
    final client = _client;
    _client = null;
    await client?.dispose();
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
