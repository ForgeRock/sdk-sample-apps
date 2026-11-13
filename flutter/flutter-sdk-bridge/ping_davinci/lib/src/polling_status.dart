/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'messages.g.dart';

/// One status of a running poll, from `DaVinciClient.poll`.
///
/// A poll reports zero or more [PollingContinue]s, then exactly one terminal status
/// ([isTerminal]), then closes. The sequence is the same on both platforms: the bridge reorders
/// iOS's to match Android's (see `PingDaVinciHostApi.startPolling`). The native collector keeps
/// the matching value (`continue`, the completed status, `timedOut`, `expired`, `error`) for
/// the next `DaVinciClient.next`.
sealed class PollingStatus {
  const PollingStatus();

  /// Re-inflates a [PollingEventMessage].
  factory PollingStatus.fromMessage(PollingEventMessage message) =>
      switch (message.kind) {
        PollingStatusKind.continuing => PollingContinue(
          retryCount: message.retryCount ?? 0,
          maxRetries: message.maxRetries ?? 0,
        ),
        PollingStatusKind.timedOut => const PollingTimedOut(),
        PollingStatusKind.expired => const PollingExpired(),
        PollingStatusKind.error => PollingError(
          message.errorMessage ?? 'Polling failed',
        ),
        PollingStatusKind.complete => PollingComplete(message.status ?? ''),
      };

  /// Whether this status ends the poll.
  bool get isTerminal => true;
}

/// An attempt came back incomplete; polling goes on (challenge mode only).
final class PollingContinue extends PollingStatus {
  /// Creates an in-progress status.
  const PollingContinue({required this.retryCount, required this.maxRetries});

  /// The attempt that came back incomplete, from 1.
  final int retryCount;

  /// The number of attempts allowed.
  final int maxRetries;

  @override
  bool get isTerminal => false;

  @override
  bool operator ==(Object other) =>
      other is PollingContinue &&
      other.retryCount == retryCount &&
      other.maxRetries == maxRetries;

  @override
  int get hashCode => Object.hash(retryCount, maxRetries);

  @override
  String toString() => 'PollingContinue($retryCount/$maxRetries)';
}

/// Every attempt was used without an answer. Submitting sends `timedOut`; the server usually
/// answers with an error.
final class PollingTimedOut extends PollingStatus {
  /// Creates a timed-out status.
  const PollingTimedOut();

  @override
  bool operator ==(Object other) => other is PollingTimedOut;

  @override
  int get hashCode => (PollingTimedOut).hashCode;

  @override
  String toString() => 'PollingTimedOut()';
}

/// The server reports the challenge expired.
///
/// **Platform difference (native 2.2.0):** iOS reports any `4xx` status response as expired and
/// retries a `5xx`; Android reports a non-`200` response as expired only when its `serviceName`
/// is `challengeExpired`, and as a [PollingError] otherwise.
final class PollingExpired extends PollingStatus {
  /// Creates an expired status.
  const PollingExpired();

  @override
  bool operator ==(Object other) => other is PollingExpired;

  @override
  int get hashCode => (PollingExpired).hashCode;

  @override
  String toString() => 'PollingExpired()';
}

/// Polling failed: a network error, an unreadable response, or a misconfigured collector.
final class PollingError extends PollingStatus {
  /// Creates a failed status.
  const PollingError(this.message);

  /// What failed, from the native SDK. Not localized.
  final String message;

  @override
  bool operator ==(Object other) =>
      other is PollingError && other.message == message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'PollingError($message)';
}

/// The poll finished: [status] is the server's (e.g. `approved`), or `continue` for a
/// simple-polling cycle.
final class PollingComplete extends PollingStatus {
  /// Creates a completed status.
  const PollingComplete(this.status);

  /// The server's status.
  final String status;

  @override
  bool operator ==(Object other) =>
      other is PollingComplete && other.status == status;

  @override
  int get hashCode => status.hashCode;

  @override
  String toString() => 'PollingComplete($status)';
}
