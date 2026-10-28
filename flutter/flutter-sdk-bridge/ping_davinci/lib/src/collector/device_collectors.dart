/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'collector.dart';

/// A choice of MFA device: [DeviceRegistrationCollector] or [DeviceAuthenticationCollector].
///
/// Call [selectDevice] with one of [devices], then press a button and `DaVinciClient.next`. The
/// native collector builds the payload from its own device, so the bridge only says which one.
sealed class DeviceCollector extends FieldCollector<Device?> {
  DeviceCollector._(CollectorMessage message)
    : devices = List<Device>.unmodifiable(<Device>[
        for (final device
            in message.devices?.whereType<DeviceMessage>() ??
                const <DeviceMessage>[])
          Device.fromMessage(device),
      ]),
      super._(message, null);

  /// The devices to choose from, in the server's order.
  final List<Device> devices;

  /// Chooses [device], which must be one of [devices].
  void selectDevice(Device device) {
    if (!devices.contains(device)) {
      throw ArgumentError.value(device, 'device', 'is not one of devices');
    }
    value = device;
  }

  /// `{id, type}`: native matches by id when there is one, else by type.
  @override
  Object? get _wireValue => switch (_value) {
    final Device device => <String, Object?>{
      'id': ?device.id,
      'type': device.type,
    },
    null => null,
  };
}

/// The kind of device to enrol (`DEVICE_REGISTRATION`): its [devices] are types, with no id.
/// Natively, the submitted payload is the chosen device's `type`.
final class DeviceRegistrationCollector extends DeviceCollector {
  DeviceRegistrationCollector._(super.message) : super._();
}

/// The enrolled device to authenticate with (`DEVICE_AUTHENTICATION`): its [devices] have ids,
/// and one may be [Device.isDefault]. Natively, the submitted payload is the device's `type`,
/// `id` and `description`. The server offers it only to a signed-in user.
final class DeviceAuthenticationCollector extends DeviceCollector {
  DeviceAuthenticationCollector._(super.message) : super._();
}
