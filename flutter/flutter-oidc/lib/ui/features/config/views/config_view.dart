/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';

import 'package:flutter_oidc/config/env.dart';
import 'package:flutter_oidc/ui/core/theme/app_theme.dart';
import 'package:flutter_oidc/ui/core/widgets/app_card.dart';
import 'package:flutter_oidc/ui/core/widgets/brand_logo.dart';
import 'package:flutter_oidc/ui/core/widgets/primary_button.dart';
import 'package:ping_oidc/ping_oidc.dart';

/// Read-only display of the active [Env.oidcConfig], shown before starting the browser login.
///
/// [oidcConfig] defaults to [Env.oidcConfig] but is injectable so a caller can exercise this
/// view with a real (non-placeholder) config without overriding the app-wide [Env] singleton.
class ConfigView extends StatelessWidget {
  const ConfigView({
    super.key,
    required this.onContinue,
    this.oidcConfig = Env.oidcConfig,
  });

  final VoidCallback onContinue;
  final OidcConfig oidcConfig;

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
                  _ConfigRow(label: 'Client ID', value: oidcConfig.clientId),
                  _ConfigRow(
                    label: 'Discovery Endpoint',
                    value: oidcConfig.discoveryEndpoint ?? '(none — explicit openId)',
                  ),
                  _ConfigRow(
                    label: 'Redirect URI',
                    value: oidcConfig.redirectUri ?? '(none)',
                  ),
                  _ConfigRow(
                    label: 'Scopes',
                    value: oidcConfig.scopes.join(', '),
                  ),
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
