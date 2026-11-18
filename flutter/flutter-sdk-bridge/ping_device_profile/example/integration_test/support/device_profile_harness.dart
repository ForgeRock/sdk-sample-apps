/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:ping_journey/ping_journey.dart';

import 'journey_fixtures.dart';
import 'mock_am_server.dart';
import 'test_config.dart';

/// A configured [JourneyClient] whose scripted Journey hands out a `DeviceProfileCallback`, so the
/// device-profile scenarios read the same whether they run against the in-process [MockAmServer]
/// or a real tenant.
///
/// Same shape as `ping_journey`'s `JourneyHarness`, minus the credential helpers — a device profile
/// page collects nothing from the user.
class DeviceProfileHarness {
  DeviceProfileHarness._({required this.client, required this.server});

  /// The client under test.
  final JourneyClient client;

  /// The mock server backing [client], or `null` in live mode.
  final MockAmServer? server;

  /// Builds a harness for the active mode. [authenticate] scripts the mock's `/authenticate`
  /// responses in order and is ignored when running live.
  static Future<DeviceProfileHarness> start({
    List<MockResponse> authenticate = const <MockResponse>[],
  }) async {
    if (E2eConfig.isLive) {
      return DeviceProfileHarness._(
        client: await JourneyClient.configure(_liveConfig()),
        server: null,
      );
    }
    final server = await MockAmServer.start(authenticate: authenticate);
    return DeviceProfileHarness._(
      client: await JourneyClient.configure(_hermeticConfig(server)),
      server: server,
    );
  }

  /// Whether this harness is backed by the in-process mock.
  bool get isHermetic => server != null;

  /// Asserts [node] is a [ContinueNode] and returns it, attaching the request log on failure.
  ContinueNode expectContinue(JourneyNode node) => _expect<ContinueNode>(node, 'ContinueNode');

  /// Asserts [node] is a [SuccessNode] and returns it, attaching the request log on failure.
  SuccessNode expectSuccess(JourneyNode node) => _expect<SuccessNode>(node, 'SuccessNode');

  T _expect<T extends JourneyNode>(JourneyNode node, String expected) {
    if (node is T) return node;
    fail(
      'Expected $expected but got: $node\n'
      'Mode: ${E2eConfig.describe}.'
      '${server == null ? '' : '\nRequests seen by the mock server:\n${server!.requestLog}'}',
    );
  }

  /// Releases the native `Journey` and stops the mock server, in that order.
  Future<void> dispose() async {
    await client.dispose();
    await server?.stop();
  }

  static JourneyConfigMessage _hermeticConfig(MockAmServer server) =>
      JourneyConfigMessage(serverUrl: server.baseUrl)..realm = E2eConfig.realm;

  static JourneyConfigMessage _liveConfig() =>
      JourneyConfigMessage(serverUrl: E2eConfig.serverUrl)..realm = E2eConfig.realm;

  /// The scripted device profile page, for hermetic scenarios.
  static List<MockResponse> collectScript({int extra = 0}) => <MockResponse>[
    MockResponse.json(JourneyFixtures.deviceProfileNode()),
    for (var i = 0; i < extra; i++) MockResponse.json(JourneyFixtures.deviceProfileNode()),
    MockResponse.json(JourneyFixtures.success()),
  ];
}
