/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:flutter_oidc/ui/core/theme/app_theme.dart';
import 'package:flutter_oidc/ui/core/widgets/app_card.dart';
import 'package:flutter_oidc/ui/core/widgets/error_banner.dart';
import 'package:flutter_oidc/ui/core/widgets/primary_button.dart';
import 'package:flutter_oidc/ui/features/oidc/view_models/oidc_view_model.dart';

/// Displays token metadata and userinfo after a successful browser login, with buttons for
/// Refresh / Userinfo / Revoke / Sign off. Port of the native samples' post-login screens.
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
      context.read<OidcViewModel>().loadUserInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Success')),
      body: ListenableBuilder(
        listenable: context.read<OidcViewModel>(),
        builder: (context, _) {
          final vm = context.read<OidcViewModel>();
          final token = vm.token;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Login completed successfully.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                if (vm.error != null) ...[
                  ErrorBanner(message: vm.error!),
                  const SizedBox(height: 16),
                ],
                if (token != null) ...[
                  _TokenSection(label: 'Access Token', value: token.accessToken),
                  if (token.idToken != null)
                    _TokenSection(label: 'ID Token', value: token.idToken!),
                  if (token.refreshToken != null)
                    _TokenSection(label: 'Refresh Token', value: token.refreshToken!),
                  _TokenSection(label: 'Token Type', value: token.tokenType ?? '(none)'),
                  _TokenSection(label: 'Scope', value: token.scope ?? '(none)'),
                  _TokenSection(label: 'Expires In', value: '${token.expiresIn}s'),
                ],
                if (vm.userInfo case final info? when info.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('User Info', style: AppTheme.sectionHeader(context)),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final entry in info.entries)
                          _InfoRow(key_: entry.key, value: entry.value),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Refresh',
                  loading: vm.loading,
                  onPressed: vm.refresh,
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Userinfo',
                  loading: vm.loading,
                  onPressed: vm.loadUserInfo,
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Revoke',
                  loading: vm.loading,
                  onPressed: vm.revoke,
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Sign Off',
                  loading: vm.loading,
                  onPressed: () async {
                    await vm.signOff();
                    widget.onSignOff();
                  },
                ),
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
