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
import 'package:ping_example/features/journey/ui/success/view_models/success_view_model.dart';

/// Displays the AM session token after a successful Journey (even without OIDC),
/// the full OIDC token metadata and userinfo when configured, and — when OIDC
/// is configured — the same Refresh / Get Token / Userinfo / Revoke / Sign Off button set
/// as the OIDC success screen. Port of the native samples' success/token screens.
class JourneySuccessView extends StatefulWidget {
  const JourneySuccessView({super.key, required this.onSignOff});

  final VoidCallback onSignOff;

  @override
  State<JourneySuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<JourneySuccessView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JourneySuccessViewModel>().loadSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Success')),
      body: ListenableBuilder(
        listenable: context.read<JourneySuccessViewModel>(),
        builder: (context, _) {
          final vm = context.read<JourneySuccessViewModel>();
          if (vm.loading && vm.session == null && vm.sessionToken == null) {
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
          final userInfo = vm.userInfo ?? session?.userInfo ?? const {};
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
                // Inline error banner (not a full-body swap) so a failed
                // Refresh/Userinfo doesn't blank the data already on screen.
                if (vm.error != null) ...[
                  ErrorBanner(message: vm.error!),
                  const SizedBox(height: 16),
                ],
                if (vm.sessionToken != null)
                  TokenSection(
                    label: 'Session Token',
                    value: vm.sessionToken!,
                  ),
                if (session != null) ...[
                  TokenSection(
                    label: 'Access Token',
                    value: session.accessToken,
                  ),
                  ExpiryRow(
                    key: ValueKey(session.accessToken),
                    accessToken: session.accessToken,
                    expiresIn: session.expiresIn,
                  ),
                  if (session.idToken != null) ...[
                    TokenSection(label: 'ID Token', value: session.idToken!),
                    IdTokenClaimsCard(idToken: session.idToken!),
                  ],
                  if (session.refreshToken != null)
                    TokenSection(
                      label: 'Refresh Token',
                      value: session.refreshToken!,
                    ),
                  TokenSection(
                    label: 'Token Type',
                    value: session.tokenType ?? '(none)',
                  ),
                  TokenSection(
                    label: 'Scope',
                    value: session.scope ?? '(none)',
                  ),
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
                  // The OIDC token buttons, same set as the OIDC success screen.
                  PrimaryButton(
                    label: 'Refresh',
                    onPressed: vm.refresh,
                    loading: vm.loading,
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Get Token',
                    onPressed: vm.loadSession,
                    loading: vm.loading,
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Userinfo',
                    onPressed: vm.loadUserInfo,
                    loading: vm.loading,
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Revoke',
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
                    loading: vm.loading,
                  ),
                ],
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
