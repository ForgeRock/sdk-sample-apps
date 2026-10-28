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

/// `DaVinciClient.validate` runs the native SDK's rules over the Form Validation node, with no
/// network call: required fields, the two `TEXT` regexes, and the node's password policy on the
/// `PASSWORD_VERIFY` field. Runs in both modes; the node is reachable without signing in.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('validate catches required, regex and policy errors locally', (
    tester,
  ) async {
    final skipReason = E2eConfig.liveConfigSkipReason;
    if (skipReason != null) {
      markTestSkipped(skipReason);
      return;
    }
    final harness = await DaVinciHarness.create(
      liveAcr: E2eConfig.acrFormFields,
      hermeticAcr: 'form-fields',
      hermeticFlow: (baseUrl) => [
        DaVinciFixtures.formFieldsMenu(baseUrl),
        DaVinciFixtures.formValidationForm(baseUrl),
      ],
    );
    addTearDown(harness.dispose);

    final menu = await harness.client.start();
    expect(menu, isA<ContinueNode>(), reason: harness.diagnose(menu));
    collectorWithKey<FlowCollector>(
      menu as ContinueNode,
      DaVinciFixtures.formValidationBranch,
    ).select();
    final next = await harness.client.next(menu);
    expect(next, isA<ContinueNode>(), reason: harness.diagnose(next));
    final form = next as ContinueNode;
    final username = collectorWithKey<TextCollector>(form, 'user.username');
    final email = collectorWithKey<TextCollector>(form, 'user.email');
    final password = collectorWithKey<PasswordCollector>(form, 'user.password');
    final requestsBefore = harness.mock?.requests.length;

    // The node's `formData` prefills every field ("default username", …), so clear them: only
    // values the app sets are sent, and native would otherwise validate the defaults.
    username.value = '';
    email.value = '';
    password.value = '';
    // Nothing filled in: every required field fails, and the empty password fails the policy.
    expect(form.canSubmit, isFalse);
    final empty = await harness.client.validate(form);
    expect(_describe(username.validationErrors), [
      'RequiredError',
      'RegexError(Must be alphanumeric)',
    ]);
    expect(_describe(email.validationErrors), [
      'RequiredError',
      'RegexError(Not a valid email)',
    ]);
    expect(_describe(password.validationErrors).toSet(), {
      'RequiredError',
      'InvalidLengthError(8, 255)',
      'UniqueCharacterError(5)',
      ..._missingSets(['upper', 'lower', 'digit', 'special']),
    });
    expect(empty, hasLength(4 + password.validationErrors.length));

    // A password violating the policy, with the other fields valid.
    username.value = 'flutter';
    email.value = 'flutter@example.com';
    password.value = 'aaa';
    expect(form.canSubmit, isTrue, reason: 'canSubmit checks presence only');
    await harness.client.validate(form);
    expect(username.validationErrors, isEmpty);
    expect(email.validationErrors, isEmpty);
    expect(_describe(password.validationErrors).toSet(), {
      'InvalidLengthError(8, 255)',
      'UniqueCharacterError(5)',
      'MaxRepeatError(2)',
      ..._missingSets(['upper', 'digit', 'special']),
    });

    password.value = 'Passw0rd!';
    expect(await harness.client.validate(form), isEmpty);
    expect(password.validationErrors, isEmpty);

    final mock = harness.mock;
    if (mock != null) {
      expect(
        mock.requests.length,
        requestsBefore,
        reason: 'validate makes no network call',
      );
      mock.expectNoUnmatchedRequests();
    }
  });
}

const _sets = <String, String>{
  'upper': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
  'lower': 'abcdefghijklmnopqrstuvwxyz',
  'digit': '0123456789',
  'special': '~!@#\$%^&*()-_=+[]{}|;:,.<>/?',
};

Iterable<String> _missingSets(List<String> names) =>
    names.map((name) => 'MinCharactersError(1, ${_sets[name]})');

List<String> _describe(List<ValidationError> errors) => [
  for (final error in errors)
    switch (error) {
      RequiredError() => 'RequiredError',
      RegexError(:final message) => 'RegexError($message)',
      InvalidLengthError(:final min, :final max) =>
        'InvalidLengthError($min, $max)',
      UniqueCharacterError(:final min) => 'UniqueCharacterError($min)',
      MaxRepeatError(:final max) => 'MaxRepeatError($max)',
      MinCharactersError(:final min, :final characters) =>
        'MinCharactersError($min, $characters)',
    },
];
