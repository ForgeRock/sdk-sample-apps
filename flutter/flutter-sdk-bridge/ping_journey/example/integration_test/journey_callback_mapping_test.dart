/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ping_journey/ping_journey.dart';

import 'support/journey_fixtures.dart';
import 'support/journey_harness.dart';
import 'support/mock_am_server.dart';
import 'support/test_config.dart';

/// Every v1 callback type, mapped once, on a single page.
///
/// The unit tests in `ping_journey/test/` already cover `NodeMapper` against synthetic
/// [CallbackMessage]s. What they cannot cover is the leg either side of it: whether the *native*
/// SDK parses AM's JSON into the fields the bridge reads, and whether Pigeon's codec carries those
/// fields across the boundary intact. That is what this test is for, and it is why the assertions
/// look redundant with the unit tests — they are checking a different link in the chain.
///
/// Hermetic only: no real tenant will serve twelve unrelated callbacks on one page on request.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every mapped callback type survives the native round trip', (
    tester,
  ) async {
    if (E2eConfig.isLive) {
      markTestSkipped(E2eConfig.hermeticOnlySkipReason);
      return;
    }

    final harness = await JourneyHarness.start(
      authenticate: <MockResponse>[
        MockResponse.json(JourneyFixtures.allCallbackTypesNode()),
        MockResponse.json(JourneyFixtures.success()),
      ],
    );
    addTearDown(harness.dispose);

    final node = harness.expectContinue(
      await harness.client.start(harness.journeyName, forceAuth: true),
    );

    expect(node.header, 'Everything');
    expect(node.description, 'One page per mapped callback type');
    expect(node.stage, 'MappingCoverage');
    expect(node.callbacks, hasLength(12));

    final name = node.callbacks.whereType<NameCallback>().single;
    expect(name.prompt, 'User Name');

    final password = node.callbacks.whereType<PasswordCallback>().single;
    expect(password.prompt, 'Password');
    // The native SDK never round-trips the password back to Dart; it always arrives empty.
    expect(password.password, isEmpty);

    final validatedUsername = node.callbacks
        .whereType<ValidatedUsernameCallback>()
        .single;
    expect(
      validatedUsername.type,
      CallbackType.validatedCreateUsernameCallback,
    );
    expect(validatedUsername.prompt, 'Username');
    expect(validatedUsername.validateOnly, isFalse);
    expect(validatedUsername.policies?['name'], 'userName');
    expect(validatedUsername.failedPolicies, isEmpty);

    final validatedPassword = node.callbacks
        .whereType<ValidatedPasswordCallback>()
        .single;
    expect(
      validatedPassword.type,
      CallbackType.validatedCreatePasswordCallback,
    );
    expect(validatedPassword.echoOn, isFalse);
    // AM sends failedPolicies as an array of JSON-encoded strings; the native SDKs parse each into
    // {policyRequirement, params}. A non-empty list here is the whole point — an empty one would
    // sail past the unchecked cast in Pigeon's decoder that this shape is guarding against.
    expect(validatedPassword.failedPolicies, hasLength(1));
    expect(
      validatedPassword.failedPolicies.single['policyRequirement'],
      'LENGTH_BASED',
    );
    expect(
      (validatedPassword.failedPolicies.single['params']
          as Map<Object?, Object?>?)?['min-password-length'],
      8,
    );

    final choice = node.callbacks.whereType<ChoiceCallback>().single;
    expect(choice.choices, <String>['Email', 'SMS', 'Authenticator']);
    expect(choice.defaultChoice, 1);
    // Selection defaults to the server's suggestion rather than to zero.
    expect(choice.selectedIndex, 1);

    final kba = node.callbacks.whereType<KbaCreateCallback>().single;
    expect(kba.predefinedQuestions, hasLength(2));
    expect(kba.predefinedQuestions.first, "What's your favorite colour?");
    expect(kba.allowUserDefinedQuestions, isFalse);

    final terms = node.callbacks.whereType<TermsAndConditionsCallback>().single;
    expect(terms.version, '0.0');
    expect(terms.terms, 'Be excellent to each other.');
    expect(terms.createDate, '2026-01-15T00:00:00.000Z');
    expect(terms.accepted, isFalse);

    final textInput = node.callbacks.whereType<TextInputCallback>().single;
    expect(textInput.defaultText, 'anonymous');
    // text initializes from defaultText so the UI can render a prefilled field.
    expect(textInput.text, 'anonymous');

    final textOutput = node.callbacks.whereType<TextOutputCallback>().single;
    expect(textOutput.message, 'Your session will expire soon.');
    // AM's numeric messageType (1 = warning) survives as the parsed enum, despite Android sending
    // the Kotlin enum name and iOS sending the lower-cased Swift case.
    expect(textOutput.messageType, TextOutputMessageType.warning);

    final stringAttribute = node.callbacks
        .whereType<StringAttributeInputCallback>()
        .single;
    expect(stringAttribute.name, 'givenName');
    expect(stringAttribute.prompt, 'First Name');
    expect(stringAttribute.required, isTrue);
    expect(stringAttribute.failedPolicies, hasLength(1));
    expect(
      stringAttribute.failedPolicies.single['policyRequirement'],
      'REQUIRED',
    );

    final numberAttribute = node.callbacks
        .whereType<NumberAttributeInputCallback>()
        .single;
    expect(numberAttribute.name, 'age');
    expect(numberAttribute.required, isFalse);
    // AM's JSON number arrives as a Dart double regardless of how it was written.
    expect(numberAttribute.value, 21.0);

    final booleanAttribute = node.callbacks
        .whereType<BooleanAttributeInputCallback>()
        .single;
    expect(booleanAttribute.name, 'preferences/marketing');
    expect(booleanAttribute.value, isFalse);

    // Now fill everything and submit, to prove the reverse direction maps too.
    name.name = 'newuser';
    password.password = 'sup3r-s3cret';
    validatedUsername.username = 'newuser';
    validatedPassword.password = 'sup3r-s3cret';
    choice.selectedIndex = 2;
    kba.selectedQuestion = 'Who was your first employer?';
    kba.selectedAnswer = 'Ping Identity';
    terms.accepted = true;
    textInput.text = 'newbie';
    stringAttribute.value = 'Ada';
    numberAttribute.value = 36;
    booleanAttribute.value = true;

    harness.expectSuccess(await harness.client.next(node));

    final submitted = harness.mock.authenticateRequests[1];
    expect(submitted.json?['authId'], JourneyFixtures.authId);
    expect(submitted.inputValues(0)['IDToken1'], 'newuser');
    expect(submitted.inputValues(1)['IDToken2'], 'sup3r-s3cret');
    expect(submitted.inputValues(2)['IDToken3'], 'newuser');
    expect(submitted.inputValues(3)['IDToken4'], 'sup3r-s3cret');
    expect(submitted.inputValues(4)['IDToken5'], 2);
    expect(
      submitted.inputValues(5)['IDToken6question'],
      'Who was your first employer?',
    );
    expect(submitted.inputValues(5)['IDToken6answer'], 'Ping Identity');
    expect(submitted.inputValues(6)['IDToken7'], isTrue);
    expect(submitted.inputValues(7)['IDToken8'], 'newbie');
    expect(submitted.inputValues(9)['IDToken10'], 'Ada');
    expect(submitted.inputValues(10)['IDToken11'], 36);
    expect(submitted.inputValues(11)['IDToken12'], isTrue);

    harness.mock.expectNoUnmatchedRequests();
  });
}
