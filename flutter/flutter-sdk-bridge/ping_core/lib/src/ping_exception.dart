/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// Typed exception surfaced to Dart callers for any native-side failure.
///
/// Carries a stable [code], a [type] classification, and a human-readable
/// [message].
class PingException implements Exception {
  /// Stable, native-side error code (e.g. `JOURNEY_START_ERROR`).
  final String code;

  /// Coarse-grained classification of [code] (e.g. `state`, `argument`, `network`).
  final String type;

  /// Human-readable description of the failure.
  final String message;

  /// Creates a [PingException] with the given [code], [type], and [message].
  const PingException(this.code, this.type, this.message);

  @override
  String toString() =>
      'PingException(code: $code, type: $type, message: $message)';
}
