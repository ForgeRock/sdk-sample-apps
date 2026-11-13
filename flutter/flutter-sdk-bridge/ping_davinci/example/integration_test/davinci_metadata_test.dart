/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'support/davinci_fixtures.dart';
import 'support/davinci_harness.dart';
import 'support/test_config.dart';

/// A `METADATA` field (native 2.2.0) pauses the flow for the app: it carries the connector's
/// payload, local validation reports it `Required` until the app sets a result, and the result
/// resumes the flow, submitted by the native collector under its key as both `actionKey` and
/// `formData`, with the `action` event type. Runs in both modes.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a metadata result resumes the flow', (tester) async {
    final skipReason = E2eConfig.liveFlowSkipReason(
      E2eConfig.acrMetadataImage,
      'E2E_ACR_METADATA_IMAGE',
    );
    if (skipReason != null) {
      markTestSkipped(skipReason);
      return;
    }
    final harness = await DaVinciHarness.create(
      liveAcr: E2eConfig.acrMetadataImage,
      hermeticAcr: 'metadata-image',
      hermeticFlow: (baseUrl) => [
        DaVinciFixtures.metadataImageMenu(baseUrl),
        DaVinciFixtures.metadataForm(baseUrl),
        DaVinciFixtures.metadataSubmitted(baseUrl),
      ],
    );
    addTearDown(harness.dispose);

    final menu = await harness.client.start();
    expect(menu, isA<ContinueNode>(), reason: harness.diagnose(menu));
    collectorWithKey<SubmitCollector>(
      menu as ContinueNode,
      DaVinciFixtures.metadataBranch,
    ).select();
    final form = await harness.client.next(menu);
    expect(form, isA<ContinueNode>(), reason: harness.diagnose(form));
    form as ContinueNode;
    final metadata = form.collectors.whereType<MetadataCollector>().single;
    expect(metadata.key, 'sdkMetadata');
    expect(metadata.metadata, {'testkey': 'testValue'});
    expect(form.canSubmit, isFalse);

    final before = await harness.client.validate(form);
    expect(before.single, isA<RequiredError>());
    expect(before.single.collector, same(metadata));

    metadata.setResult({'flutter': 'integration', 'ok': true});
    expect(await harness.client.validate(form), isEmpty);
    expect(form.canSubmit, isTrue);

    final next = await harness.client.next(form);
    expect(next, isA<ContinueNode>(), reason: harness.diagnose(next));
    expect(
      (next as ContinueNode).collectors.whereType<SubmitCollector>(),
      isNotEmpty,
    );

    final mock = harness.mock;
    if (mock == null) return;
    mock.expectNoUnmatchedRequests();
    final submit = mock.flowRequests.last;
    expect((submit.json?['parameters'] as Map)['eventType'], 'action');
    expect(submit.submittedData?['actionKey'], 'sdkMetadata');
    expect(submit.submittedData?['formData'], {
      'sdkMetadata': {'flutter': 'integration', 'ok': true},
    });
  });
}
