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
    final api = hostApi ?? PingJourneyHostApi();
    final journeyId = await _guard(() => api.configureJourney(config));
    return JourneyClient._(journeyId, api);
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
  Future<Session?> user() async {
    final message = await _guard(() => _hostApi.getSession(_journeyId));
    if (message == null) return null;
    return Session.fromJson({
      'accessToken': message.accessToken,
      'refreshToken': message.refreshToken,
      'expiresIn': message.expiresIn,
      'userInfo': message.userInfo,
    });
  }

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
