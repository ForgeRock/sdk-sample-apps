/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';

import 'package:flutter_journey/config/env.dart';
import 'package:flutter_journey/ui/core/theme/app_theme.dart';
import 'package:flutter_journey/ui/core/widgets/app_card.dart';
import 'package:flutter_journey/ui/core/widgets/brand_logo.dart';
import 'package:flutter_journey/ui/core/widgets/primary_button.dart';

/// Read-only display of the active [Env] — analog of the native samples' server/realm config
/// screen (Android's `Env.kt`), shown before starting a Journey.
class ConfigView extends StatelessWidget {
  const ConfigView({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Environment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: BrandLogo(size: 72)),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ConfigRow(label: 'Server URL', value: Env.serverUrl),
                  _ConfigRow(label: 'Realm', value: Env.realm),
                  _ConfigRow(label: 'Cookie', value: Env.cookie),
                  if (Env.oidcConfig case final oidc?) ...[
                    _ConfigRow(label: 'Client ID', value: oidc.clientId),
                    _ConfigRow(
                      label: 'Discovery Endpoint',
                      value: oidc.discoveryEndpoint,
                    ),
                    _ConfigRow(label: 'Redirect URI', value: oidc.redirectUri),
                  ],
                ],
              ),
            ),
            const Spacer(),
            PrimaryButton(label: 'Continue', onPressed: onContinue),
          ],
        ),
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTheme.sectionHeader(context)),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
