/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_journey/ping_journey.dart';

class ChoiceCallbackView extends StatelessWidget {
  const ChoiceCallbackView({
    super.key,
    required this.callback,
    required this.onChanged,
  });

  final ChoiceCallback callback;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: callback.selectedIndex,
      decoration: InputDecoration(
        labelText: callback.prompt ?? 'Choice',
      ),
      items: [
        for (final (index, choice) in callback.choices.indexed)
          DropdownMenuItem(value: index, child: Text(choice)),
      ],
      onChanged: (value) {
        if (value == null) return;
        callback.selectedIndex = value;
        onChanged();
      },
    );
  }
}
