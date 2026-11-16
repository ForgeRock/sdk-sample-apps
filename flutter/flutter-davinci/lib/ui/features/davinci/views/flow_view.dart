/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_davinci/ping_davinci.dart';
import 'package:provider/provider.dart';

import 'package:flutter_davinci/ui/core/widgets/error_banner.dart';
import 'package:flutter_davinci/ui/core/widgets/primary_button.dart';
import 'package:flutter_davinci/ui/features/davinci/view_models/davinci_view_model.dart';
import 'package:flutter_davinci/ui/features/davinci/widgets/collector_form.dart';

/// Hosts a running DaVinci flow: dispatches on the sealed [DaVinciNode] and hands a
/// [ContinueNode] to [CollectorForm].
///
/// A wrong password or a rejected value never lands here as an [ErrorNode]: the ViewModel
/// re-renders the same form with the errors attached. Only an [ErrorNode] that can't be retried,
/// or a [FailureNode], ends the run with a "Try Again".
class FlowView extends StatefulWidget {
  const FlowView({super.key, required this.onSuccess, required this.onRestart});

  final VoidCallback onSuccess;

  /// The flow ended with no form to go back to: start over.
  final VoidCallback onRestart;

  @override
  State<FlowView> createState() => _FlowViewState();
}

class _FlowViewState extends State<FlowView> {
  bool _successHandled = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<DaVinciViewModel>();
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
          appBar: AppBar(
            title: Text(switch (node) {
              ContinueNode(:final name?) when name.isNotEmpty => name,
              _ => 'DaVinci',
            }),
            bottom: viewModel.loading
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(4),
                    child: LinearProgressIndicator(),
                  )
                : null,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: switch (node) {
              ContinueNode() => _ContinueNodeView(
                node: node,
                viewModel: viewModel,
              ),
              ErrorNode() => _DeadEnd(
                message: node.message,
                onRestart: widget.onRestart,
              ),
              FailureNode() => _DeadEnd(
                message: node.cause,
                onRestart: widget.onRestart,
              ),
              null when viewModel.error != null => _DeadEnd(
                message: viewModel.error!,
                onRestart: widget.onRestart,
              ),
              SuccessNode() ||
              null => const Center(child: CircularProgressIndicator()),
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
  final DaVinciViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final error = [
      ?viewModel.error,
      for (final MapEntry(:key, :value) in viewModel.fieldErrors.entries)
        '$key: $value',
    ].join('\n');
    final unsupported = node.unsupportedFields
        .where((field) => field.reason != UnsupportedFieldReason.knownIgnorable)
        .toList();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ErrorBanner(message: error),
            ),
          if (node.pageDescription?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(node.pageDescription!),
            ),
          if (unsupported.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _UnsupportedFieldsNotice(fields: unsupported),
            ),
          CollectorForm(
            node: node,
            loading: viewModel.loading,
            onChanged: viewModel.refresh,
            onSubmit: (button) => viewModel.submit(button: button),
            onPollingDone: () => viewModel.submit(validate: false),
            poll: viewModel.poll,
          ),
        ],
      ),
    );
  }
}

/// Lists the fields the server sent that this app has no widget for, so a missing field is
/// visible rather than silently absent. The rest of the form still works.
class _UnsupportedFieldsNotice extends StatelessWidget {
  const _UnsupportedFieldsNotice({required this.fields});

  final List<UnsupportedField> fields;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lines = [
      for (final field in fields)
        '• ${field.type}${field.key == null ? '' : ' (${field.key})'}: ${switch (field.reason) {
          UnsupportedFieldReason.addOnRequired => 'needs an add-on module',
          UnsupportedFieldReason.notBridged => 'not supported by this app',
          UnsupportedFieldReason.unknown => 'unknown field type',
          UnsupportedFieldReason.knownIgnorable => 'ignored',
        }}',
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Some fields of this form are not shown:\n${lines.join('\n')}',
        style: TextStyle(color: scheme.onSecondaryContainer),
      ),
    );
  }
}

class _DeadEnd extends StatelessWidget {
  const _DeadEnd({required this.message, required this.onRestart});

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
