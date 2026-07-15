/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_journey/ping_journey.dart';

class TermsAndConditionsCallbackView extends StatelessWidget {
  const TermsAndConditionsCallbackView({
    super.key,
    required this.callback,
    required this.onChanged,
  });

  final TermsAndConditionsCallback callback;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (callback.version.isNotEmpty) Text('Version: ${callback.version}'),
        if (callback.createDate.isNotEmpty)
          Text('Date: ${callback.createDate}'),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 160),
          child: SingleChildScrollView(child: Text(callback.terms)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('I accept the terms and conditions'),
          value: callback.accepted,
          onChanged: (value) {
            callback.accepted = value;
            onChanged();
          },
        ),
      ],
    );
  }
}
