/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:ping_davinci/ping_davinci.dart';

import 'package:flutter_davinci/config/env.dart';

/// Single source of truth for DaVinci state, wrapping the plugin's [DaVinciClient]. ViewModels
/// depend on this rather than the plugin directly, per the app's layered-MVVM architecture.
class DaVinciRepository {
  DaVinciClient? _client;

  /// Builds the native DaVinci workflow for [Env] and starts the flow [acrValues] selects,
  /// returning its first node.
  ///
  /// Disposes any previously configured client first: the ViewModels are long-lived (created
  /// once at the root, not per route), so a restart (Try Again, or sign off then start again)
  /// calls this while the last client is still registered natively. Without the dispose, its
  /// native workflow and cached node would leak in the core registry.
  Future<DaVinciNode> start(String acrValues) async {
    await dispose();
    _client = await DaVinciClient.configure(
      DaVinciConfigMessage()
        ..clientId = Env.clientId
        ..discoveryEndpoint = Env.discoveryEndpoint
        ..redirectUri = Env.redirectUri
        ..scopes = Env.scopes
        ..acrValues = acrValues.isEmpty ? null : acrValues,
    );
    return _client!.start();
  }

  Future<DaVinciNode> next(ContinueNode node) => _requireClient().next(node);

  Future<List<ValidationError>> validate(ContinueNode node) =>
      _requireClient().validate(node);

  Stream<PollingStatus> poll(PollingCollector collector) =>
      _requireClient().poll(collector);

  Future<DaVinciSession?> session() => _requireClient().getSession();

  Future<DaVinciToken> token() => _requireClient().getToken();

  Future<Map<String, Object?>> userInfo() => _requireClient().getUserInfo();

  Future<bool> signOff() => _requireClient().signOff();

  Future<void> dispose() async {
    final client = _client;
    _client = null;
    await client?.dispose();
  }

  DaVinciClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('start() must complete before calling this method');
    }
    return client;
  }
}
