/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'collector.dart';

/// A pause while the user acts somewhere else (`POLLING`): approves a push, opens a magic link,
/// scans a QR code. Run it with `DaVinciClient.poll`, then submit the node with
/// `DaVinciClient.next`: the native collector keeps the value the poll ended with (`continue`,
/// `approved`, `timedOut`, …), so the app sets nothing.
///
/// Two modes, picked by the server:
///
/// - **Simple** ([pollChallengeStatus] `false`): each poll waits [pollInterval] once and ends with
///   [PollingComplete] `continue`, or [PollingTimedOut] on the last retry. Submitting
///   `continue` makes the server send this form again, with [retriesAllowed] one lower.
/// - **Challenge** ([pollChallengeStatus] `true`): each poll asks the server about [challenge]
///   every [pollInterval], up to [pollRetries] times, reporting a [PollingContinue] per
///   incomplete attempt, until it completes, expires or times out.
final class PollingCollector extends Collector {
  PollingCollector._(super.message)
    : pollInterval = Duration(milliseconds: message.pollIntervalMillis ?? 0),
      pollRetries = message.pollRetries ?? 0,
      retriesAllowed = message.retriesAllowed ?? 0,
      pollChallengeStatus = message.pollChallengeStatus ?? false,
      challenge = message.challenge,
      super._();

  /// The wait before each attempt.
  final Duration pollInterval;

  /// The number of attempts allowed.
  final int pollRetries;

  /// The simple-polling cycles left, counted down across the server's repeats of this form.
  final int retriesAllowed;

  /// Whether polling asks the server about [challenge], rather than only waiting.
  final bool pollChallengeStatus;

  /// The challenge whose status is polled, or `null` in simple mode.
  final String? challenge;

  /// Nothing: polling sets the native value itself.
  @override
  CollectorValueMessage? toValue() => null;
}
