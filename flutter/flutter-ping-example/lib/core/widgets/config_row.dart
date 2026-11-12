/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ping_example/core/theme/app_theme.dart';

/// Whether [value] is empty or still one of the `<placeholder>` defaults from an `Env` class.
bool isUnsetConfigValue(String value) =>
    value.isEmpty || (value.startsWith('<') && value.endsWith('>'));

/// A labelled configuration value. Tapping it copies the value; a value that was never configured
/// shows "Not configured" in the error color instead.
class ConfigRow extends StatelessWidget {
  const ConfigRow({
    super.key,
    required this.label,
    required this.value,
    this.copyable = true,
  });

  final String label;
  final String value;

  /// `false` for descriptive text that isn't a real configuration value.
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unset = isUnsetConfigValue(value);
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
      onTap: unset || !copyable ? null : () => _copy(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: AppTheme.sectionHeader(context)),
            const SizedBox(height: 2),
            Text(
              unset ? 'Not configured' : value,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: unset ? theme.colorScheme.error : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: value));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Copied $label')));
  }
}
