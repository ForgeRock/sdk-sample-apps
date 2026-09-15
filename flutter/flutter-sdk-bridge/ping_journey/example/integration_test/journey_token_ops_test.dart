/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of an MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ping_journey/ping_journey.dart';

import 'support/journey_fixtures.dart';
import 'support/journey_harness.dart';
import 'support/mock_am_server.dart';
import 'support/test_config.dart';

/// The post-login token operations the success screen drives: the AM session
/// token carried on `SuccessNode`, and `refresh()` / `revoke()` / `userInfo()`
/// against a Journey-configured OAuth 2.0 client.
///
/// Every OIDC scenario loads the session via `user()` first — mirroring the
/// sample app, whose success screen always loads the session before any token
/// button is reachable. The headless token exchange runs lazily inside the
/// first `token()` call; `refresh()`/`revoke()` operate on the token that call
/// stored, so calling them without a prior `user()` fails (or no-ops) by
/// native design, not by bridge design.
///
/// Hermetic coverage is shape-level: the mock's token response carries no
/// `id_token` (never fabricate a JWT — native may decode/validate it), so
/// `idToken` is asserted null here and verified live only.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a completed Journey carries its AM session token on the success node',
    (tester) async {
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
      final success = harness.expectSuccess(await harness.client.next(node));

      if (harness.isHermetic) {
        // The whole new pipe end-to-end: the tokenId the fixture returns must
        // reach Dart as SuccessNode.sessionToken.
        expect(success.sessionToken, 'mock-sso-token');
      } else {
        expect(success.sessionToken, isNotEmpty);
      }
    },
  );

  testWidgets(
    'a completed Journey with no OAuth client still carries its session token',
    (tester) async {
      final liveSkipReason = E2eConfig.liveCredentialsSkipReason;
      if (liveSkipReason != null) {
        markTestSkipped(liveSkipReason);
        return;
      }

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
      final success = harness.expectSuccess(await harness.client.next(node));

      if (harness.isHermetic) {
        expect(success.sessionToken, 'mock-sso-token');
      } else {
        expect(success.sessionToken, isNotEmpty);
      }
    },
  );

  testWidgets('refresh() returns a new token set for an OIDC Journey', (
    tester,
  ) async {
    final skipReason = _oidcSkipReason;
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

    // Load the session first: the lazy headless exchange runs inside user() ->
    // token(), which is what stores the token refresh()/revoke() then operate on.
    final session = await harness.client.user();
    expect(session, isNotNull);

    final refreshed = await harness.client.refresh();

    expect(refreshed.accessToken, isNotEmpty);
    expect(
      refreshed.userInfo,
      isEmpty,
      reason:
          'refresh() deliberately returns no userinfo — claims come '
          'from userInfo(), so callers preserve what they already loaded.',
    );

    if (harness.isHermetic) {
      expect(refreshed.accessToken, 'mock-access-token');
      expect(refreshed.refreshToken, 'mock-refresh-token');
      expect(refreshed.tokenType, 'Bearer');
      expect(refreshed.scope, 'openid profile email');
      expect(refreshed.idToken, isNull);

      final tokenRequests = harness.mock.requests.where(
        (request) => request.path == '/oauth2/access_token',
      );
      expect(tokenRequests, isNotEmpty);
      harness.mock.expectNoUnmatchedRequests();
    }
  });

  testWidgets('revoke() completes for an OIDC Journey', (tester) async {
    final skipReason = _oidcSkipReason;
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

    // Load the session first — see the file doc comment for why.
    final session = await harness.client.user();
    expect(session, isNotNull);

    await harness.client.revoke();

    if (harness.isHermetic) {
      final revokeRequests = harness.mock.requests
          .where((request) => request.path == '/oauth2/token/revoke')
          .toList();
      expect(revokeRequests, hasLength(1));
      expect(revokeRequests.single.body, contains('token='));
    }
  });

  testWidgets('userInfo() returns the claims for an OIDC Journey', (
    tester,
  ) async {
    final skipReason = _oidcSkipReason;
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

    // Load the session first — see the file doc comment for why.
    final session = await harness.client.user();
    expect(session, isNotNull);

    final info = await harness.client.userInfo(cache: false);

    expect(info, isNotNull);
    expect(info!['sub'], 'mock-subject');
    expect(info['email'], 'mock.user@example.com');

    if (harness.isHermetic) {
      final userInfoRequests = harness.mock.requests.where(
        (request) => request.path == '/oauth2/userinfo',
      );
      expect(userInfoRequests, isNotEmpty);
      harness.mock.expectNoUnmatchedRequests();
    }
  });

  testWidgets(
    'token commands throw a typed error with no OAuth client configured',
    (tester) async {
      final liveSkipReason = E2eConfig.liveCredentialsSkipReason;
      if (liveSkipReason != null) {
        markTestSkipped(liveSkipReason);
        return;
      }

      final harness = await JourneyHarness.start(
        authenticate: <MockResponse>[
          MockResponse.json(JourneyFixtures.usernamePasswordNode()),
          MockResponse.json(JourneyFixtures.success()),
        ],
      );
      addTearDown(harness.dispose);

      await expectLater(
        () => harness.client.refresh(),
        throwsA(
          isA<PingException>()
              .having((e) => e.code, 'code', 'JOURNEY_REFRESH_ERROR')
              .having((e) => e.type, 'type', 'state'),
        ),
      );
      await expectLater(
        () => harness.client.revoke(),
        throwsA(
          isA<PingException>()
              .having((e) => e.code, 'code', 'JOURNEY_REVOKE_ERROR')
              .having((e) => e.type, 'type', 'state'),
        ),
      );
      await expectLater(
        () => harness.client.userInfo(),
        throwsA(
          isA<PingException>()
              .having((e) => e.code, 'code', 'JOURNEY_USERINFO_ERROR')
              .having((e) => e.type, 'type', 'state'),
        ),
      );
    },
  );
}

String? get _oidcSkipReason {
  final credentials = E2eConfig.liveCredentialsSkipReason;
  if (credentials != null) return credentials;
  if (E2eConfig.isLive && !E2eConfig.hasOidc) {
    return 'Live mode is on but no OAuth 2.0 client was supplied. Set E2E_CLIENT_ID, '
        'E2E_DISCOVERY_ENDPOINT, and E2E_REDIRECT_URI, or drop E2E_SERVER_URL to run hermetically.';
  }
  return null;
}
