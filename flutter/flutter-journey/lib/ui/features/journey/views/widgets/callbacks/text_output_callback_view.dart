/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_journey/ping_journey.dart';

class TextOutputCallbackView extends StatelessWidget {
  const TextOutputCallbackView({super.key, required this.callback});

  final TextOutputCallback callback;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (callback.messageType) {
      TextOutputMessageType.information => (Icons.info, scheme.primary),
      TextOutputMessageType.warning => (Icons.warning, Colors.orange),
      TextOutputMessageType.error => (Icons.error, scheme.error),
      TextOutputMessageType.script ||
      TextOutputMessageType.unknown => (
        Icons.settings,
        scheme.onSurfaceVariant,
      ),
    };

    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(callback.message)),
      ],
    );
  }
}
