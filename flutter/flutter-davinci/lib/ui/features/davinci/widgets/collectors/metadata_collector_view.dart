/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'package:flutter_davinci/ui/core/theme/app_theme.dart';
import 'package:flutter_davinci/ui/core/widgets/app_card.dart';
import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/collector_support.dart';

/// The flow is paused at a DaVinci SDK Integrator connector (`METADATA`), waiting for the app.
///
/// A real app would read [MetadataCollector.metadata], do the work it describes, and report the
/// outcome. The sample shows the metadata and lets the user pick either branch by hand: a JSON
/// result, or a client error.
class MetadataCollectorView extends StatelessWidget {
  const MetadataCollectorView({
    super.key,
    required this.collector,
    required this.onChanged,
  });

  final MetadataCollector collector;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final chosen = switch (collector.value) {
      MetadataSuccess() => 'Result set. Continue to send it.',
      MetadataFailure(:final code) => 'Error $code set. Continue to send it.',
      null => 'The flow is waiting for the app to return a result.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Metadata', style: AppTheme.sectionHeader(context)),
        const SizedBox(height: 4),
        AppCard(
          padding: const EdgeInsets.all(8),
          child: SelectableText(
            const JsonEncoder.withIndent('  ').convert(collector.metadata),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ),
        const SizedBox(height: 8),
        Text(chosen),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  collector.setResult({
                    'source': 'flutter-davinci',
                    'completed': true,
                  });
                  onChanged();
                },
                child: const Text('Return result'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  collector.setError(
                    'USER_CANCELLED',
                    'The user cancelled in the sample app.',
                  );
                  onChanged();
                },
                child: const Text('Return error'),
              ),
            ),
          ],
        ),
        FieldErrorText(collector: collector),
      ],
    );
  }
}
