/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/collector_support.dart';

/// A `PASSWORD` or `PASSWORD_VERIFY` field, obscured, with the password policy (when the server
/// sends one) shown as a hint so the user sees the rules before submitting.
class PasswordCollectorView extends StatefulWidget {
  const PasswordCollectorView({
    super.key,
    required this.collector,
    required this.onChanged,
  });

  final PasswordCollector collector;
  final VoidCallback onChanged;

  /// One line describing [policy], or `null` when it sets no rule.
  static String? policyHint(PasswordPolicy? policy) {
    if (policy == null) return null;
    final rules = [
      if (policy.lengthMax case final max?)
        '${policy.lengthMin}–$max characters'
      else if (policy.lengthMin > 0)
        'at least ${policy.lengthMin} characters',
      if (policy.minUniqueCharacters > 0)
        '${policy.minUniqueCharacters} different characters',
      if (policy.maxRepeatedCharacters case final max?)
        'no character more than $max times',
      for (final MapEntry(:key, :value) in policy.minCharacters.entries)
        '$value+ ${_describe(key)}',
    ];
    return rules.isEmpty ? null : 'Use ${rules.join(', ')}.';
  }

  static String _describe(String characters) {
    bool all(bool Function(int) test) => characters.runes.every(test);
    if (all((c) => c >= 0x30 && c <= 0x39)) return 'digits';
    if (all((c) => c >= 0x61 && c <= 0x7A)) return 'lowercase letters';
    if (all((c) => c >= 0x41 && c <= 0x5A)) return 'uppercase letters';
    return 'of $characters';
  }

  @override
  State<PasswordCollectorView> createState() => _PasswordCollectorViewState();
}

class _PasswordCollectorViewState extends State<PasswordCollectorView>
    with ControllersState<PasswordCollectorView> {
  // A password never crosses the bridge from native, so the field always starts empty —
  // including on the form an ErrorNode hands back.
  late final _controller = TextEditingController(text: widget.collector.value);
  bool _obscure = true;

  @override
  List<TextEditingController> get controllers => [_controller];

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: fieldLabel(widget.collector),
        helperText: PasswordCollectorView.policyHint(
          widget.collector.passwordPolicy,
        ),
        helperMaxLines: 3,
        errorText: fieldErrorText(widget.collector),
        errorMaxLines: 8,
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      onChanged: (value) {
        widget.collector.value = value;
        widget.onChanged();
      },
    );
  }
}
