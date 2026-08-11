/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_journey/ui/core/widgets/brand_logo.dart';
import 'package:flutter_journey/ui/core/widgets/primary_button.dart';
import 'package:flutter_journey/ui/features/config/view_models/journey_name_view_model.dart';

/// Text field for the Journey to start, pre-filled with the last-used name — analog of the
/// native samples' journey-name entry screen (Android's `JourneyRoute.kt`, iOS's
/// `JourneyNameInputView`).
class JourneyNameView extends StatefulWidget {
  const JourneyNameView({super.key, required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<JourneyNameView> createState() => _JourneyNameViewState();
}

class _JourneyNameViewState extends State<JourneyNameView> {
  final _controller = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(JourneyNameViewModel viewModel) {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    viewModel.save(name);
    widget.onSubmit(name);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<JourneyNameViewModel>();
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (!_loaded && viewModel.lastJourneyName.isNotEmpty) {
          _controller.text = viewModel.lastJourneyName;
          _loaded = true;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Start a Journey')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: BrandLogo(size: 96)),
                const SizedBox(height: 32),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(labelText: 'Journey Name'),
                  onSubmitted: (_) => _submit(viewModel),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Start Journey',
                  onPressed: () => _submit(viewModel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
