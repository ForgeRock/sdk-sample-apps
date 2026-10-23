/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ping_oidc/ping_oidc.dart';

import 'support/mock_oidc_provider.dart';
import 'support/oidc_harness.dart';
import 'support/test_config.dart';

/// An `openId`-only config (no `discoveryEndpoint`) authorizes, exchanges its code, and fetches
/// userinfo without ever requesting a discovery document.
///
/// Drives the real system browser against [MockOidcProvider], whose `/oauth2/authorize` 302s
/// straight back to the redirect URI, so no UI interaction is needed. iOS uses the ephemeral
/// session type to avoid the system sign-in consent alert. Hermetic only; nothing is pumped.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'an openId-only config authorizes and exchanges the code without discovery',
    (tester) async {
      if (E2eConfig.isLive) {
        markTestSkipped(
          'Hermetic only: authorize() against a real tenant shows a login page that nothing in '
          'this suite can complete. The live openId path is covered by hand via flutter-oidc.',
        );
        return;
      }

      final provider = await MockOidcProvider.start(
        redirectUri: OidcHarness.hermeticRedirectUri,
      );
      addTearDown(provider.stop);

      final client = await OidcClient.configure(
        OidcConfig(
          clientId: OidcHarness.hermeticClientId,
          redirectUri: OidcHarness.hermeticRedirectUri,
          scopes: const ['openid', 'profile', 'email'],
          openId: OidcOpenIdConfig(
            authorizationEndpoint: provider.authorizationEndpoint,
            tokenEndpoint: provider.tokenEndpoint,
            userinfoEndpoint: provider.userinfoEndpoint,
            endSessionEndpoint: provider.endSessionEndpoint,
            revocationEndpoint: provider.revocationEndpoint,
          ),
        ),
        browserOptions: Platform.isIOS
            ? const OidcBrowserOptions(browserType: 'ephemeralAuthSession')
            : null,
      );
      addTearDown(client.dispose);

      // Normally completes in seconds; a hang usually means Chrome's first-run screen is blocking
      // the Custom Tab (see example/README.md § Preconditions).
      final result = await client.authorize().timeout(
        const Duration(seconds: 60),
        onTimeout: () => fail(
          'authorize() did not return within 60s. Requests so far:\n'
          '${provider.requestLog}\n'
          'If that is empty, the system browser never loaded the authorize URL. On Android, '
          'complete Chrome\'s first-run screen on the emulator once, then re-run.',
        ),
      );
      expect(
        result,
        isA<AuthorizeSuccess>(),
        reason:
            'authorize() did not complete.\nRequests:\n${provider.requestLog}',
      );

      final authorize = provider.requestsTo('/oauth2/authorize').single;
      expect(authorize.query['client_id'], OidcHarness.hermeticClientId);
      expect(authorize.query['redirect_uri'], OidcHarness.hermeticRedirectUri);
      expect(authorize.query['code_challenge'], isNotEmpty);
      expect(authorize.query['code_challenge_method'], 'S256');

      final token = await client.token();
      expect(token.accessToken, MockOidcProvider.token['access_token']);
      expect(token.refreshToken, MockOidcProvider.token['refresh_token']);

      final exchange = provider.requestsTo('/oauth2/access_token').single;
      expect(exchange.method, 'POST');
      expect(
        exchange.body,
        contains('code=${MockOidcProvider.authorizationCode}'),
      );
      expect(exchange.body, contains('code_verifier='));

      final userInfo = await client.userInfo();
      expect(userInfo['sub'], MockOidcProvider.userInfo['sub']);

      expect(
        provider.requestsTo('/.well-known/openid-configuration'),
        isEmpty,
        reason:
            'An explicit openId config must skip discovery on both platforms.\n'
            'Requests:\n${provider.requestLog}',
      );

      // Native token storage outlives the process; don't leak into the next run.
      await client.signOff();
    },
  );
}
