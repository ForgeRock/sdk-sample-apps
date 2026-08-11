/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';

import 'package:flutter_journey/ui/core/theme/app_theme.dart';

/// The Ping Identity brand mark, rendered at [size]. Falls back to a simple icon + wordmark
/// lockup if the `assets/images/ping_logo.png` asset failed to load.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 80});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/ping_logo.png',
      height: size,
      width: size,
      errorBuilder: (context, error, stackTrace) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.shield, color: AppTheme.brandRed, size: size * 0.6),
        const SizedBox(height: 4),
        Text(
          'PING IDENTITY',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.brandRed,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
