/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/services.dart';
import 'package:ping_journey/ping_journey.dart';

import 'messages.g.dart';

/// A Journey callback that collects the device's profile (identifier, metadata, location) during
/// authentication, contributed by this add-on package.
///
/// The server drives what is collected through the callback's `metadata` and `location` flags.
/// Rendering: there is normally nothing to show — collection is automatic, so a UI typically
/// displays a progress indicator while [collect] runs and then submits the node with
/// `JourneyClient.next`.
///
/// The profile itself never crosses back into Dart for submission: the native SDK stores it on
/// the callback, and the generic `JourneyClient.next` sends it. [collect] returns it only so the
/// app can display or audit it.
final class DeviceProfileCallback extends AddOnCallback {
  /// Creates a device profile callback from its wire [message] and the node's [journeyId].
  /// Called by `NodeMapper` once `PingDeviceProfile.registerWith` has registered this class.
  ///
  /// [hostApi] is for tests only; production callers get the default channel-backed API.
  DeviceProfileCallback(super.message, super.journeyId, {PingDeviceProfileHostApi? hostApi})
    : _hostApi = hostApi ?? PingDeviceProfileHostApi();

  final PingDeviceProfileHostApi _hostApi;

  /// Whether the server asked for device metadata (platform, hardware, network, ...).
  bool get metadata => _flag('metadata');

  /// Whether the server asked for the device's location.
  bool get location => _flag('location');

  /// The server's message about the collection, if any.
  String get message => _outputField('message') as String? ?? '';

  /// The server sends its fields in the callback JSON's `output` array as `{name, value}` pairs
  /// (the native SDK populates them through `initValue`), not as top-level JSON keys.
  Object? _outputField(String name) {
    final output = raw['output'];
    if (output is! List<Object?>) return null;
    for (final entry in output) {
      if (entry is Map<String, Object?> && entry['name'] == name) {
        return entry['value'];
      }
    }
    return null;
  }

  bool _flag(String name) => _outputField(name) == true;

  /// Runs the native device profile collection and returns the collected profile.
  ///
  /// The native SDK also stores the profile on the callback itself, so after this completes the
  /// app only has to submit the node with `JourneyClient.next`.
  ///
  /// Throws a [PingException] (type `state`) when the Journey has no active node, (type
  /// `argument`) when the node no longer holds this callback, (type `permission`, Android only)
  /// when a collection permission was denied, or (type `unknown`) for a native collection
  /// failure — including denied location access on iOS, whose error type the native SDK keeps
  /// internal.
  Future<Map<String, Object?>> collect() async {
    final result = await _guard(() => _hostApi.collect(journeyId, index));
    return result.cast<String, Object?>();
  }
}

Future<T> _guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on PlatformException catch (error) {
    throw PingException(
      error.code,
      error.details is String ? error.details as String : 'unknown',
      error.message ?? 'Unknown device profile error',
    );
  }
}
