/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

// Captures the hermetic mock server's DaVinci responses from the live test tenant.
//
// Run on the host, not the device, from `ping_davinci/example`:
//
//   dart run integration_test/support/capture_fixtures.dart ../../../.env
//
// The argument is the gitignored `flutter/.env` (non-secret tenant configuration only). Every
// captured flow is anonymous — no username or password is used or needed. The script replays what
// the native SDK sends: discovery, then a PKCE authorize request with `response_mode=pi.flow` and
// the SDK's `x-requested-*` headers (without them PingOne answers with the HTML-connector shape),
// then a POST to `_links.next.href` that picks a menu branch the way a `FlowCollector` does. A
// cookie jar carries the DaVinci session across the requests. Two captures are deliberate `400`s
// (a sign-on for a nonexistent user, a registration whose password fails the policy), recorded
// for the `ErrorNode` scenarios; neither creates anything on the tenant.
//
// Before writing `davinci_captured_fixtures.dart` it scrubs `interactionId`/`interactionToken`
// and replaces the tenant origin with `{{baseUrl}}`, which `DaVinciFixtures` swaps for the mock
// server's loopback URL. It also writes each node as `support/fixtures/<name>.json`, which the
// native unit tests read (Android as test resources, iOS from the source tree), so every tier
// tests against the same captured payloads.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'usage: dart run integration_test/support/capture_fixtures.dart <path/to/.env>',
    );
    exit(64);
  }
  final env = _readEnv(File(args.single));
  final captured = <String, Map<String, Object?>>{};
  String? origin;

  // One fresh session (cookie jar) per branch, since each branch restarts its flow.
  Future<void> branch(String acr, String key, String name) async {
    final capture = _Capture(env);
    final menu = await capture.authorize(env[acr]!);
    captured[name] = await capture.chooseBranch(menu, key);
    origin = capture.origin;
    capture.close();
  }

  final capture = _Capture(env);
  final menu = await capture.authorize(env['E2E_ACR_FORM_FIELDS']!);
  captured['formFieldsMenu'] = menu;
  captured['formFieldsForm'] = await capture.chooseBranch(menu, 'Form Fields');
  capture.close();

  // What the tenant answers a completed form with, submitted the way `ContinueNode.next()` does:
  // `formData` keyed by collector id with each collector's payload, the pressed button's key as
  // `actionKey`.
  final submit = _Capture(env);
  final submitMenu = await submit.authorize(env['E2E_ACR_FORM_FIELDS']!);
  final submitForm = await submit.chooseBranch(submitMenu, 'Form Fields');
  captured['formFieldsSubmitted'] = await submit.submit(
    submitForm,
    'submit',
    <String, Object?>{
      'text-input-key': 'Flutter',
      'checkbox-field-key': <String>['option1 value'],
      'dropdown-field-key': 'dropdown-option3-value',
      'radio-group-key': 'option1 value',
      'combobox-field-key': <String>['option2 value'],
      'phone-field': <String, Object?>{
        'countryCode': 'US',
        'phoneNumber': '2015550123',
        'extension': '',
      },
      'single-checkbox-field': true,
    },
  );
  submit.close();

  await branch('E2E_ACR_FORM_FIELDS', 'Form Validation', 'formValidationForm');
  await branch('E2E_ACR_FORM_FIELDS', 'Agreement Test', 'agreementForm');
  await branch('E2E_ACR_METADATA_IMAGE', 'Image', 'imageForm');
  final sso = _Capture(env);
  captured['ssoMenu'] = await sso.authorize(env['E2E_ACR_SSO']!);
  sso.close();

  // The tenant's two recoverable 4xx shapes. A sign-on for a user that doesn't exist fails the
  // `userLookup` with `details[].rawResponse` but no `target`. A registration whose password
  // fails the policy fails `createUser` with `target: "password"` and an `innerError`; PingOne
  // rejects the whole request, so no user is created.
  final wrong = _Capture(env);
  final wrongMenu = await wrong.authorize(env['E2E_ACR_SSO']!);
  captured['ssoWrongPassword'] = await wrong.submit(
    wrongMenu,
    'SIGNON',
    <String, Object?>{
      'username': 'flutter-fixture-nobody',
      'password': 'Not-the-passw0rd',
    },
    expectStatus: HttpStatus.badRequest,
  );
  wrong.close();
  final register = _Capture(env);
  final registerMenu = await register.authorize(env['E2E_ACR_SSO']!);
  final registerForm = await register.chooseBranch(registerMenu, 'REGISTER');
  captured['ssoRegisterForm'] = registerForm;
  captured['ssoRegisterWeakPassword'] = await register
      .submit(registerForm, 'REGISTER', <String, Object?>{
        'email': 'flutter-fixture@example.invalid',
        'password': 'a',
        'givenName': 'Flutter',
        'familyName': 'Fixture',
      }, expectStatus: HttpStatus.badRequest);
  register.close();

  // Phase 6: polling, QR code, metadata, device registration. Each menu's first choice is a
  // `SUBMIT_BUTTON`, so it is submitted rather than chosen as a flow branch.
  final continuePolling = _Capture(env);
  final pollingMenu = await continuePolling.authorize(env['E2E_ACR_POLLING']!);
  captured['pollingMenu'] = pollingMenu;
  final pollingContinueForm = await continuePolling.submit(
    pollingMenu,
    'Continue Polling',
    <String, Object?>{},
  );
  captured['pollingContinueForm'] = pollingContinueForm;
  // What a finished simple poll submits: the collector's value, under its key, with the
  // `polling` event type and no `actionKey`.
  captured['pollingContinueSubmitted'] = await continuePolling.submit(
    pollingContinueForm,
    null,
    <String, Object?>{'polling-field': 'continue'},
    eventType: 'polling',
  );
  // The rewound form's "Finish" button ends the polling branch.
  captured['pollingDone'] = await continuePolling.submit(
    pollingContinueForm,
    'Finish',
    <String, Object?>{},
    eventType: 'action',
  );
  continuePolling.close();

  final challenge = _Capture(env);
  final challengeMenu = await challenge.authorize(env['E2E_ACR_POLLING']!);
  final challengeForm = await challenge.chooseBranch(
    challengeMenu,
    'Challenge Polling',
  );
  captured['pollingChallengeForm'] = challengeForm;
  // The challenge-status endpoint's answer while nobody has approved the challenge.
  captured['challengeStatusPending'] = await challenge.challengeStatus(
    challengeForm,
  );
  challenge.close();
  await branch(
    'E2E_ACR_POLLING',
    'Challenge Polling QRCode',
    'pollingQrCodeForm',
  );

  final metadata = _Capture(env);
  final metadataMenu = await metadata.authorize(env['E2E_ACR_METADATA_IMAGE']!);
  captured['metadataImageMenu'] = metadataMenu;
  final metadataForm = await metadata.submit(
    metadataMenu,
    'Metadata',
    <String, Object?>{},
  );
  captured['metadataForm'] = metadataForm;
  // What `MetadataCollector.setResult` submits: the result under the collector's key, which is
  // also the `actionKey`, with the `action` event type.
  captured['metadataSubmitted'] = await metadata.submit(
    metadataForm,
    'sdkMetadata',
    <String, Object?>{
      'sdkMetadata': <String, Object?>{'flutter': 'fixture'},
    },
    eventType: 'action',
  );
  metadata.close();
  await branch('E2E_ACR_METADATA_IMAGE', 'QRCode', 'qrCodeForm');

  final devices = _Capture(env);
  final devicesMenu = await devices.authorize(env['E2E_ACR_MFA_DEVICE']!);
  captured['mfaDeviceMenu'] = devicesMenu;
  final deviceRegistrationForm = await devices.submit(
    devicesMenu,
    'DEVICE_REGISTRATION',
    <String, Object?>{},
  );
  captured['deviceRegistrationForm'] = deviceRegistrationForm;
  // Choosing `EMAIL` asks for the address to enrol; nothing is created yet.
  captured['deviceRegistrationSubmitted'] = await devices.submit(
    deviceRegistrationForm,
    null,
    <String, Object?>{'device-registration': 'EMAIL'},
  );
  devices.close();
  // `DEVICE_AUTHENTICATION` needs a signed-in user, so an anonymous capture can't reach it.
  // Derived from the registration node instead: the field retyped, and each option given the
  // `id` and `default` an enrolled device carries (ping-android-sdk's `Device`).
  captured['deviceAuthenticationForm'] = _deviceAuthentication(
    deviceRegistrationForm,
  );

  // The challenge form's QR image encodes the magic link, `interactionId` included, which no text
  // scrub reaches. The QR branch's image (it encodes a public URL) stands in for it.
  _qrCodeField(captured['pollingQrCodeForm']!)['content'] = _qrCodeField(
    captured['qrCodeForm']!,
  )['content'];

  final output = File(
    'integration_test/support/davinci_captured_fixtures.dart',
  );
  output.writeAsStringSync(_render(captured, origin ?? capture.origin!));
  final jsonDir = Directory('integration_test/support/fixtures')
    ..createSync(recursive: true);
  captured.forEach((name, json) {
    File(
      '${jsonDir.path}/$name.json',
    ).writeAsStringSync('${_encode(json, origin ?? capture.origin!)}\n');
  });
  stdout.writeln(
    'Wrote ${captured.length} fixtures to ${output.path} and ${jsonDir.path}/',
  );
}

class _Capture {
  _Capture(this.env);

  final Map<String, String> env;
  final HttpClient _client = HttpClient();
  final Map<String, String> _cookies = <String, String>{};
  String? origin;

  Future<Map<String, Object?>> authorize(String acr) async {
    final discovery = await _send(
      'GET',
      Uri.parse(env['E2E_DISCOVERY_ENDPOINT']!),
    );
    final authorizationEndpoint = Uri.parse(
      discovery['authorization_endpoint']! as String,
    );
    origin = authorizationEndpoint.origin;
    final verifier = _randomUrlSafe(64);
    final uri = authorizationEndpoint.replace(
      queryParameters: <String, String>{
        'client_id': env['E2E_CLIENT_ID']!,
        'response_type': 'code',
        // `.env` lists scopes comma-separated; OAuth wants them space-separated.
        'scope': (env['E2E_SCOPES'] ?? 'openid')
            .split(RegExp(r'[ ,]+'))
            .join(' '),
        'redirect_uri': env['E2E_REDIRECT_URI']!,
        'code_challenge': base64Url
            .encode(await _sha256(utf8.encode(verifier)))
            .replaceAll('=', ''),
        'code_challenge_method': 'S256',
        'response_mode': 'pi.flow',
        'acr_values': acr,
      },
    );
    return _send('GET', uri);
  }

  /// Submits the menu's `FLOW_BUTTON`/`ACTION` whose key is [branch].
  Future<Map<String, Object?>> chooseBranch(
    Map<String, Object?> node,
    String branch,
  ) {
    final next = ((node['_links'] as Map)['next'] as Map)['href'] as String;
    return _send(
      'POST',
      Uri.parse(next),
      body: <String, Object?>{
        'id': node['id'],
        'eventName': 'continue',
        'parameters': <String, Object?>{
          'eventType': 'action',
          'data': <String, Object?>{
            'actionKey': branch,
            'formData': <String, Object?>{},
          },
        },
      },
    );
  }

  /// Submits [node]'s form with the button [actionKey] pressed (none when `null`) and [formData]
  /// filled in.
  Future<Map<String, Object?>> submit(
    Map<String, Object?> node,
    String? actionKey,
    Map<String, Object?> formData, {
    String eventType = 'submit',
    int expectStatus = HttpStatus.ok,
  }) {
    final next = ((node['_links'] as Map)['next'] as Map)['href'] as String;
    return _send(
      'POST',
      Uri.parse(next),
      body: <String, Object?>{
        'id': node['id'],
        'eventName': 'continue',
        'parameters': <String, Object?>{
          'eventType': eventType,
          'data': <String, Object?>{
            'actionKey': ?actionKey,
            'formData': formData,
          },
        },
      },
      expectStatus: expectStatus,
    );
  }

  /// POSTs [node]'s `POLLING` challenge to the status endpoint, as `PollingCollector` does in
  /// challenge mode: `{self.href before /davinci/connections}/davinci/user/credentials/challenge/
  /// {challenge}/status`, with the node's `interactionId` as a header.
  Future<Map<String, Object?>> challengeStatus(Map<String, Object?> node) {
    final fields =
        ((node['form']! as Map)['components']! as Map)['fields']! as List;
    final polling = fields.cast<Map>().firstWhere(
      (field) => field['type'] == 'POLLING',
    );
    final self = ((node['_links'] as Map)['self'] as Map)['href'] as String;
    final base = self.substring(0, self.indexOf('/davinci/connections'));
    return _send(
      'POST',
      Uri.parse(
        '$base/davinci/user/credentials/challenge/${polling['challenge']}/status',
      ),
      headers: <String, String>{
        'interactionId': node['interactionId']! as String,
      },
    );
  }

  Future<Map<String, Object?>> _send(
    String method,
    Uri uri, {
    Object? body,
    Map<String, String> headers = const <String, String>{},
    int expectStatus = HttpStatus.ok,
  }) async {
    final request = await _client.openUrl(method, uri);
    request.headers
      ..set('accept', 'application/json')
      ..set('x-requested-with', 'ping-sdk')
      ..set('x-requested-platform', 'android');
    headers.forEach(request.headers.set);
    if (_cookies.isNotEmpty) {
      request.headers.set(
        'cookie',
        _cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
      );
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    for (final cookie in response.cookies) {
      _cookies[cookie.name] = cookie.value;
    }
    final text = await utf8.decoder.bind(response).join();
    if (response.statusCode != expectStatus) {
      throw HttpException('$method $uri -> ${response.statusCode}: $text');
    }
    return (jsonDecode(text) as Map).cast<String, Object?>();
  }

  void close() => _client.close(force: true);
}

Map<Object?, Object?> _qrCodeField(Map<String, Object?> node) =>
    (((node['form']! as Map)['components']! as Map)['fields']! as List)
        .cast<Map<Object?, Object?>>()
        .firstWhere((field) => field['type'] == 'QR_CODE');

Map<String, Object?> _deviceAuthentication(Map<String, Object?> registration) {
  final node = (jsonDecode(jsonEncode(registration)) as Map)
      .cast<String, Object?>();
  final fields =
      ((node['form']! as Map)['components']! as Map)['fields']! as List;
  final field = fields.cast<Map>().firstWhere(
    (field) => field['type'] == 'DEVICE_REGISTRATION',
  );
  field
    ..['type'] = 'DEVICE_AUTHENTICATION'
    ..['key'] = 'device-authentication'
    ..['label'] = 'MFA Device Selection - Authentication';
  final options = (field['options']! as List).cast<Map>();
  for (final (i, option) in options.indexed) {
    option
      ..['id'] = 'fixture-device-${i + 1}'
      ..['default'] = i == 0;
  }
  return node;
}

Map<String, String> _readEnv(File file) => <String, String>{
  for (final line in file.readAsLinesSync())
    if (line.contains('=') && !line.trimLeft().startsWith('#'))
      line.substring(0, line.indexOf('=')).trim(): line
          .substring(line.indexOf('=') + 1)
          .trim(),
};

const _scrubbedKeys = <String>{'interactionId', 'interactionToken'};

Object? _scrub(Object? value) => switch (value) {
  Map() => <String, Object?>{
    for (final entry in value.entries)
      '${entry.key}': _scrubbedKeys.contains(entry.key)
          ? 'scrubbed'
          : _scrub(entry.value),
  },
  List() => value.map(_scrub).toList(),
  _ => value,
};

String _render(Map<String, Map<String, Object?>> fixtures, String origin) {
  final buffer = StringBuffer()
    ..writeln('/*')
    ..writeln(
      ' * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.',
    )
    ..writeln(' *')
    ..writeln(
      ' * This software may be modified and distributed under the terms',
    )
    ..writeln(' * of the MIT license. See the LICENSE file for details.')
    ..writeln(' */')
    ..writeln()
    ..writeln(
      '// GENERATED by capture_fixtures.dart from the live DaVinci test tenant. Do not edit by',
    )
    ..writeln(
      '// hand; re-run the script instead. `{{baseUrl}}` stands for the tenant origin.',
    )
    ..writeln();
  fixtures.forEach((name, json) {
    final text = _encode(json, origin);
    buffer
      ..writeln('/// Captured `$name` node.')
      ..writeln("const $name = r'''")
      ..writeln(text)
      ..writeln("''';")
      ..writeln();
  });
  return buffer.toString();
}

/// The values of the scrubbed keys anywhere in [value]. Some nodes repeat them inside other
/// strings: the challenge-polling label's magic link carries the `interactionId`.
Iterable<String> _scrubbedValues(Object? value) sync* {
  switch (value) {
    case Map():
      for (final MapEntry(:key, value: element) in value.entries) {
        if (_scrubbedKeys.contains(key) && element is String) {
          yield element;
        } else {
          yield* _scrubbedValues(element);
        }
      }
    case List():
      for (final element in value) {
        yield* _scrubbedValues(element);
      }
  }
}

String _encode(Map<String, Object?> json, String origin) {
  var text = const JsonEncoder.withIndent(
    '  ',
  ).convert(_scrub(json)).replaceAll(origin, '{{baseUrl}}');
  // Ids only: a short value (some nodes send `deprecated`) would also match unrelated text.
  for (final secret in _scrubbedValues(json).where((v) => v.length >= 16)) {
    text = text.replaceAll(secret, 'scrubbed');
  }
  return text;
}

String _randomUrlSafe(int length) {
  final random = Random.secure();
  return base64Url
      .encode(List<int>.generate(length, (_) => random.nextInt(256)))
      .replaceAll('=', '')
      .substring(0, length);
}

/// SHA-256 via the host's `shasum`, so the script needs no package dependency.
Future<List<int>> _sha256(List<int> bytes) async {
  final process = await Process.start('shasum', <String>['-a', '256']);
  process.stdin.add(bytes);
  await process.stdin.close();
  final hex = (await utf8.decoder.bind(process.stdout).join()).split(' ').first;
  return <int>[
    for (var i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ];
}
