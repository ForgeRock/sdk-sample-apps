/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:ping_oidc/ping_oidc.dart';

import 'package:flutter_oidc/config/env.dart';

/// Single source of truth for OIDC state, wrapping the plugin's [OidcClient]. ViewModels depend
/// on this rather than the plugin directly, per the app's layered-MVVM architecture.
class OidcRepository {
  OidcClient? _client;

  /// Builds the native `OidcClient` for [Env] and returns it.
  ///
  /// Disposes any previously configured client first — the app's ViewModels are long-lived
  /// (created once at the root, not per-route), so re-entering the login screen after a
  /// sign-off or a cancelled authorize calls this while a stale `_client` is still registered
  /// natively; without disposing it first, its native handles would leak in the core registry.
  Future<OidcClient> configure() async {
    await dispose();
    _client = await OidcClient.configure(Env.oidcConfig);
    return _client!;
  }

  Future<AuthorizeResult> authorize() => _requireClient().authorize();

  Future<bool> hasUser() => _requireClient().hasUser();

  Future<OidcToken> token() => _requireClient().token();

  Future<OidcToken> refresh() => _requireClient().refresh();

  Future<OidcUserInfo> userInfo({bool cache = false}) =>
      _requireClient().userInfo(cache: cache);

  Future<void> revoke() => _requireClient().revoke();

  Future<bool> signOff() => _requireClient().signOff();

  Future<void> dispose() async {
    final client = _client;
    _client = null;
    await client?.dispose();
  }

  OidcClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('configure() must complete before calling this method');
    }
    return client;
  }
}
