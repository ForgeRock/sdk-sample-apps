/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ping_davinci/ping_davinci.dart';

/// Compiles only while the `switch` covers every [Collector] subtype with no default branch —
/// the proof that a form builder over [Collector] is exhaustively checked.
String describe(Collector collector) => switch (collector) {
  TextCollector() => 'text',
  PasswordCollector() => 'password',
  SingleSelectCollector() => 'singleSelect',
  SubmitCollector() => 'submit',
  FlowCollector() => 'flow',
  MultiSelectCollector() => 'multiSelect',
  BooleanCollector() => 'boolean',
  PhoneNumberCollector() => 'phoneNumber',
  LabelCollector() => 'label',
  ReadOnlyTextCollector() => 'readOnlyText',
  ImageCollector() => 'image',
  QRCodeCollector() => 'qrCode',
  PollingCollector() => 'polling',
  DeviceRegistrationCollector() => 'deviceRegistration',
  DeviceAuthenticationCollector() => 'deviceAuthentication',
  MetadataCollector() => 'metadata',
  AddOnCollector() => 'addOn',
};

CollectorMessage message(
  String type,
  String kind, {
  int index = 0,
  String key = 'field',
  Object? value,
}) => CollectorMessage(
  type: type,
  index: index,
  kind: kind,
  id: key,
  key: key,
  label: 'Label',
  required: true,
  value: value,
);

/// A stand-in for an add-on package's collector.
final class _ProtectCollector extends AddOnCollector {
  _ProtectCollector(super.message);

  @override
  CollectorValueMessage? toValue() => null;
}

void main() {
  group('Collector.fromMessage', () {
    test('every core kind maps to its own subtype', () {
      final kinds = <String>[
        CollectorKind.text,
        CollectorKind.password,
        CollectorKind.singleSelect,
        CollectorKind.submit,
        CollectorKind.flow,
        CollectorKind.multiSelect,
        CollectorKind.boolean,
        CollectorKind.phoneNumber,
        CollectorKind.label,
        CollectorKind.readOnlyText,
        CollectorKind.image,
        CollectorKind.qrCode,
        CollectorKind.polling,
        CollectorKind.deviceRegistration,
        CollectorKind.deviceAuthentication,
        CollectorKind.metadata,
      ];

      expect(
        kinds.map(
          (kind) => describe(Collector.fromMessage(message('X', kind))),
        ),
        kinds,
      );
    });

    test('keeps the shared fields', () {
      final collector = Collector.fromMessage(
        message('DROPDOWN', CollectorKind.singleSelect, index: 4, key: 'k'),
      );

      expect(collector.type, 'DROPDOWN');
      expect(collector.kind, 'singleSelect');
      expect(collector.index, 4);
      expect(collector.id, 'k');
      expect(collector.key, 'k');
      expect((collector as FieldCollector<String>).label, 'Label');
      expect(collector.required, isTrue);
    });

    test('an unknown kind throws an UnsupportedError naming the type', () {
      expect(
        () => Collector.fromMessage(message('MOBILE_PAIRING', 'mobilePairing')),
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            allOf(contains('"MOBILE_PAIRING"'), contains('"mobilePairing"')),
          ),
        ),
      );
      expect(
        Collector.tryFromMessage(message('MOBILE_PAIRING', 'mobilePairing')),
        isNull,
      );
    });

    test('an add-on kind maps once registered', () {
      final protect = message('PROTECT', 'protect');
      expect(Collector.tryFromMessage(protect), isNull);

      Collector.registerAddOn('protect', _ProtectCollector.new);

      final collector = Collector.fromMessage(protect);
      expect(collector, isA<_ProtectCollector>());
      expect(describe(collector), 'addOn');
      expect(collector.toValue(), isNull);
    });

    test('a core kind cannot be registered as an add-on', () {
      expect(
        () =>
            Collector.registerAddOn(CollectorKind.text, _ProtectCollector.new),
        throwsArgumentError,
      );
    });
  });

  group('round trip: CollectorMessage -> Collector -> CollectorValueMessage', () {
    /// `[type, index, value]` — a list, so `expect` compares the value deeply.
    List<Object?> wire(Collector collector) {
      final value = collector.toValue()!;
      return [value.type, value.index, value.value];
    }

    test('nothing is submitted until the app sets a value', () {
      final text =
          Collector.fromMessage(
                message('TEXT', CollectorKind.text, value: 'default'),
              )
              as TextCollector;

      expect(text.value, 'default');
      expect(text.hasChanged, isFalse);
      expect(text.toValue(), isNull);
    });

    test('text', () {
      final text =
          Collector.fromMessage(
                CollectorMessage(
                  type: 'TEXT',
                  index: 2,
                  kind: CollectorKind.text,
                  value: 'default',
                  validationRegex: r'^[a-z]+$',
                  validationErrorMessage: 'Lowercase only',
                ),
              )
              as TextCollector;

      expect(text.validation?.regex, r'^[a-z]+$');
      expect(text.validation?.errorMessage, 'Lowercase only');
      text.value = 'alice';
      expect(text.hasChanged, isTrue);
      expect(wire(text), ['TEXT', 2, 'alice']);
    });

    test('password, starting empty whatever native sends', () {
      final password =
          Collector.fromMessage(
                CollectorMessage(
                  type: 'PASSWORD_VERIFY',
                  index: 3,
                  kind: CollectorKind.password,
                  value: 'never-sent',
                  passwordPolicy: PasswordPolicyMessage(
                    lengthMin: 8,
                    minUniqueCharacters: 5,
                    maxRepeatedCharacters: 2,
                    minCharacters: <String?, int?>{'0123456789': 1, null: 3},
                  ),
                ),
              )
              as PasswordCollector;

      expect(password.value, isEmpty);
      expect(password.validation, isNull);
      final policy = password.passwordPolicy!;
      expect(policy.lengthMin, 8);
      expect(policy.lengthMax, isNull, reason: 'unbounded');
      expect(policy.minUniqueCharacters, 5);
      expect(policy.maxRepeatedCharacters, 2);
      expect(policy.minCharacters, {'0123456789': 1});
      password.value = 's3cret!';
      expect(wire(password), ['PASSWORD_VERIFY', 3, 's3cret!']);
    });

    test('a password with no policy has none', () {
      final password =
          Collector.fromMessage(message('PASSWORD', CollectorKind.password))
              as PasswordCollector;
      expect(password.passwordPolicy, isNull);
    });

    test('single select', () {
      final select =
          Collector.fromMessage(
                CollectorMessage(
                  type: 'RADIO',
                  index: 1,
                  kind: CollectorKind.singleSelect,
                  value: 'b',
                  options: [
                    OptionMessage(label: 'A', value: 'a'),
                    null,
                    OptionMessage(label: 'B', value: 'b'),
                  ],
                ),
              )
              as SingleSelectCollector;

      expect(select.options, const [
        Option(label: 'A', value: 'a'),
        Option(label: 'B', value: 'b'),
      ]);
      expect(select.value, 'b');
      select.value = 'a';
      expect(wire(select), ['RADIO', 1, 'a']);
    });

    test('multi select, with an unmodifiable value', () {
      final multi =
          Collector.fromMessage(
                CollectorMessage(
                  type: 'COMBOBOX',
                  index: 5,
                  kind: CollectorKind.multiSelect,
                  value: <Object?>['a', 'c'],
                  options: [OptionMessage(label: 'A', value: 'a')],
                ),
              )
              as MultiSelectCollector;

      expect(multi.value, ['a', 'c']);
      expect(() => multi.value.add('b'), throwsUnsupportedError);
      expect(multi.hasChanged, isFalse);
      multi.value = [...multi.value, 'b'];
      expect(wire(multi), [
        'COMBOBOX',
        5,
        ['a', 'c', 'b'],
      ]);
      expect(() => multi.value.clear(), throwsUnsupportedError);
    });

    test('boolean, with appearance and rich content', () {
      final boolean =
          Collector.fromMessage(
                CollectorMessage(
                  type: 'SINGLE_CHECKBOX',
                  index: 0,
                  kind: CollectorKind.boolean,
                  value: false,
                  appearance: 'SWITCH',
                  errorMessage: 'Select the checkbox to continue.',
                  richContent: RichContentMessage(
                    content: 'I agree to the {{link1}}',
                    replacements: [
                      RichContentReplacementMessage(
                        key: 'link1',
                        value: 'Terms',
                        href: 'https://example.com/terms',
                        type: 'link',
                        target: '_blank',
                      ),
                    ],
                  ),
                ),
              )
              as BooleanCollector;

      expect(boolean.value, isFalse);
      expect(boolean.appearance, BooleanAppearance.toggleSwitch);
      expect(boolean.errorMessage, 'Select the checkbox to continue.');
      expect(boolean.richContent!.content, 'I agree to the {{link1}}');
      final link = boolean.richContent!.replacements['link1']!;
      expect(link.value, 'Terms');
      expect(link.href, 'https://example.com/terms');
      expect(link.type, 'link');
      expect(link.target, '_blank');
      boolean.value = true;
      expect(wire(boolean), ['SINGLE_CHECKBOX', 0, true]);
    });

    test('boolean appearance defaults to a checkbox', () {
      final boolean =
          Collector.fromMessage(
                message('SINGLE_CHECKBOX', CollectorKind.boolean),
              )
              as BooleanCollector;
      expect(boolean.appearance, BooleanAppearance.checkbox);
      expect(boolean.value, isFalse);
      expect(boolean.richContent, isNull);
    });

    test('phone number, as three parts', () {
      final phone =
          Collector.fromMessage(
                CollectorMessage(
                  type: 'PHONE_NUMBER',
                  index: 8,
                  kind: CollectorKind.phoneNumber,
                  defaultCountryCode: 'BF',
                  validatePhoneNumber: true,
                  showExtension: true,
                  extensionLabel: 'Extension',
                  countryCode: 'GB',
                  phoneNumber: '(555)555-1234',
                  phoneExtension: '4321',
                ),
              )
              as PhoneNumberCollector;

      expect(phone.defaultCountryCode, 'BF');
      expect(phone.validatePhoneNumber, isTrue);
      expect(phone.showExtension, isTrue);
      expect(phone.extensionLabel, 'Extension');
      expect(
        phone.value,
        const PhoneNumberValue(
          countryCode: 'GB',
          phoneNumber: '(555)555-1234',
          phoneExtension: '4321',
        ),
      );
      phone.value = phone.value.copyWith(countryCode: 'US', phoneExtension: '');
      expect(wire(phone), [
        'PHONE_NUMBER',
        8,
        {
          'countryCode': 'US',
          'phoneNumber': '(555)555-1234',
          'phoneExtension': '',
        },
      ]);
    });

    test('submit and flow buttons submit their key when selected', () {
      final submit =
          Collector.fromMessage(
                message(
                  'SUBMIT_BUTTON',
                  CollectorKind.submit,
                  index: 6,
                  key: 'SIGNON',
                  value: '',
                ),
              )
              as SubmitCollector;
      final flow =
          Collector.fromMessage(
                message(
                  'FLOW_LINK',
                  CollectorKind.flow,
                  index: 7,
                  key: 'TROUBLE',
                ),
              )
              as FlowCollector;

      expect(submit.value, isEmpty);
      expect(submit.toValue(), isNull);
      submit.select();
      flow.select();
      expect(wire(submit), ['SUBMIT_BUTTON', 6, 'SIGNON']);
      expect(wire(flow), ['FLOW_LINK', 7, 'TROUBLE']);
    });

    test(
      'label, read-only text, and image carry their fields and submit nothing',
      () {
        final label =
            Collector.fromMessage(
                  CollectorMessage(
                    type: 'LABEL',
                    index: 0,
                    kind: CollectorKind.label,
                    content: 'Hello',
                    richContent: RichContentMessage(content: 'Hello'),
                  ),
                )
                as LabelCollector;
        final agreement =
            Collector.fromMessage(
                  CollectorMessage(
                    type: 'AGREEMENT',
                    index: 1,
                    kind: CollectorKind.readOnlyText,
                    key: 'agreement',
                    content: 'Terms text',
                    title: 'Terms of Service',
                    titleEnabled: true,
                    enabled: true,
                    agreementId: 'agreement-id',
                    useDynamicAgreement: false,
                  ),
                )
                as ReadOnlyTextCollector;
        final image =
            Collector.fromMessage(
                  CollectorMessage(
                    type: 'IMAGE',
                    index: 2,
                    kind: CollectorKind.image,
                    key: 'image',
                    imageUrl: 'https://example.com/a.png',
                    imageDescription: 'An image',
                    hyperlinkUrl: 'https://example.com',
                  ),
                )
                as ImageCollector;

        expect(label.key, isEmpty, reason: 'labels may have no key');
        expect(label.content, 'Hello');
        expect(label.richContent!.replacements, isEmpty);
        expect(agreement.content, 'Terms text');
        expect(agreement.title, 'Terms of Service');
        expect(agreement.titleEnabled, isTrue);
        expect(agreement.enabled, isTrue);
        expect(agreement.agreementId, 'agreement-id');
        expect(agreement.useDynamicAgreement, isFalse);
        expect(image.imageUrl, 'https://example.com/a.png');
        expect(image.imageDescription, 'An image');
        expect(image.hyperlinkUrl, 'https://example.com');
        expect([label, agreement, image].map((c) => c.toValue()), [
          null,
          null,
          null,
        ]);
      },
    );
  });
  group('Phase 6 collectors', () {
    /// A captured field from `example/integration_test/support/fixtures/<name>.json`.
    Map<String, Object?> capturedField(String name, String type) {
      final node =
          jsonDecode(
                File(
                  'example/integration_test/support/fixtures/$name.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final fields =
          ((node['form']! as Map)['components']! as Map)['fields']! as List;
      return (fields.cast<Map<String, Object?>>()).firstWhere(
        (field) => field['type'] == type,
      );
    }

    test('a captured QR code decodes to PNG bytes', () {
      final field = capturedField('qrCodeForm', 'QR_CODE');
      final qrCode =
          Collector.fromMessage(
                CollectorMessage(
                  type: 'QR_CODE',
                  index: 0,
                  kind: CollectorKind.qrCode,
                  key: 'qr-code',
                  content: field['content']! as String,
                  fallbackText: field['fallbackText']! as String,
                ),
              )
              as QRCodeCollector;

      final bytes = qrCode.imageBytes!;
      // The PNG signature.
      expect(bytes.take(8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      expect(qrCode.fallbackText, startsWith("If you can't scan the QR code"));
      expect(qrCode.toValue(), isNull);
    });

    test('a QR code that is not base64 has no bytes', () {
      QRCodeCollector qr(String content) =>
          Collector.fromMessage(
                CollectorMessage(
                  type: 'QR_CODE',
                  index: 0,
                  kind: CollectorKind.qrCode,
                  content: content,
                ),
              )
              as QRCodeCollector;

      expect(qr('data:image/png;base64,***not base64***').imageBytes, isNull);
      expect(qr('https://example.com/qr.png').imageBytes, isNull);
      expect(qr('').imageBytes, isNull);
      expect(qr('').fallbackText, isEmpty);
    });

    test('polling carries its configuration and submits nothing itself', () {
      final polling =
          Collector.fromMessage(
                CollectorMessage(
                  type: 'POLLING',
                  index: 2,
                  kind: CollectorKind.polling,
                  key: 'polling-field',
                  pollIntervalMillis: 2000,
                  pollRetries: 3,
                  retriesAllowed: 2,
                  pollChallengeStatus: true,
                  challenge: 'abc',
                ),
              )
              as PollingCollector;

      expect(polling.pollInterval, const Duration(seconds: 2));
      expect((polling.pollRetries, polling.retriesAllowed), (3, 2));
      expect(polling.pollChallengeStatus, isTrue);
      expect(polling.challenge, 'abc');
      expect(polling.toValue(), isNull);
    });

    CollectorMessage deviceMessage(String kind, List<DeviceMessage> devices) =>
        CollectorMessage(
          type: kind == CollectorKind.deviceRegistration
              ? 'DEVICE_REGISTRATION'
              : 'DEVICE_AUTHENTICATION',
          index: 1,
          kind: kind,
          key: 'device',
          required: true,
          devices: devices,
        );

    test('selecting an authentication device sends its id and type', () {
      final collector =
          Collector.fromMessage(
                deviceMessage(CollectorKind.deviceAuthentication, [
                  DeviceMessage(id: 'd1', type: 'EMAIL', isDefault: true),
                  DeviceMessage(
                    id: 'd2',
                    type: 'SMS',
                    title: 'Text',
                    deviceDescription: 'A text message',
                  ),
                ]),
              )
              as DeviceAuthenticationCollector;
      final node = ContinueNode(collectors: [collector]);

      expect(collector.devices.first.isDefault, isTrue);
      expect(collector.devices.last.description, 'A text message');
      expect(collector.toValue(), isNull);
      expect(node.canSubmit, isFalse, reason: 'required, and no device yet');

      collector.selectDevice(collector.devices.last);

      final value = collector.toValue()!;
      expect((value.type, value.index), ('DEVICE_AUTHENTICATION', 1));
      expect(value.value, {'id': 'd2', 'type': 'SMS'});
      expect(node.canSubmit, isTrue);
    });

    test('selecting a registration device sends its type alone', () {
      final collector =
          Collector.fromMessage(
                deviceMessage(CollectorKind.deviceRegistration, [
                  DeviceMessage(type: 'EMAIL'),
                  DeviceMessage(type: 'SMS'),
                ]),
              )
              as DeviceRegistrationCollector;

      collector.selectDevice(collector.devices.first);

      expect(collector.toValue()!.value, {'type': 'EMAIL'});
      expect(
        () => collector.selectDevice(const Device(type: 'VOICE')),
        throwsArgumentError,
      );
    });

    test(
      'metadata sends a result or an error, and blocks submit until then',
      () {
        MetadataCollector metadata() =>
            Collector.fromMessage(
                  CollectorMessage(
                    type: 'METADATA',
                    index: 0,
                    kind: CollectorKind.metadata,
                    key: 'sdkMetadata',
                    required: false,
                    metadata: <String?, Object?>{'testkey': 'testValue'},
                  ),
                )
                as MetadataCollector;

        final success = metadata();
        final node = ContinueNode(collectors: [success]);
        expect(success.metadata, {'testkey': 'testValue'});
        expect(success.required, isTrue, reason: 'native validates it anyway');
        expect(node.canSubmit, isFalse);
        expect(success.toValue(), isNull);

        success.setResult({'ok': true, 'count': 2});
        expect(success.toValue()!.value, {
          'result': {'ok': true, 'count': 2},
        });
        expect(node.canSubmit, isTrue);

        final failure = metadata()..setError('USER_CANCELLED', 'No');
        expect(failure.value, isA<MetadataFailure>());
        expect(failure.toValue()!.value, {
          'error': {'code': 'USER_CANCELLED', 'message': 'No'},
        });
      },
    );
  });
}
