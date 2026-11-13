/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/collector_support.dart';

/// A choice of MFA device: a type to enrol (`DEVICE_REGISTRATION`) or an enrolled device to
/// authenticate with (`DEVICE_AUTHENTICATION`, its default marked).
class DeviceCollectorView extends StatelessWidget {
  const DeviceCollectorView({
    super.key,
    required this.collector,
    required this.onChanged,
  });

  final DeviceCollector collector;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (collector.label.isNotEmpty) Text(fieldLabel(collector)),
        RadioGroup<Device>(
          groupValue: collector.value,
          onChanged: (device) {
            if (device == null) return;
            collector.selectDevice(device);
            onChanged();
          },
          child: Column(
            children: [
              for (final device in collector.devices)
                RadioListTile<Device>(
                  contentPadding: EdgeInsets.zero,
                  value: device,
                  title: Text(device.title ?? device.type),
                  subtitle: switch ((device.description, device.isDefault)) {
                    (final String text, true) when text.isNotEmpty => Text(
                      '$text · default',
                    ),
                    (final String text, false) when text.isNotEmpty => Text(
                      text,
                    ),
                    (_, true) => const Text('Default'),
                    _ => null,
                  },
                ),
            ],
          ),
        ),
        FieldErrorText(collector: collector),
      ],
    );
  }
}
