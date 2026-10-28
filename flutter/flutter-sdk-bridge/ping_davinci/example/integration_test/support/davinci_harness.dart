/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:ping_davinci/ping_davinci.dart';

import 'davinci_fixtures.dart';
import 'mock_davinci_server.dart';
import 'test_config.dart';

/// A configured [DaVinciClient] for the form-fields flow, in whichever mode [E2eConfig] selects.
///
/// Hermetic: a [MockDaVinciServer] scripted with the captured menu node, then the `Form Fields`
/// node. Live: the tenant's real flow, selected by `E2E_ACR_FORM_FIELDS`. Both start at the same
/// menu, so a scenario that picks [DaVinciFixtures.formFieldsBranch] runs unchanged in either.
class DaVinciHarness {
  DaVinciHarness._(this.client, this.mock);

  /// The client under test.
  final DaVinciClient client;

  /// The mock server in hermetic mode; `null` in live mode.
  final MockDaVinciServer? mock;

  /// Whether this run is hermetic.
  bool get isHermetic => mock != null;

  /// Configures a client for the form-fields flow. [then] scripts the hermetic responses after
  /// the `Form Fields` form; live mode runs the tenant's real flow either way.
  static Future<DaVinciHarness> formFields({
    List<Object> Function(String baseUrl)? then,
  }) => create(
    liveAcr: E2eConfig.acrFormFields,
    hermeticAcr: 'form-fields',
    hermeticFlow: (baseUrl) => [
      DaVinciFixtures.formFieldsMenu(baseUrl),
      DaVinciFixtures.formFieldsForm(baseUrl),
      ...?then?.call(baseUrl),
    ],
  );

  /// Configures a client for the flow [liveAcr] selects in live mode, or for a mock scripted with
  /// [hermeticFlow] (and requested with [hermeticAcr]) otherwise.
  ///
  /// [challengeStatus] scripts the mock's challenge-status endpoint (see [MockDaVinciServer]).
  static Future<DaVinciHarness> create({
    required String liveAcr,
    required String hermeticAcr,
    required List<Object> Function(String baseUrl) hermeticFlow,
    List<Object> challengeStatus = const <Object>[],
  }) async {
    if (E2eConfig.isLive) {
      final client = await DaVinciClient.configure(
        DaVinciConfigMessage()
          ..clientId = E2eConfig.clientId
          ..discoveryEndpoint = E2eConfig.discoveryEndpoint
          ..redirectUri = E2eConfig.redirectUri
          ..scopes = E2eConfig.scopeList
          ..acrValues = liveAcr,
      );
      return DaVinciHarness._(client, null);
    }
    final mock = await MockDaVinciServer.start(
      flow: hermeticFlow,
      challengeStatus: challengeStatus,
    );
    final client = await DaVinciClient.configure(
      DaVinciConfigMessage()
        ..clientId = 'integration-test-client'
        ..discoveryEndpoint = mock.discoveryEndpoint
        ..redirectUri = 'pingdavinciexample://callback'
        ..scopes = <String?>['openid']
        ..acrValues = hermeticAcr,
    );
    return DaVinciHarness._(client, mock);
  }

  /// Configures a client for the SSO flow, scripted in hermetic mode to sign on successfully.
  static Future<DaVinciHarness> signOnFlow() => create(
    liveAcr: E2eConfig.acrSso,
    hermeticAcr: 'sso',
    hermeticFlow: (baseUrl) => [
      DaVinciFixtures.ssoMenu(baseUrl),
      DaVinciFixtures.signOnSuccess(),
    ],
  );

  /// Starts the SSO flow and submits the username and password (`alice` in hermetic mode, the
  /// `E2E_*` user live), returning the node that follows. Configure with [signOnFlow].
  Future<DaVinciNode> signOn() async {
    final start = await client.start();
    if (start is! ContinueNode) return start;
    start.collectors.whereType<TextCollector>().single.value = isHermetic
        ? 'alice'
        : E2eConfig.username;
    start.collectors.whereType<PasswordCollector>().single.value = isHermetic
        ? 'Passw0rd!'
        : E2eConfig.password;
    collectorWithKey<SubmitCollector>(
      start,
      DaVinciFixtures.signOnButton,
    ).select();
    return client.next(start);
  }

  /// Releases the client and stops the mock. Safe to pass straight to `addTearDown`.
  Future<void> dispose() async {
    await client.dispose();
    await mock?.stop();
  }

  /// Context for a failed assertion about [node]: its error text, the mode, and the request log in
  /// hermetic mode.
  String diagnose(DaVinciNode node) {
    final detail = switch (node) {
      FailureNode(:final cause) => 'FailureNode cause: $cause',
      ErrorNode(:final message, :final status) => 'ErrorNode $status: $message',
      _ => node.runtimeType.toString(),
    };
    final log = mock == null ? '' : '\nRequests:\n${mock!.requestLog}';
    return '$detail\n${E2eConfig.describe}$log';
  }
}

/// The collector on [node] whose key is [key], as a [T].
T collectorWithKey<T extends Collector>(ContinueNode node, String key) =>
    node.collectors.firstWhere((collector) => collector.key == key) as T;
