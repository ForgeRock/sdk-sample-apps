/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:ping_journey/ping_journey.dart';

import 'device_profile_callback.dart';

/// The server's wire type for [DeviceProfileCallback].
const String _deviceProfileCallbackType = 'DeviceProfileCallback';

/// The package registrant: registers everything this package contributes to the Dart side of the
/// bridge.
///
/// The plugin's `dartPluginClass` points here, so Flutter's generated plugin registrant calls
/// [registerWith] before `main()` on both platforms and apps need no setup code. Registration
/// lives on the package rather than on one callback so that a package contributing several types
/// (FIDO, external IdP) follows the same pattern: add its registrations to [registerWith].
class PingDeviceProfile {
  const PingDeviceProfile._();

  /// Registers this package's callback types with `ping_journey`'s add-on callback registry:
  /// [DeviceProfileCallback] under the server's `DeviceProfileCallback` type.
  ///
  /// Called automatically at app startup through the plugin's `dartPluginClass` hook. Calling it
  /// again is harmless — a later registration replaces the earlier one.
  static void registerWith() => Callback.registerAddOn(
    _deviceProfileCallbackType,
    DeviceProfileCallback.new,
  );
}
