/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ping_example/core/widgets/brand_logo.dart';
import 'package:ping_example/core/widgets/primary_button.dart';
import 'package:ping_example/features/davinci/ui/config/view_models/flow_settings_view_model.dart';

/// The one DaVinci setting that changes per run: the `acr_values` that pick which flow starts.
/// The rest of the configuration is on the Environments screen.
class DaVinciConfigView extends StatefulWidget {
  const DaVinciConfigView({super.key, required this.onStart});

  /// Starts the flow [acrValues] selects (empty for the application's default policy).
  final Future<void> Function(String acrValues) onStart;

  @override
  State<DaVinciConfigView> createState() => _ConfigViewState();
}

class _ConfigViewState extends State<DaVinciConfigView> {
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
      appBar: AppBar(title: const Text('Start a DaVinci Flow')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: BrandLogo(size: 96)),
            const SizedBox(height: 32),
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
