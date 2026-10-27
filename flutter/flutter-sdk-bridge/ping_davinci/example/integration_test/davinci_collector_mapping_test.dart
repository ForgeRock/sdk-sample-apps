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

/// The mapping sweep: one scripted form carrying all 17 core collector keys (including a
/// `DROPDOWN`/`RADIO` pair, both `SINGLE_SELECT`) arrives as the right `Collector` subtypes with
/// their fields intact, through the real native SDK. Its two unregistered fields come back as
/// `unsupportedFields`, and the rest of the form still submits — with only value-bearing
/// collectors in the payload.
///
/// **Hermetic only**: no real tenant emits all 17 keys on request, and asserting one tenant's
/// form would be asserting that tenant's configuration.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every core collector maps to its subtype and submits', (
    tester,
  ) async {
    if (E2eConfig.isLive) {
      markTestSkipped(
        'The mapping sweep is hermetic only: no real tenant emits all 17 collector keys '
        'in one form on request.',
      );
      return;
    }
    final harness = await DaVinciHarness.create(
      liveAcr: '',
      hermeticAcr: 'collector-sweep',
      hermeticFlow: (baseUrl) => [
        DaVinciFixtures.collectorSweep(baseUrl),
        DaVinciFixtures.formFieldsSubmitted(baseUrl),
      ],
    );
    addTearDown(harness.dispose);

    final start = await harness.client.start();
    expect(start, isA<ContinueNode>(), reason: harness.diagnose(start));
    final form = start as ContinueNode;

    // Native dropped ERROR_DISPLAY and the unregistered field; everything else is a collector,
    // addressed by its position.
    expect(form.collectors.map((c) => '${c.type}/${c.runtimeType}'), <String>[
      'LABEL/LabelCollector',
      'LABEL/LabelCollector',
      'LABEL/LabelCollector',
      'TEXT/TextCollector',
      'CHECKBOX/MultiSelectCollector',
      'DROPDOWN/SingleSelectCollector',
      'RADIO/SingleSelectCollector',
      'COMBOBOX/MultiSelectCollector',
      'PHONE_NUMBER/PhoneNumberCollector',
      'SINGLE_CHECKBOX/BooleanCollector',
      'FLOW_BUTTON/FlowCollector',
      'FLOW_LINK/FlowCollector',
      'TEXT/TextCollector',
      'PASSWORD/PasswordCollector',
      'TEXT/TextCollector',
      'PASSWORD_VERIFY/PasswordCollector',
      'AGREEMENT/ReadOnlyTextCollector',
      'IMAGE/ImageCollector',
      'QR_CODE/QRCodeCollector',
      'POLLING/PollingCollector',
      'DEVICE_REGISTRATION/DeviceRegistrationCollector',
      'DEVICE_AUTHENTICATION/DeviceAuthenticationCollector',
      'METADATA/MetadataCollector',
      'SUBMIT_BUTTON/SubmitCollector',
    ]);
    expect(
      form.collectors.map((c) => c.index),
      List<int>.generate(form.collectors.length, (i) => i),
    );
    expect(
      form.unsupportedFields.map((f) => (f.key, f.type, f.reason)),
      <(String?, String, UnsupportedFieldReason)>[
        (null, 'ERROR_DISPLAY', UnsupportedFieldReason.knownIgnorable),
        ('future-field', 'FUTURE_FIELD', UnsupportedFieldReason.unknown),
      ],
    );

    // Display collectors.
    final [plain, translatable, linked, ...] = form.collectors;
    expect((plain as LabelCollector).key, isEmpty);
    expect(plain.content, contains('Rich Text fields produce LABELs'));
    expect(
      (translatable as LabelCollector).richContent?.content,
      'Translatable Rich Text produce LABELs too!',
    );
    final link = (linked as LabelCollector).richContent!.replacements['link2']!;
    expect(
      (link.value, link.href, link.type, link.target),
      ('apple.com', 'https://www.apple.com', 'link', '_blank'),
    );
    final agreement = collectorWithKey<ReadOnlyTextCollector>(
      form,
      'agreement',
    );
    expect(agreement.title, 'Terms of Service Agreement');
    expect(agreement.titleEnabled, isTrue);
    expect(agreement.agreementId, '1c3de4cc-74c0-4a42-b484-4047b10122ce');
    expect(agreement.content, startsWith('This is example agreement text'));
    final image = collectorWithKey<ImageCollector>(form, 'image');
    expect(image.imageDescription, 'Image Collector Test');
    expect(image.imageUrl, startsWith('https://img.magnific.com/'));
    expect(image.hyperlinkUrl, 'https://www.pingidentity.com/en.html');
    final qrCode = collectorWithKey<QRCodeCollector>(form, 'qr-code');
    expect(qrCode.content, DaVinciFixtures.qrCodeContent());
    expect(qrCode.imageBytes, isNotEmpty);
    expect(qrCode.fallbackText, startsWith("If you can't scan the QR code"));

    // Polling, devices and metadata.
    final polling = collectorWithKey<PollingCollector>(form, 'polling-field');
    expect(
      (polling.pollInterval, polling.pollRetries, polling.retriesAllowed),
      (const Duration(seconds: 2), 3, 3),
    );
    expect((polling.pollChallengeStatus, polling.challenge), (false, null));
    final registration = collectorWithKey<DeviceRegistrationCollector>(
      form,
      'device-registration',
    );
    expect(registration.devices.map((d) => (d.id, d.type, d.isDefault)), [
      (null, 'EMAIL', false),
      (null, 'SMS', false),
      (null, 'VOICE', false),
    ]);
    expect(registration.devices.first.title, 'Email');
    expect(
      registration.devices.first.iconSrc,
      endsWith('icon-outline-mail.svg'),
    );
    final authentication = collectorWithKey<DeviceAuthenticationCollector>(
      form,
      'device-authentication',
    );
    expect(authentication.devices.map((d) => (d.id, d.isDefault)), [
      ('fixture-device-1', true),
      ('fixture-device-2', false),
      ('fixture-device-3', false),
    ]);
    final metadata = collectorWithKey<MetadataCollector>(form, 'sdkMetadata');
    expect(metadata.metadata, {'testkey': 'testValue'});
    expect(form.canSubmit, isFalse, reason: 'no device or metadata result yet');

    // Value collectors, with their formData defaults.
    final text = collectorWithKey<TextCollector>(form, 'text-input-key');
    expect(
      (text.label, text.required, text.value),
      ('Text Input Label', true, 'default text'),
    );
    final email = collectorWithKey<TextCollector>(form, 'user.email');
    expect(email.validation?.regex, r'^[^@]+@[^@]+\.[^@]+$');
    expect(email.validation?.errorMessage, 'Not a valid email');
    final checkbox = collectorWithKey<MultiSelectCollector>(
      form,
      'checkbox-field-key',
    );
    expect(checkbox.value, ['option1 value', 'option2 value']);
    expect(checkbox.options.map((o) => o.label), [
      'option1 label',
      'option2 label',
    ]);
    final dropdown = collectorWithKey<SingleSelectCollector>(
      form,
      'dropdown-field-key',
    );
    expect(dropdown.value, 'dropdown-option2-value');
    expect(dropdown.options, hasLength(3));
    final radio = collectorWithKey<SingleSelectCollector>(
      form,
      'radio-group-key',
    );
    expect(radio.value, 'option2 value');
    final combobox = collectorWithKey<MultiSelectCollector>(
      form,
      'combobox-field-key',
    );
    expect(combobox.value, ['option1 value', 'option3 value']);
    final phone = collectorWithKey<PhoneNumberCollector>(form, 'phone-field');
    expect(
      phone.value,
      const PhoneNumberValue(
        countryCode: 'GB',
        phoneNumber: '(555)555-1234',
        phoneExtension: '4321',
      ),
    );
    expect(
      (phone.defaultCountryCode, phone.showExtension, phone.extensionLabel),
      ('BF', true, 'Extension'),
      reason:
          'Android loses extensionLabel to the formData default unless the bridge restores it',
    );
    final boolean = collectorWithKey<BooleanCollector>(
      form,
      'single-checkbox-field',
    );
    expect(boolean.appearance, BooleanAppearance.toggleSwitch);
    expect(boolean.errorMessage, 'Select the checkbox to continue.');
    expect(
      boolean.richContent?.replacements['link1']?.value,
      'Terms and Conditions',
    );
    final password = collectorWithKey<PasswordCollector>(form, 'password');
    expect(password.passwordPolicy, isNull);
    final verify = collectorWithKey<PasswordCollector>(form, 'user.password');
    expect(verify.value, isEmpty, reason: 'its formData default never crosses');
    final policy = verify.passwordPolicy!;
    expect(
      (policy.lengthMin, policy.lengthMax, policy.maxRepeatedCharacters),
      (8, 255, 2),
    );
    expect(policy.minCharacters, hasLength(4));
    expect(
      collectorWithKey<FlowCollector>(form, 'flow-link-field').label,
      'Flow Link',
    );

    // Submit: every value-bearing type, the submit button pressed.
    text.value = 'Flutter';
    collectorWithKey<TextCollector>(form, 'username').value = 'alice';
    email.value = 'alice@example.com';
    password.value = 'Passw0rd!';
    verify.value = 'Passw0rd!';
    checkbox.value = ['option2 value'];
    dropdown.value = 'dropdown-option3-value';
    radio.value = 'option1 value';
    combobox.value = [];
    phone.value = const PhoneNumberValue(
      countryCode: 'US',
      phoneNumber: '2015550123',
    );
    boolean.value = true;
    registration.selectDevice(registration.devices.first);
    authentication.selectDevice(authentication.devices[1]);
    collectorWithKey<SubmitCollector>(form, 'submit').select();

    final next = await harness.client.next(form);
    expect(next, isA<ContinueNode>(), reason: harness.diagnose(next));
    expect((next as ContinueNode).name, 'Success');

    final mock = harness.mock!;
    mock.expectNoUnmatchedRequests();
    final submit = mock.flowRequests.last;
    expect((submit.json?['parameters'] as Map)['eventType'], 'submit');
    expect(submit.submittedData?['actionKey'], 'submit');
    final formData = (submit.submittedData?['formData'] as Map)
        .cast<String, Object?>();
    expect(formData, <String, Object?>{
      'text-input-key': 'Flutter',
      'checkbox-field-key': ['option2 value'],
      'dropdown-field-key': 'dropdown-option3-value',
      'radio-group-key': 'option1 value',
      // An emptied multi-select has no payload, so it is left out.
      'phone-field': {
        'countryCode': 'US',
        'phoneNumber': '2015550123',
        'extension': '',
      },
      'single-checkbox-field': true,
      'username': 'alice',
      'password': 'Passw0rd!',
      'user.email': 'alice@example.com',
      'user.password': 'Passw0rd!',
      // Registration submits the type; authentication the device's type, id and description.
      'device-registration': 'EMAIL',
      'device-authentication': {
        'type': 'SMS',
        'id': 'fixture-device-2',
        'description': 'Receive an authentication passcode in a text message.',
      },
      // Buttons become the actionKey, never formData; display collectors, a polling collector
      // that hasn't polled and metadata without a result have no payload.
    });
  });
}
