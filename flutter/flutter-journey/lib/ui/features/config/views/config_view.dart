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
///
/// [serverUrl]/[realm]/[cookie]/[oidcConfig] default to [Env]'s values but are injectable so
/// tests can exercise a real (non-placeholder) config without depending on — or overriding —
/// the app-wide [Env] singleton.
class ConfigView extends StatelessWidget {
  const ConfigView({
    super.key,
    required this.onContinue,
    this.serverUrl = Env.serverUrl,
    this.realm = Env.realm,
    this.cookie = Env.cookie,
    this.oidcConfig = Env.oidcConfig,
  });

  final VoidCallback onContinue;
  final String serverUrl;
  final String realm;
  final String cookie;
  final OidcConfig? oidcConfig;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Environment')),
      body: SingleChildScrollView(
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
                  _ConfigRow(label: 'Server URL', value: serverUrl),
                  _ConfigRow(label: 'Realm', value: realm),
                  _ConfigRow(label: 'Cookie', value: cookie),
                  if (oidcConfig case final oidc?) ...[
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
            const SizedBox(height: 24),
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
