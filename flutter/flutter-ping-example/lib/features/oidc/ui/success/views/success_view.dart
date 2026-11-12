/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ping_example/core/theme/app_theme.dart';
import 'package:ping_example/core/widgets/app_card.dart';
import 'package:ping_example/core/widgets/error_banner.dart';
import 'package:ping_example/core/widgets/primary_button.dart';
import 'package:ping_example/core/widgets/token_widgets.dart';
import 'package:ping_example/features/oidc/ui/oidc/view_models/oidc_view_model.dart';

/// Displays token metadata and userinfo after a successful browser login, with buttons for
/// Refresh / Get Token / Userinfo / Revoke / Sign off. Port of the native samples' post-login
/// screens.
class OidcSuccessView extends StatefulWidget {
  const OidcSuccessView({super.key, required this.onSignOff});

  final VoidCallback onSignOff;

  @override
  State<OidcSuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<OidcSuccessView> {
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
                  TokenSection(label: 'Access Token', value: token.accessToken),
                  ExpiryRow(
                    key: ValueKey(token.accessToken),
                    accessToken: token.accessToken,
                    expiresIn: token.expiresIn,
                  ),
                  if (token.idToken != null) ...[
                    TokenSection(label: 'ID Token', value: token.idToken!),
                    IdTokenClaimsCard(idToken: token.idToken!),
                  ],
                  if (token.refreshToken != null)
                    TokenSection(
                      label: 'Refresh Token',
                      value: token.refreshToken!,
                    ),
                  TokenSection(
                    label: 'Token Type',
                    value: token.tokenType ?? '(none)',
                  ),
                  TokenSection(label: 'Scope', value: token.scope ?? '(none)'),
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
                          InfoRow(label: entry.key, value: entry.value),
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
                  label: 'Get Token',
                  loading: vm.loading,
                  onPressed: vm.getToken,
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
                  onPressed: () async {
                    await vm.revoke();
                    if (context.mounted && vm.error == null) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Token revoked. Tap Get Token to see what the SDK returns now.',
                            ),
                          ),
                        );
                    }
                  },
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
