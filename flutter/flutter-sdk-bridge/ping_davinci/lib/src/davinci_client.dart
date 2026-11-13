/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ping_core/ping_core.dart';

import 'collector/collector.dart';
import 'davinci_node.dart';
import 'messages.g.dart' as wire show pollingEvents;
import 'messages.g.dart' hide pollingEvents;
import 'node_mapper.dart';
import 'polling_status.dart';
import 'session.dart';
import 'token.dart';
import 'validation_error.dart';

/// Public Dart facade over the generated [PingDaVinciHostApi]. Wraps every call so native
/// failures surface as a typed [PingException] rather than a raw [PlatformException].
class DaVinciClient {
  DaVinciClient._(this._handleId, this._hostApi, this._pollingEvents);

  final String _handleId;
  final PingDaVinciHostApi _hostApi;
  final Stream<PollingEventMessage> _pollingEvents;

  /// The polls this client is running, closed when the flow moves on.
  final Set<_Poll> _polls = <_Poll>{};

  /// The one `pollingEvents` channel stream, shared by every client: each call of the generated
  /// function replaces the channel's handler, so it is made once.
  static final Stream<PollingEventMessage> _sharedPollingEvents = wire
      .pollingEvents();

  static int _pollSequence = 0;

  /// The id of the native DaVinci workflow in `ping_core`'s `CoreRuntime.davinciRegistry`.
  String get handleId => _handleId;

  /// Builds the native DaVinci workflow for [config] and returns a client bound to it.
  ///
  /// Throws a [PingException] of type `argument` unless [config] configures OIDC through
  /// exactly one path — see [DaVinciConfigMessage]. The check runs natively, so both platforms
  /// enforce the same rule.
  ///
  /// [hostApi] and [pollingEvents] replace the platform channels, for tests.
  static Future<DaVinciClient> configure(
    DaVinciConfigMessage config, {
    PingDaVinciHostApi? hostApi,
    Stream<PollingEventMessage>? pollingEvents,
  }) async {
    final api = hostApi ?? PingDaVinciHostApi();
    final handleId = await _guard(() => api.configureDaVinci(config));
    return DaVinciClient._(
      handleId,
      api,
      pollingEvents ?? _sharedPollingEvents,
    );
  }

  /// Starts the flow and returns its first node. Running polls end.
  Future<DaVinciNode> start() async {
    _closePolls();
    final message = await _guard(() => _hostApi.start(_handleId));
    return NodeMapper.map(message);
  }

  /// Submits the values the app set on [node]'s collectors and returns the next node.
  ///
  /// Only collectors whose `value` was set are sent. A value of the wrong type for its collector
  /// throws a [PingException] of type `argument` and submits nothing. Nothing is validated
  /// locally first, as in both native SDKs: call [validate] for that.
  ///
  /// [node] is the current form, or the [ErrorNode.continueNode] of the error it produced.
  /// Running polls end: a finished one has already set its collector's value, which is sent.
  Future<DaVinciNode> next(ContinueNode node) async {
    final values = _values(node);
    _closePolls();
    final message = await _guard(() => _hostApi.next(_handleId, values));
    return NodeMapper.map(message);
  }

  /// Runs the native SDK's local validation over [node]'s values, without a network call:
  /// required fields, server regexes, and the password policy.
  ///
  /// Sends the values the app set, exactly as [next] would, then sets each collector's
  /// [FieldCollector.validationErrors] and returns every error in collector order. Errors for
  /// collectors this package doesn't type (see [ContinueNode.unsupportedFields]) are left out:
  /// the app can't render or correct them. See [ValidationError] for where the platforms' rules
  /// differ.
  Future<List<ValidationError>> validate(ContinueNode node) async {
    final messages = await _guard(
      () => _hostApi.validate(_handleId, _values(node)),
    );
    final byIndex = <int, Collector>{
      for (final collector in node.collectors) collector.index: collector,
    };
    final errors = List<ValidationError>.unmodifiable(<ValidationError>[
      for (final message in messages.whereType<ValidationErrorMessage>())
        if (byIndex[message.index] case final collector?
            when collector.type == message.collectorType)
          ValidationError.fromMessage(message, collector),
    ]);
    attachValidationErrors(node.collectors, errors);
    return errors;
  }

  /// The authorization code of the [SuccessNode] this client reached, or `null` before it has
  /// reached one (or after it starts over or signs off).
  ///
  /// The code is spent: the native SDK redeems it itself, so this is for display and diagnostics.
  /// See [DaVinciSession]. Throws a [PingException] of type `auth` if the node carried no code.
  Future<DaVinciSession?> getSession() async {
    final message = await _guard(() => _hostApi.getSession(_handleId));
    if (message == null) return null;
    return DaVinciSession.fromJson({
      'authorizationCode': message.authorizationCode,
    });
  }

  /// The signed-in user's OIDC tokens, read from native secure storage and refreshed natively if
  /// they have expired.
  ///
  /// Throws a [PingException] of type `state` when there is no signed-in user: before the flow
  /// reaches a [SuccessNode], after [signOff], or once the session cookie is gone. It never
  /// returns an empty token. Token failures surface with the OIDC error's type (`auth`,
  /// `network`, `exchange`, …).
  Future<DaVinciToken> getToken() async {
    final message = await _guard(() => _hostApi.getToken(_handleId));
    return DaVinciToken.fromJson({
      'accessToken': message.accessToken,
      'tokenType': message.tokenType,
      'scope': message.scope,
      'expiresIn': message.expiresIn,
      'refreshToken': message.refreshToken,
      'idToken': message.idToken,
    });
  }

  /// The signed-in user's userinfo claims, fetched from the userinfo endpoint.
  ///
  /// With [cache] `true`, a native copy from an earlier cached call is returned without a
  /// request. It defaults to `false` on every platform; the native SDKs' own defaults differ
  /// (Android `false`, iOS `true`), so the bridge always passes it. Throws like [getToken].
  Future<Map<String, Object?>> getUserInfo({bool cache = false}) async {
    final claims = await _guard(() => _hostApi.getUserInfo(_handleId, cache));
    return Map<String, Object?>.unmodifiable(<String, Object?>{
      for (final MapEntry(:key, :value) in claims.entries) ?key: value,
    });
  }

  /// Signs the user off: ends the OIDC session, revokes the stored tokens, deletes the session
  /// cookies, and drops this client's cached node, so [getToken] then throws.
  ///
  /// Returns `false` if the native sign-off threw (it is logged natively), `true` otherwise.
  /// `true` does not prove a session existed: signing off with none succeeds. Neither outcome
  /// throws; only a disposed client does.
  Future<bool> signOff() {
    _closePolls();
    return _guard(() => _hostApi.signOff(_handleId));
  }

  /// Releases the native DaVinci resources backing this client, ending its polls.
  Future<void> dispose() {
    _closePolls();
    return _guard(() => _hostApi.dispose(_handleId));
  }

  /// Polls [collector], a [PollingCollector] of the current node, natively, and streams its
  /// statuses: zero or more [PollingContinue]s, then one terminal status, then done. Submit the
  /// node with [next] afterwards; the native collector holds the value the poll ended with.
  ///
  /// The poll starts when the stream is listened to. Cancelling the subscription, [next],
  /// [start], [signOff] and [dispose] all end it: the stream closes with no terminal status, and
  /// nothing more is reported. A failure to start (e.g. [collector] isn't on the current node) is
  /// a [PingException] error event, then done.
  ///
  /// **Platform difference (native 2.2.0):** ending a poll on Android stops its network polling
  /// at once. iOS can't: its SDK polls in a task the app can't cancel, which goes on sending
  /// status requests, unreported, for up to `pollRetries × pollInterval`.
  Stream<PollingStatus> poll(PollingCollector collector) {
    final poll = _Poll('$_handleId#${_pollSequence++}', _polls);
    poll.controller = StreamController<PollingStatus>(
      onListen: () {
        _polls.add(poll);
        poll.events = _pollingEvents
            .where((event) => event.pollId == poll.id)
            .listen((event) {
              final status = PollingStatus.fromMessage(event);
              poll.controller.add(status);
              if (status.isTerminal) poll.close();
            });
        _guard(
          () => _hostApi.startPolling(
            _handleId,
            poll.id,
            collector.type,
            collector.index,
          ),
        ).catchError((Object error) {
          if (poll.isOpen) poll.controller.addError(error);
          poll.close();
        });
      },
      onCancel: () {
        final wasOpen = poll.isOpen;
        poll.close();
        // A poll that ended by itself is already released natively.
        if (wasOpen) return _hostApi.cancelPolling(poll.id).catchError((_) {});
        return null;
      },
    );
    return poll.controller.stream;
  }

  /// Ends every running poll on the Dart side; native cancels its own on the same calls.
  void _closePolls() {
    for (final poll in _polls.toList()) {
      poll.close();
    }
  }

  static List<CollectorValueMessage> _values(ContinueNode node) => node
      .collectors
      .map((collector) => collector.toValue())
      .whereType<CollectorValueMessage>()
      .toList();

  static Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PlatformException catch (error) {
      throw PingException(
        error.code,
        error.details is String ? error.details as String : 'unknown',
        error.message ?? 'Unknown DaVinci error',
      );
    }
  }
}

/// One [DaVinciClient.poll] stream and its slice of the shared event channel.
class _Poll {
  _Poll(this.id, this._owner);

  final String id;
  final Set<_Poll> _owner;
  late final StreamController<PollingStatus> controller;
  StreamSubscription<PollingEventMessage>? events;
  bool _closed = false;

  bool get isOpen => !_closed;

  void close() {
    if (_closed) return;
    _closed = true;
    _owner.remove(this);
    events?.cancel();
    controller.close();
  }
}
