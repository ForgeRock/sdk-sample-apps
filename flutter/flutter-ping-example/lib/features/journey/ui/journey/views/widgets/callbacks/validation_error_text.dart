/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';

/// Shared inline validation-error display for the Validated*/Attribute*Input callback family,
/// driven by [failedPolicies] (`{"policyRequirement": ..., "params": ...}` entries) —
/// analog of the native samples' `ErrorMessageView`/`supportingText` error rendering.
class ValidationErrorText extends StatelessWidget {
  const ValidationErrorText({super.key, required this.failedPolicies});

  final List<Map<String, Object?>> failedPolicies;

  /// Sentinel [TextField.decoration.errorText] value that triggers Material's themed
  /// `errorBorder` without duplicating the message already shown by [ValidationErrorText]
  /// underneath. Returns `null` (no error) when [failedPolicies] and [hasLocalError] are both
  /// clear, or `''` (empty-string sentinel) otherwise.
  static String? errorTextFor(
    List<Map<String, Object?>> failedPolicies, {
    bool hasLocalError = false,
  }) => failedPolicies.isNotEmpty || hasLocalError ? '' : null;

  @override
  Widget build(BuildContext context) {
    if (failedPolicies.isEmpty) return const SizedBox.shrink();
    final message = failedPolicies
        .map((policy) => policy['policyRequirement'] as String? ?? 'INVALID')
        .join(', ');
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
