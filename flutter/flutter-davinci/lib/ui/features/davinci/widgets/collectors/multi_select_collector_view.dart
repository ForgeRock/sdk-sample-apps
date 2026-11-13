/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/collector_support.dart';

/// Any number of choices: a checkbox list for `CHECKBOX`, filter chips for `COMBOBOX`.
class MultiSelectCollectorView extends StatelessWidget {
  const MultiSelectCollectorView({
    super.key,
    required this.collector,
    required this.onChanged,
  });

  final MultiSelectCollector collector;
  final VoidCallback onChanged;

  void _toggle(Option option, bool selected) {
    // The value list is unmodifiable: assign a new one.
    collector.value = [
      for (final value in collector.value)
        if (value != option.value) value,
      if (selected) option.value,
    ];
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final chosen = collector.value.toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(fieldLabel(collector)),
        if (collector.type == 'COMBOBOX')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final option in collector.options)
                  FilterChip(
                    label: Text(option.label),
                    selected: chosen.contains(option.value),
                    onSelected: (selected) => _toggle(option, selected),
                  ),
              ],
            ),
          )
        else
          for (final option in collector.options)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(option.label),
              value: chosen.contains(option.value),
              onChanged: (selected) => _toggle(option, selected ?? false),
            ),
        FieldErrorText(collector: collector),
      ],
    );
  }
}
