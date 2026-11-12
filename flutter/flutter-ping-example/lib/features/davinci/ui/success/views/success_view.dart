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
import 'package:ping_example/features/davinci/ui/success/view_models/success_view_model.dart';

/// Shows what a completed DaVinci flow produced: the authorization code it ended with
/// (truncated: the native SDK has already spent it), the OIDC tokens, and the userinfo claims.
/// Same layout as the Journey success screen.
class DaVinciSuccessView extends StatefulWidget {
  const DaVinciSuccessView({super.key, required this.onSignOff});

  final VoidCallback onSignOff;

  @override
  State<DaVinciSuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<DaVinciSuccessView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DaVinciSuccessViewModel>().load();
    });
  }

  static String _truncate(String value) =>
      value.length <= 12 ? value : '${value.substring(0, 12)}…';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Success')),
      body: ListenableBuilder(
        listenable: context.read<DaVinciSuccessViewModel>(),
        builder: (context, _) {
          final vm = context.read<DaVinciSuccessViewModel>();
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
                  TokenSection(
                    label: 'Authorization Code',
                    value: _truncate(session.authorizationCode),
                    copyable: false,
                  ),
                if (token != null) ...[
                  TokenSection(
                    label: 'Access Token',
                    value: token.accessToken,
                  ),
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
                if (userInfo.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('User Info', style: AppTheme.sectionHeader(context)),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final entry in userInfo.entries)
                          InfoRow(label: entry.key, value: entry.value),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // The native SDK refreshes the tokens if they have expired.
                PrimaryButton(
                  label: 'Get Token',
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
