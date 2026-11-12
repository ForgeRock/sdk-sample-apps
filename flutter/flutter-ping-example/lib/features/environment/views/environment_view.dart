/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ping_example/core/session/session_coordinator.dart';
import 'package:ping_example/core/theme/app_theme.dart';
import 'package:ping_example/core/widgets/app_card.dart';
import 'package:ping_example/core/widgets/config_row.dart';
import 'package:ping_example/core/widgets/icon_tile.dart';
import 'package:ping_example/features/davinci/config/davinci_env.dart';
import 'package:ping_example/features/davinci/ui/config/view_models/flow_settings_view_model.dart';
import 'package:ping_example/features/environment/flow_configuration.dart';
import 'package:ping_example/features/journey/config/journey_env.dart';
import 'package:ping_example/features/oidc/config/oidc_env.dart';

/// Read-only overview of the configuration each flow was built with, side by side, so a missing or
/// wrong value is visible before starting a flow.
class EnvironmentView extends StatelessWidget {
  const EnvironmentView({super.key});

  @override
  Widget build(BuildContext context) {
    final acrValues = context.watch<FlowSettingsViewModel>().acrValues;
    return Scaffold(
      appBar: AppBar(title: const Text('Environments')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'What this build was configured with. Tap a value to copy it.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _FlowSection(
            flow: PingFlow.journey,
            rows: [
              const ConfigRow(label: 'Server URL', value: JourneyEnv.serverUrl),
              const ConfigRow(label: 'Realm', value: JourneyEnv.realm),
              const ConfigRow(label: 'Cookie', value: JourneyEnv.cookie),
              const ConfigRow(label: 'Client ID', value: JourneyEnv.clientId),
              const ConfigRow(
                label: 'Discovery endpoint',
                value: JourneyEnv.discoveryEndpoint,
              ),
              const ConfigRow(
                label: 'Redirect URI',
                value: JourneyEnv.redirectUri,
              ),
              ConfigRow(label: 'Scopes', value: JourneyEnv.scopes.join(' ')),
              ConfigRow(
                label: 'Token exchange',
                value: JourneyEnv.oidcConfig == null
                    ? 'Disabled: session only, no OIDC client configured'
                    : 'Enabled after a successful journey',
                copyable: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FlowSection(
            flow: PingFlow.davinci,
            rows: [
              const ConfigRow(
                label: 'Discovery endpoint',
                value: DaVinciEnv.discoveryEndpoint,
              ),
              const ConfigRow(label: 'Client ID', value: DaVinciEnv.clientId),
              const ConfigRow(
                label: 'Redirect URI',
                value: DaVinciEnv.redirectUri,
              ),
              ConfigRow(label: 'Scopes', value: DaVinciEnv.scopes.join(' ')),
              ConfigRow(
                label: 'ACR values (next run)',
                value: acrValues.isEmpty
                    ? "Empty: the application's default flow"
                    : acrValues,
                copyable: acrValues.isNotEmpty,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FlowSection(
            flow: PingFlow.oidc,
            rows: [
              const ConfigRow(
                label: 'Discovery endpoint',
                value: OidcEnv.discoveryEndpoint,
              ),
              const ConfigRow(label: 'Client ID', value: OidcEnv.clientId),
              const ConfigRow(
                label: 'Redirect URI',
                value: OidcEnv.redirectUri,
              ),
              ConfigRow(
                label: 'Sign-out redirect URI',
                value: OidcEnv.signOutRedirectUri ?? 'None',
                copyable: OidcEnv.signOutRedirectUri != null,
              ),
              ConfigRow(label: 'Scopes', value: OidcEnv.scopes.join(' ')),
            ],
          ),
        ],
      ),
    );
  }
}

/// One flow's card: title, whether its required values are all set, then its rows.
class _FlowSection extends StatelessWidget {
  const _FlowSection({required this.flow, required this.rows});

  final PingFlow flow;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final complete = flow.isConfigured;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: flow.icon, size: 36, iconSize: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(flow.title, style: theme.textTheme.titleMedium),
              ),
              Icon(
                complete
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.exclamationmark_triangle_fill,
                size: 18,
                color: complete
                    ? AppTheme.colors(context).statusSuccess
                    : AppTheme.colors(context).statusWarning,
              ),
              const SizedBox(width: 4),
              Text(
                complete ? 'Configured' : 'Incomplete',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }
}
