/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:flutter_davinci/ui/core/theme/app_theme.dart';
import 'package:flutter_davinci/ui/core/widgets/app_card.dart';
import 'package:flutter_davinci/ui/core/widgets/error_banner.dart';
import 'package:flutter_davinci/ui/core/widgets/primary_button.dart';
import 'package:flutter_davinci/ui/features/success/view_models/success_view_model.dart';

/// Shows what a completed DaVinci flow produced: the authorization code it ended with
/// (truncated: the native SDK has already spent it), the OIDC tokens, and the userinfo claims.
/// Same layout as the `flutter-journey` success screen.
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
      context.read<SuccessViewModel>().load();
    });
  }

  static String _truncate(String value) =>
      value.length <= 12 ? value : '${value.substring(0, 12)}…';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Success')),
      body: ListenableBuilder(
        listenable: context.read<SuccessViewModel>(),
        builder: (context, _) {
          final vm = context.read<SuccessViewModel>();
          if (vm.loading && vm.session == null) {
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
          final session = vm.session;
          final token = vm.token;
          final userInfo = vm.userInfo ?? const {};
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'DaVinci flow completed successfully.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                // Inline error banner (not a full-body swap) so a failed reload doesn't blank
                // the data already on screen.
                if (vm.error != null) ...[
                  ErrorBanner(message: vm.error!),
                  const SizedBox(height: 16),
                ],
                if (session != null)
                  _TokenSection(
                    label: 'Authorization Code',
                    value: _truncate(session.authorizationCode),
                    copyable: false,
                  ),
                if (token != null) ...[
                  _TokenSection(
                    label: 'Access Token',
                    value: token.accessToken,
                  ),
                  if (token.idToken != null)
                    _TokenSection(label: 'ID Token', value: token.idToken!),
                  if (token.refreshToken != null)
                    _TokenSection(
                      label: 'Refresh Token',
                      value: token.refreshToken!,
                    ),
                  _TokenSection(
                    label: 'Token Type',
                    value: token.tokenType ?? '(none)',
                  ),
                  _TokenSection(label: 'Scope', value: token.scope ?? '(none)'),
                  _TokenSection(
                    label: 'Expires In',
                    value: '${token.expiresIn}s',
                  ),
                ],
                if (userInfo.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('User Info', style: AppTheme.sectionHeader(context)),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final entry in userInfo.entries)
                          _InfoRow(key_: entry.key, value: entry.value),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Reload Token',
                  onPressed: vm.reloadToken,
                  loading: vm.loading,
                ),
                const SizedBox(height: 12),
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
  const _TokenSection({
    required this.label,
    required this.value,
    this.copyable = true,
  });

  final String label;
  final String value;
  final bool copyable;

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
                if (copyable)
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
