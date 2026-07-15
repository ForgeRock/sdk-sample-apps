/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:flutter_journey/ui/core/theme/app_theme.dart';
import 'package:flutter_journey/ui/core/widgets/app_card.dart';
import 'package:flutter_journey/ui/core/widgets/error_banner.dart';
import 'package:flutter_journey/ui/core/widgets/primary_button.dart';
import 'package:flutter_journey/ui/features/success/view_models/success_view_model.dart';

/// Displays the access/refresh tokens and userinfo after a successful Journey, and provides a
/// Sign-off button. Port of the native samples' success/token screens.
class SuccessView extends StatefulWidget {
  const SuccessView({super.key, required this.onSignOff});

  final VoidCallback onSignOff;

  @override
  State<SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<SuccessView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuccessViewModel>().loadSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Success')),
      body: ListenableBuilder(
        listenable: context.read<SuccessViewModel>(),
        builder: (context, _) {
          final vm = context.read<SuccessViewModel>();
          if (vm.loading) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    'Loading session…',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          if (vm.error != null) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ErrorBanner(message: vm.error!),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Sign Off',
                    onPressed: widget.onSignOff,
                  ),
                ],
              ),
            );
          }
          final session = vm.session;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Journey completed successfully.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                if (session != null) ...[
                  _TokenSection(
                    label: 'Access Token',
                    value: session.accessToken,
                  ),
                  if (session.refreshToken != null)
                    _TokenSection(
                      label: 'Refresh Token',
                      value: session.refreshToken!,
                    ),
                  _TokenSection(
                    label: 'Expires In',
                    value: '${session.expiresIn}s',
                  ),
                  if (session.userInfo.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'User Info',
                      style: AppTheme.sectionHeader(context),
                    ),
                    const SizedBox(height: 8),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final entry in session.userInfo.entries)
                            _InfoRow(key_: entry.key, value: entry.value),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                PrimaryButton(label: 'Sign Off', onPressed: widget.onSignOff),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TokenSection extends StatelessWidget {
  const _TokenSection({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.sectionHeader(context)),
          const SizedBox(height: 4),
          AppCard(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
                InkWell(
                  onTap: () => Clipboard.setData(ClipboardData(text: value)),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.key_, required this.value});

  final String key_;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              key_,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
