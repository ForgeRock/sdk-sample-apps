/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/collector_support.dart';

/// A single choice: a radio group for `RADIO`, a dropdown for `DROPDOWN` (and any other type
/// the server maps to a single select).
class SingleSelectCollectorView extends StatelessWidget {
  const SingleSelectCollectorView({
    super.key,
    required this.collector,
    required this.onChanged,
  });

  final SingleSelectCollector collector;
  final VoidCallback onChanged;

  void _select(String? value) {
    if (value == null) return;
    collector.value = value;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final selected = collector.value.isEmpty ? null : collector.value;
    if (collector.type == 'RADIO') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fieldLabel(collector)),
          RadioGroup<String>(
            groupValue: selected,
            onChanged: _select,
            child: Column(
              children: [
                for (final option in collector.options)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: option.value,
                    title: Text(option.label),
                  ),
              ],
            ),
          ),
          FieldErrorText(collector: collector),
        ],
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: fieldLabel(collector),
        errorText: fieldErrorText(collector),
        errorMaxLines: 5,
      ),
      items: [
        for (final option in collector.options)
          DropdownMenuItem(value: option.value, child: Text(option.label)),
      ],
      onChanged: _select,
    );
  }
}
