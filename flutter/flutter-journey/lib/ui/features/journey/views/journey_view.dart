/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_journey/ping_journey.dart';
import 'package:provider/provider.dart';

import 'package:flutter_journey/ui/core/widgets/error_banner.dart';
import 'package:flutter_journey/ui/core/widgets/primary_button.dart';
import 'package:flutter_journey/ui/features/journey/view_models/journey_view_model.dart';
import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/boolean_attribute_input_callback_view.dart';
import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/choice_callback_view.dart';
import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/kba_create_callback_view.dart';
import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/name_callback_view.dart';
import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/number_attribute_input_callback_view.dart';
import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/password_callback_view.dart';
import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/string_attribute_input_callback_view.dart';
import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/terms_and_conditions_callback_view.dart';
import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/text_input_callback_view.dart';
import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/text_output_callback_view.dart';
import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/validated_password_callback_view.dart';
import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/validated_username_callback_view.dart';

/// Dynamic renderer: dispatches on the sealed [JourneyNode], then on the sealed [Callback] type
/// to build one widget each. Analog of the native samples' `Journey`/`JourneyNodeView`.
class JourneyView extends StatefulWidget {
  const JourneyView({
    super.key,
    required this.onSuccess,
    required this.onRestart,
  });

  final VoidCallback onSuccess;

  /// The Journey ended in an [ErrorNode]/[FailureNode] with no further step to render — invoked
  /// by a "Try Again" button so the user isn't stuck on a dead-end screen.
  final VoidCallback onRestart;

  @override
  State<JourneyView> createState() => _JourneyViewState();
}

class _JourneyViewState extends State<JourneyView> {
  bool _successHandled = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<JourneyViewModel>();
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final node = viewModel.node;

        if (node is SuccessNode && !_successHandled) {
          _successHandled = true;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => widget.onSuccess(),
          );
        } else if (node is! SuccessNode) {
          _successHandled = false;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Journey')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: switch (node) {
              ContinueNode() => _ContinueNodeView(
                node: node,
                viewModel: viewModel,
              ),
              ErrorNode() => _ErrorBanner(
                message: node.message,
                onRestart: widget.onRestart,
              ),
              FailureNode() => _ErrorBanner(
                message: node.cause,
                onRestart: widget.onRestart,
              ),
              SuccessNode() || null => const SizedBox.shrink(),
            },
          ),
        );
      },
    );
  }
}

class _ContinueNodeView extends StatelessWidget {
  const _ContinueNodeView({required this.node, required this.viewModel});

  final ContinueNode node;
  final JourneyViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (viewModel.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ErrorBanner(message: viewModel.error!),
            ),
          if (node.header?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                node.header!,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          if (node.description?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(node.description!),
            ),
          for (final callback in node.callbacks)
            Padding(
              key: ObjectKey(callback),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: switch (callback) {
                NameCallback() => NameCallbackView(
                  callback: callback,
                  onChanged: viewModel.refresh,
                ),
                PasswordCallback() => PasswordCallbackView(
                  callback: callback,
                  onChanged: viewModel.refresh,
                ),
                ValidatedUsernameCallback() => ValidatedUsernameCallbackView(
                  callback: callback,
                  onChanged: viewModel.refresh,
                ),
                ValidatedPasswordCallback() => ValidatedPasswordCallbackView(
                  callback: callback,
                  onChanged: viewModel.refresh,
                ),
                ChoiceCallback() => ChoiceCallbackView(
                  callback: callback,
                  onChanged: viewModel.refresh,
                ),
                KbaCreateCallback() => KbaCreateCallbackView(
                  callback: callback,
                  onChanged: viewModel.refresh,
                ),
                TermsAndConditionsCallback() => TermsAndConditionsCallbackView(
                  callback: callback,
                  onChanged: viewModel.refresh,
                ),
                TextInputCallback() => TextInputCallbackView(
                  callback: callback,
                  onChanged: viewModel.refresh,
                ),
                TextOutputCallback() => TextOutputCallbackView(
                  callback: callback,
                ),
                StringAttributeInputCallback() =>
                  StringAttributeInputCallbackView(
                    callback: callback,
                    onChanged: viewModel.refresh,
                  ),
                NumberAttributeInputCallback() =>
                  NumberAttributeInputCallbackView(
                    callback: callback,
                    onChanged: viewModel.refresh,
                  ),
                BooleanAttributeInputCallback() =>
                  BooleanAttributeInputCallbackView(
                    callback: callback,
                    onChanged: viewModel.refresh,
                  ),
              },
            ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Next',
            onPressed: viewModel.next,
            loading: viewModel.loading,
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRestart});

  final String message;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ErrorBanner(message: message),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Try Again', onPressed: onRestart),
      ],
    );
  }
}
