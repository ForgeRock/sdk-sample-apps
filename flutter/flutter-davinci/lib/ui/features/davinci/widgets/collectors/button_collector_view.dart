/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'package:flutter_davinci/ui/core/widgets/primary_button.dart';

/// A button that submits the form: the brand button for `SUBMIT_BUTTON`, an outlined one for
/// `FLOW_BUTTON`, a text link for `FLOW_LINK`.
class ButtonCollectorView extends StatelessWidget {
  const ButtonCollectorView({
    super.key,
    required this.collector,
    required this.onPressed,
    required this.loading,
  });

  final ButtonCollector collector;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final label = collector.label.isEmpty ? collector.key : collector.label;
    return switch (collector) {
      SubmitCollector() => PrimaryButton(
        label: label,
        onPressed: onPressed,
        loading: loading,
      ),
      FlowCollector(type: 'FLOW_LINK') => Center(
        child: TextButton(
          onPressed: loading ? null : onPressed,
          child: Text(label),
        ),
      ),
      FlowCollector() => OutlinedButton(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: loading ? null : onPressed,
        child: Text(label),
      ),
    };
  }
}
