// Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/src/main/kotlin/com/pingidentity/flutter/deviceprofile/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.pingidentity.flutter.deviceprofile'),
    swiftOut:
        'ios/ping_device_profile/Sources/ping_device_profile/Messages.g.swift',
    swiftOptions: SwiftOptions(),
    copyrightHeader: 'pigeons/copyright.txt',
    dartPackageName: 'ping_device_profile',
  ),
)
/// Device profile collection for a Journey's `DeviceProfileCallback`.
///
/// Stateless: the live callback is resolved on every call from the Journey's handle, through
/// `ping_core`'s `ActiveNodeAccess`, so this API has no configure/dispose lifecycle of its own.
@HostApi()
abstract class PingDeviceProfileHostApi {
  /// Runs the native device profile collection on the `DeviceProfileCallback` at
  /// [callbackIndex] (0-based among `DeviceProfileCallback`s) in the current node of the Journey
  /// [journeyId], and returns the collected profile.
  ///
  /// The native SDK also stores the profile on the callback itself, so after this completes the
  /// app only has to submit the node with `JourneyClient.next`.
  ///
  /// The profile is the native SDK's own JSON (device identifier, metadata, location); its shape
  /// differs by platform and by which collectors ran, so it is returned as a plain map. It can
  /// contain a device identifier and location, so it must never be logged.
  @async
  Map<String?, Object?> collect(String journeyId, int callbackIndex);
}
