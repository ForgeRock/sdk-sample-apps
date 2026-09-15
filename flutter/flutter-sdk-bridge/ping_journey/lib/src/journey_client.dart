/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/services.dart';
import 'package:ping_core/ping_core.dart';

import 'journey_node.dart';
import 'messages.g.dart';
import 'node_mapper.dart';
import 'session.dart';

/// Public Dart facade over the generated [PingJourneyHostApi]. Wraps every call so native
/// failures surface as a typed [PingException] rather than a raw [PlatformException].
class JourneyClient {
  JourneyClient._(this._journeyId, this._hostApi);

  final String _journeyId;
  final PingJourneyHostApi _hostApi;

  /// Builds the native `Journey` for [config] and returns a client bound to it.
  static Future<JourneyClient> configure(
    JourneyConfigMessage config, {
    PingJourneyHostApi? hostApi,
  }) async {
    _validateOidcConfig(config);
    final api = hostApi ?? PingJourneyHostApi();
    final journeyId = await _guard(() => api.configureJourney(config));
    return JourneyClient._(journeyId, api);
  }

  /// Throws [ArgumentError] if [config] sets both `oidcClientId` and any inline OIDC field
  static void _validateOidcConfig(JourneyConfigMessage config) {
    if (config.oidcClientId == null) return;
    final hasInlineFields =
        config.clientId != null ||
        config.discoveryEndpoint != null ||
        config.redirectUri != null ||
        config.scopes != null;
    if (hasInlineFields) {
      throw ArgumentError(
        'JourneyConfigMessage.oidcClientId cannot be combined with inline OIDC fields '
        '(clientId/discoveryEndpoint/redirectUri/scopes) — configure OIDC through exactly one path.',
      );
    }
  }

  /// Starts the named Journey and returns the first node.
  Future<JourneyNode> start(
    String name, {
    bool forceAuth = false,
    bool noSession = false,
  }) async {
    final message = await _guard(
      () => _hostApi.start(
        _journeyId,
        name,
        StartOptionsMessage(forceAuth: forceAuth, noSession: noSession),
      ),
    );
    return NodeMapper.map(message, _journeyId);
  }

  /// Submits the current [node]'s callback values and returns the next node.
  Future<JourneyNode> next(ContinueNode node) async {
    final values = node.callbacks
        .map((callback) => callback.toValue())
        .whereType<CallbackValueMessage>()
        .toList();
    final message = await _guard(() => _hostApi.next(_journeyId, values));
    return NodeMapper.map(message, _journeyId);
  }

  /// Fetches the access/refresh token + userinfo for a completed Journey.
  ///
  /// Returns `null` when the Journey has no OIDC configuration or no session —
  /// a query, not a command: null means "nothing to show", not an error.
  Future<Session?> user() async {
    final message = await _guard(() => _hostApi.getSession(_journeyId));
    if (message == null) return null;
    return Session.fromJson({
      'accessToken': message.accessToken,
      'refreshToken': message.refreshToken,
      'idToken': message.idToken,
      'tokenType': message.tokenType,
      'scope': message.scope,
      'expiresIn': message.expiresIn,
      'userInfo': message.userInfo,
    });
  }

  /// Refreshes the OIDC token for a completed Journey, returning the new token
  /// set. The returned [Session] carries `userInfo: {}` — previously loaded
  /// claims are NOT re-fetched, so callers should preserve the userinfo they
  /// already have. Throws a typed [PingException] when the Journey has no OIDC
  /// configuration or no user session.
  Future<Session> refresh() async {
    final message = await _guard(() => _hostApi.refreshToken(_journeyId));
    return _sessionFromMessage(message);
  }

  /// Revokes the OIDC token for a completed Journey. Native swallows
  /// server-side revocation errors (matching the native SDKs and `ping_oidc`),
  /// so completion is not proof the token was invalidated. Throws a typed
  /// [PingException] when no OIDC/user session exists.
  Future<void> revoke() async {
    await _guard(() => _hostApi.revokeToken(_journeyId));
  }

  /// Fetches the OIDC userinfo claims for a completed Journey. [cache] is
  /// always passed explicitly to native — the platforms' own defaults differ
  /// (Android `false`, iOS `true`). Throws a typed [PingException] when no
  /// OIDC/user session exists.
  Future<Map<String, Object?>?> userInfo({bool cache = false}) async {
    final result = await _guard(() => _hostApi.getUserInfo(_journeyId, cache));
    return result.cast<String, Object?>();
  }

  Session _sessionFromMessage(SessionMessage message) => Session.fromJson({
    'accessToken': message.accessToken,
    'refreshToken': message.refreshToken,
    'idToken': message.idToken,
    'tokenType': message.tokenType,
    'scope': message.scope,
    'expiresIn': message.expiresIn,
    'userInfo': message.userInfo,
  });

  /// Signs the user out of the current session, returning whether the sign-off succeeded.
  Future<bool> signOff() => _guard(() => _hostApi.signOff(_journeyId));

  /// Releases the native `Journey` resources backing this client.
  Future<void> dispose() => _guard(() => _hostApi.dispose(_journeyId));

  static Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PlatformException catch (error) {
      throw PingException(
        error.code,
        error.details is String ? error.details as String : 'unknown',
        error.message ?? 'Unknown journey error',
      );
    }
  }
}
