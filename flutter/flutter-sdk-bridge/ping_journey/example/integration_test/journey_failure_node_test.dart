/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ping_journey/ping_journey.dart';

/// An unreachable server yields a [FailureNode] with a cause, and never throws.
///
/// A transport error is the one FailureNode trigger that is identical on both platforms. HTTP status
/// codes are not: a 5xx with a JSON body becomes an ErrorNode on Android (its transform catches the
/// parse and falls through to `error(...)`) but a FailureNode on iOS. So this test refuses the
/// connection outright rather than serving a 500, which would assert a difference instead of a
/// contract.
///
/// The contract being pinned is that `start()` *returns* a node — both native `Workflow`
/// implementations catch every throwable and convert it — rather than throwing a `PingException` that
/// callers would have to wrap in a try/catch. The sample app's error handling depends on that.
///
/// Runs in both modes: it needs no tenant and no mock, only a port nobody is listening on.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('an unreachable server yields a FailureNode rather than throwing', (
    tester,
  ) async {
    // Bind an ephemeral port and immediately release it. Asking the OS for a port and giving it back
    // is more reliable than hard-coding one and hoping it is free on the CI machine.
    final probe = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final closedPort = probe.port;
    await probe.close();

    final client = await JourneyClient.configure(
      JourneyConfigMessage(
        serverUrl: 'http://127.0.0.1:$closedPort',
        realm: 'root',
        cookie: 'iPlanetDirectoryPro',
        // Short, because nothing is going to answer. Connection-refused on loopback is immediate, but
        // this keeps a misconfigured environment from stalling the suite for the default timeout.
        timeoutMillis: 5000,
      ),
    );
    addTearDown(client.dispose);

    final node = await client.start('Login', forceAuth: true);

    expect(
      node,
      isA<FailureNode>(),
      reason:
          'Expected a transport error to be converted into a FailureNode, but got $node. '
          'If this is a ContinueNode, something is listening on port $closedPort.',
    );
    // The cause text is whatever Ktor or URLSession produced, so only its presence is contractual.
    expect((node as FailureNode).cause, isNotEmpty);
  });
}
