/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/journey_fixtures.dart';
import 'support/journey_harness.dart';
import 'support/mock_am_server.dart';
import 'support/test_config.dart';

/// A Journey configured with an OAuth 2.0 client exchanges its SSO session for tokens.
///
/// This is the leg that cannot be unit-tested at all: the token exchange happens entirely inside the
/// native SDK, triggered by reaching a success node, and it is *headless* — the agent sends the SSO
/// cookie as a request header and reads the authorization code out of a 302's `Location`, so no
/// browser and no UI are involved. That is the whole reason this suite can run without pumping a
/// widget.
///
/// The negative case matters as much as the positive one: without an OAuth 2.0 client the bridge
/// returns `null` from `user()` by design, and the sample app relies on that to decide whether to show
/// a token screen.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a successful Journey with OIDC configured yields a session', (
    tester,
  ) async {
    final skipReason = E2eConfig.oidcSkipReason;
    if (skipReason != null) {
      markTestSkipped(skipReason);
      return;
    }

    final harness = await JourneyHarness.start(
      oidc: true,
      authenticate: <MockResponse>[
        MockResponse.json(JourneyFixtures.usernamePasswordNode()),
        MockResponse.json(JourneyFixtures.success()),
      ],
    );
    addTearDown(harness.dispose);

    final node = harness.expectContinue(
      await harness.client.start(harness.journeyName, forceAuth: true),
    );
    harness.fillCredentials(node);
    harness.expectSuccess(await harness.client.next(node));

    final session = await harness.client.user();
    expect(
      session,
      isNotNull,
      reason:
          'user() returned null despite an OAuth 2.0 client being configured. '
          'Mode: ${E2eConfig.describe}.'
          '${harness.isHermetic ? '\nRequests:\n${harness.mock.requestLog}' : ''}',
    );

    expect(session!.accessToken, isNotEmpty);
    expect(session.userInfo, isNotEmpty);

    if (harness.isHermetic) {
      expect(session.accessToken, 'mock-access-token');
      expect(session.refreshToken, 'mock-refresh-token');
      // Raw seconds from the token response, not a computed absolute expiry — both platforms keep
      // `expires_in` as given and derive their own `expiresAt` separately.
      expect(session.expiresIn, 3599);
      expect(session.userInfo['sub'], 'mock-subject');
      expect(session.userInfo['email'], 'mock.user@example.com');

      // The authorize call carries the SSO cookie the Journey just established, plus PKCE — this is
      // what makes the exchange headless.
      final authorize = harness.mock.requests
          .where((request) => request.path == '/oauth2/authorize')
          .single;
      expect(authorize.headers['iplanetdirectorypro'], 'mock-sso-token');
      expect(authorize.query['code_challenge'], isNotEmpty);
      expect(authorize.query['code_challenge_method'], 'S256');
      expect(authorize.query['client_id'], 'mock-client-id');
      expect(
        authorize.query['redirect_uri'],
        JourneyHarness.hermeticRedirectUri,
      );

      // The code from the 302 is redeemed with the matching verifier.
      final token = harness.mock.requests
          .where((request) => request.path == '/oauth2/access_token')
          .single;
      expect(token.method, 'POST');
      expect(token.body, contains('code=mock-authorization-code'));
      expect(token.body, contains('code_verifier='));

      harness.mock.expectNoUnmatchedRequests();
    }
  });

  testWidgets('a Journey with no OAuth 2.0 client returns a null session', (
    tester,
  ) async {
    final liveSkipReason = E2eConfig.liveCredentialsSkipReason;
    if (liveSkipReason != null) {
      markTestSkipped(liveSkipReason);
      return;
    }

    // No login required: the bridge short-circuits on the *configuration*, before it ever looks for a
    // session, so this holds whether or not a Journey has been completed.
    final harness = await JourneyHarness.start(
      authenticate: <MockResponse>[
        MockResponse.json(JourneyFixtures.usernamePasswordNode()),
        MockResponse.json(JourneyFixtures.success()),
      ],
    );
    addTearDown(harness.dispose);

    final node = harness.expectContinue(
      await harness.client.start(harness.journeyName, forceAuth: true),
    );
    harness.fillCredentials(node);
    harness.expectSuccess(await harness.client.next(node));

    expect(
      await harness.client.user(),
      isNull,
      reason:
          'A Journey-only configuration has no tokens to return, so user() must be null rather '
          'than an empty Session.',
    );
  });
}
