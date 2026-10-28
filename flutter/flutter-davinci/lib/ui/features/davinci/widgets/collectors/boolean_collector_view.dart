/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/collector_support.dart';

/// A yes/no field (`SINGLE_CHECKBOX`), drawn as a checkbox or a switch as the server's
/// `appearance` asks. Its label keeps any links the server put in it.
class BooleanCollectorView extends StatelessWidget {
  const BooleanCollectorView({
    super.key,
    required this.collector,
    required this.onChanged,
  });

  final BooleanCollector collector;
  final VoidCallback onChanged;

  void _set(bool? value) {
    collector.value = value ?? false;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (collector.richContent) {
      final RichContent richContent => RichContentText(
        richContent: richContent,
      ),
      null => Text(fieldLabel(collector)),
    };
    final subtitle = fieldErrorText(collector) == null
        ? null
        : FieldErrorText(collector: collector);
    return switch (collector.appearance) {
      BooleanAppearance.toggleSwitch => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: title,
        subtitle: subtitle,
        value: collector.value,
        onChanged: _set,
      ),
      BooleanAppearance.checkbox => CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: title,
        subtitle: subtitle,
        value: collector.value,
        onChanged: _set,
      ),
    };
  }
}
