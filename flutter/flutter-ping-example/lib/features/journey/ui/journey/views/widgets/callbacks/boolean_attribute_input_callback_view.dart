/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_journey/ping_journey.dart';

class BooleanAttributeInputCallbackView extends StatelessWidget {
  const BooleanAttributeInputCallbackView({
    super.key,
    required this.callback,
    required this.onChanged,
  });

  final BooleanAttributeInputCallback callback;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final label = callback.prompt ?? callback.name;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(callback.required ? '$label *' : label),
      value: callback.value,
      onChanged: (value) {
        callback.value = value;
        onChanged();
      },
    );
  }
}
