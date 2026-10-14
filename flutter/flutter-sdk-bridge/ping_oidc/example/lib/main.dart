/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';

/// Integration-test host for `ping_oidc`.
///
/// This app exists only so that Flutter's `integration_test` package has an application package to
/// run inside — a plugin cannot host integration tests itself. The tests under
/// `integration_test/` drive [OidcClient] directly and never pump this widget tree, so there is
/// deliberately nothing here to interact with.
///
/// For a real, readable demonstration of the `ping_oidc` API, see the sample app at
/// `flutter/flutter-oidc`.
void main() => runApp(const PingOidcExampleApp());

/// The placeholder host application. See [main] for why it is intentionally empty.
class PingOidcExampleApp extends StatelessWidget {
  /// Creates the placeholder host application.
  const PingOidcExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ping_oidc integration test host',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'ping_oidc integration-test host.\n\n'
              'This app has no UI by design. Run the suites under integration_test/ '
              'instead — see example/README.md.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}
