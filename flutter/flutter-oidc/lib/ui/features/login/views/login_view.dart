/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_oidc/ui/core/widgets/brand_logo.dart';
import 'package:flutter_oidc/ui/core/widgets/error_banner.dart';
import 'package:flutter_oidc/ui/core/widgets/primary_button.dart';
import 'package:flutter_oidc/ui/features/oidc/view_models/oidc_view_model.dart';

/// A single "Login with browser" button. Shows a spinner while the system browser is up, and an
/// inline error banner with a retry path on failure. Cancelling the browser returns here cleanly
/// — [OidcViewModel.authorize] resolves `false` for a cancel, which is not an error.
class LoginView extends StatelessWidget {
  const LoginView({super.key, required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OidcViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: BrandLogo(size: 96)),
            const SizedBox(height: 32),
            if (viewModel.error != null) ...[
              ErrorBanner(message: viewModel.error!),
              const SizedBox(height: 16),
            ],
            PrimaryButton(
              label: 'Login with browser',
              loading: viewModel.loading,
              onPressed: () async {
                final success = await context.read<OidcViewModel>().authorize();
                if (success && context.mounted) onSuccess();
              },
            ),
          ],
        ),
      ),
    );
  }
}
