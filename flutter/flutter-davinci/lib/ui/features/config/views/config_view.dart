/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_davinci/config/env.dart';
import 'package:flutter_davinci/ui/core/theme/app_theme.dart';
import 'package:flutter_davinci/ui/core/widgets/app_card.dart';
import 'package:flutter_davinci/ui/core/widgets/brand_logo.dart';
import 'package:flutter_davinci/ui/core/widgets/primary_button.dart';
import 'package:flutter_davinci/ui/features/config/view_models/flow_settings_view_model.dart';

/// Read-only display of the active [Env], plus the one setting that changes per run: the
/// `acr_values` that pick which DaVinci flow starts.
class ConfigView extends StatefulWidget {
  const ConfigView({super.key, required this.onStart});

  /// Starts the flow [acrValues] selects (empty for the application's default policy).
  final Future<void> Function(String acrValues) onStart;

  @override
  State<ConfigView> createState() => _ConfigViewState();
}

class _ConfigViewState extends State<ConfigView> {
  late final FlowSettingsViewModel _settings;
  late final TextEditingController _acrValues;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _settings = context.read<FlowSettingsViewModel>();
    _acrValues = TextEditingController(text: _settings.acrValues);
    // load() may still be running: pick up the saved value when it lands.
    _settings.addListener(_onSettingsLoaded);
  }

  void _onSettingsLoaded() {
    _settings.removeListener(_onSettingsLoaded);
    _acrValues.text = _settings.acrValues;
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsLoaded);
    _acrValues.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final acrValues = _acrValues.text.trim();
    setState(() => _starting = true);
    await _settings.save(acrValues);
    await widget.onStart(acrValues);
    if (mounted) setState(() => _starting = false);
  }

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
                  _ConfigRow(
                    label: 'Discovery Endpoint',
                    value: Env.discoveryEndpoint,
                  ),
                  _ConfigRow(label: 'Client ID', value: Env.clientId),
                  _ConfigRow(label: 'Redirect URI', value: Env.redirectUri),
                  _ConfigRow(label: 'Scopes', value: Env.scopes.join(' ')),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _acrValues,
              decoration: const InputDecoration(
                labelText: 'ACR values (flow policy)',
                helperText:
                    "Leave empty to run the application's default flow.",
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Start',
              onPressed: _start,
              loading: _starting,
            ),
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
