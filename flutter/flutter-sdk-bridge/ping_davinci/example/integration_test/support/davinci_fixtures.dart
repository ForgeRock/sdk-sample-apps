/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:convert';
import 'dart:io';

import 'package:ping_davinci/ping_davinci.dart';

import 'davinci_captured_fixtures.dart' as captured;
import 'mock_davinci_server.dart';

/// A valid hoisted-fields config. Building a DaVinci workflow never touches the network, so the
/// endpoint is never contacted; it only has to be well-formed.
DaVinciConfigMessage validConfig() => DaVinciConfigMessage()
  ..clientId = 'integration-test-client'
  ..redirectUri = 'pingdavinciexample://callback'
  ..discoveryEndpoint = 'http://127.0.0.1:9/as/.well-known/openid-configuration'
  ..scopes = <String?>['openid'];

/// Node bodies for `MockDaVinciServer`, captured from the live test tenant by
/// `capture_fixtures.dart`. Captured links point at `{{baseUrl}}`, replaced here with the mock's.
abstract final class DaVinciFixtures {
  /// The form-fields flow's first node: a menu whose `SUBMIT_BUTTON`/`FLOW_BUTTON` keys name the
  /// sub-flows (`Form Fields`, `Form Validation`, `Agreement Test`, `Error Node`).
  static Map<String, Object?> formFieldsMenu(String baseUrl) =>
      _node(captured.formFieldsMenu, baseUrl);

  /// The `Form Fields` branch: every core field collector, in one form.
  static Map<String, Object?> formFieldsForm(String baseUrl) =>
      _node(captured.formFieldsForm, baseUrl);

  /// The menu key that leads to [formFieldsForm].
  static const formFieldsBranch = 'Form Fields';

  /// The menu key that leads to [agreementForm], through a `FLOW_BUTTON`.
  static const agreementBranch = 'Agreement Test';

  /// The menu key that leads to [formValidationForm], through a `FLOW_BUTTON`.
  static const formValidationBranch = 'Form Validation';

  /// The `Form Validation` branch: a `LABEL`, required `TEXT` username and email with regexes
  /// (`^[a-zA-Z0-9]+$`, `^[^@]+@[^@]+\.[^@]+$`), a required `PASSWORD_VERIFY` whose policy is the
  /// node's (length 8–255, 5 unique, at most 2 repeats, one of each of four character sets), and
  /// a submit button.
  static Map<String, Object?> formValidationForm(String baseUrl) =>
      _node(captured.formValidationForm, baseUrl);

  /// What the tenant answers a valid [formFieldsForm] submit with: a "Success" form whose only
  /// field is a `CONTINUE` submit button.
  static Map<String, Object?> formFieldsSubmitted(String baseUrl) =>
      _node(captured.formFieldsSubmitted, baseUrl);

  /// The `Agreement Test` branch: `AGREEMENT`/`READ_ONLY_TEXT`, a key-less `ERROR_DISPLAY`, a
  /// `SINGLE_CHECKBOX`/`BOOLEAN`, and a submit button.
  static Map<String, Object?> agreementForm(String baseUrl) =>
      _node(captured.agreementForm, baseUrl);

  /// The SSO flow's first node: `TEXT` username, `PASSWORD`, the `SIGNON` submit button, and the
  /// `REGISTER`/`TROUBLE` flow buttons.
  static Map<String, Object?> ssoMenu(String baseUrl) =>
      _node(captured.ssoMenu, baseUrl);

  /// The submit key of [ssoMenu]'s sign-on button.
  static const signOnButton = 'SIGNON';

  /// The key of [ssoMenu]'s `FLOW_BUTTON` that leads to [ssoRegisterForm].
  static const registerBranch = 'REGISTER';

  /// The SSO flow's registration form: `TEXT` email, `PASSWORD`, `TEXT` given and family name,
  /// the `REGISTER` submit button, and a `CANCEL` flow button. No password policy.
  static Map<String, Object?> ssoRegisterForm(String baseUrl) =>
      _node(captured.ssoRegisterForm, baseUrl);

  /// The submit key of [ssoRegisterForm]'s button.
  static const registerButton = 'REGISTER';

  /// What the tenant answers [ssoRegisterForm] with when the password fails the policy: a `400`
  /// from `createUser`, whose `details` name `target: "password"` with an `innerError` per unmet
  /// requirement. No user is created.
  static MockResponse ssoRegisterWeakPassword() => MockResponse(
    HttpStatus.badRequest,
    _node(captured.ssoRegisterWeakPassword, ''),
  );

  /// What the tenant answers [ssoMenu]'s sign-on with for a user that doesn't exist: a `400`
  /// from `userLookup`, whose only detail is the user search's result. It names no field.
  static MockResponse ssoWrongPassword() =>
      MockResponse(HttpStatus.badRequest, _node(captured.ssoWrongPassword, ''));

  /// A DaVinci polling timeout, the one `4xx` the two native SDKs route differently: iOS's
  /// `Transform.swift` treats `code: "timedOut"` as a `FailureNode`, Android's `Transform.kt` as
  /// a recoverable `ErrorNode`. Hand-written: no tenant times out on request, and the rule only
  /// reads `code`.
  static MockResponse pollingTimedOut() =>
      const MockResponse(HttpStatus.badRequest, <String, Object?>{
        'code': 'timedOut',
        'message': 'Polling timed out',
        'httpResponseCode': 400,
      });

  /// A completed sign-on: `authorizeResponse.code`, which the SDK turns into a `SuccessNode` and
  /// exchanges at the token endpoint. Not captured — an anonymous capture can't sign in — but
  /// copied from the response ping-android-sdk's own `DaVinciTest` records for the same step
  /// (`DaVinciTest.Response.kt`, `customHTMLTemplate()`), ids replaced.
  static Map<String, Object?> signOnSuccess() => <String, Object?>{
    'interactionId': 'scrubbed',
    'companyId': '300c4f2a-39d4-4ba9-a18a-f6de246006f4',
    'connectionId': '26146c8065741406afb0899484e361a7',
    'connectorId': 'pingOneAuthenticationConnector',
    'id': '5dtrjnrwox',
    'capabilityName': 'returnSuccessResponseRedirect',
    'environment': <String, Object?>{
      'id': '300c4f2a-39d4-4ba9-a18a-f6de246006f4',
    },
    'session': <String, Object?>{'id': 'mock-session'},
    'status': 'COMPLETED',
    'authorizeResponse': <String, Object?>{'code': 'mock-authorization-code'},
    'success': true,
    'interactionToken': 'scrubbed',
  };

  /// A field no native collector is registered for, on either platform. The one hand-written
  /// field in the suite: no real tenant emits one on request.
  static const unregisteredField = <String, Object?>{
    'type': 'TEXT',
    'inputType': 'FUTURE_FIELD',
    'key': 'future-field',
    'label': 'A field from a newer server',
  };

  /// All 17 core collector keys in one form, composed from captured fields: [formFieldsForm]'s
  /// thirteen (`LABEL` ×3, `TEXT`, `CHECKBOX`, `DROPDOWN`, `RADIO`, `COMBOBOX`, `PHONE_NUMBER`,
  /// `SINGLE_CHECKBOX`, `FLOW_BUTTON`, `FLOW_LINK`, `SUBMIT_BUTTON`), the SSO form's `TEXT` username
  /// and `PASSWORD`, the validation form's regex-validated `TEXT` email and policy-bearing
  /// `PASSWORD_VERIFY`, the agreement form's `AGREEMENT` and key-less `ERROR_DISPLAY`, the image
  /// form's `IMAGE`, the QR form's `QR_CODE`, the simple-polling form's `POLLING`, the device
  /// forms' `DEVICE_REGISTRATION` and `DEVICE_AUTHENTICATION`, the metadata form's `METADATA`, and
  /// [unregisteredField]. The submit button stays last. The node's own id, links and `formData`
  /// defaults are [formFieldsForm]'s.
  static Map<String, Object?> collectorSweep(String baseUrl) {
    List<Map<String, Object?>> fields(String json) =>
        ((((_node(json, baseUrl)['form']! as Map)['components']!
                        as Map)['fields']!
                    as List)
                .cast<Map<Object?, Object?>>())
            .map((field) => field.cast<String, Object?>())
            .toList();
    Map<String, Object?> withKey(List<Map<String, Object?>> from, String key) =>
        from.firstWhere((field) => field['key'] == key);

    final base = fields(captured.formFieldsForm);
    final sso = fields(captured.ssoMenu);
    final validation = fields(captured.formValidationForm);
    final agreement = fields(captured.agreementForm);
    final image = fields(captured.imageForm);
    Map<String, Object?> only(String json, String type) =>
        fields(json).firstWhere((field) => field['type'] == type);
    final node = _node(captured.formFieldsForm, baseUrl);
    ((node['form']! as Map)['components']! as Map)['fields'] = <Object?>[
      ...base.take(base.length - 1),
      withKey(sso, 'username'),
      withKey(sso, 'password'),
      withKey(validation, 'user.email'),
      withKey(validation, 'user.password'),
      withKey(agreement, 'agreement'),
      agreement.firstWhere((field) => field['type'] == 'ERROR_DISPLAY'),
      withKey(image, 'image'),
      only(captured.qrCodeForm, 'QR_CODE'),
      only(captured.pollingContinueForm, 'POLLING'),
      only(captured.deviceRegistrationForm, 'DEVICE_REGISTRATION'),
      only(captured.deviceAuthenticationForm, 'DEVICE_AUTHENTICATION'),
      only(captured.metadataForm, 'METADATA'),
      unregisteredField,
      base.last,
    ];
    return node;
  }

  /// The polling flow's first node: a menu whose `Continue Polling` (`SUBMIT_BUTTON`),
  /// `Challenge Polling` and `Challenge Polling QRCode` (`FLOW_BUTTON`s) keys name the branches.
  static Map<String, Object?> pollingMenu(String baseUrl) =>
      _node(captured.pollingMenu, baseUrl);

  /// The menu key that leads to [pollingContinueForm], through a `SUBMIT_BUTTON`.
  static const continuePollingBranch = 'Continue Polling';

  /// The menu key that leads to [pollingChallengeForm], through a `FLOW_BUTTON`.
  static const challengePollingBranch = 'Challenge Polling';

  /// The menu key that leads to [pollingQrCodeForm], through a `FLOW_BUTTON`.
  static const challengePollingQrCodeBranch = 'Challenge Polling QRCode';

  /// The `Continue Polling` branch: two `LABEL`s, an `ERROR_DISPLAY`, a simple-mode `POLLING`
  /// (`polling-field`, 2000 ms, 3 retries), and a `Finish` flow button.
  static Map<String, Object?> pollingContinueForm(String baseUrl) =>
      _node(captured.pollingContinueForm, baseUrl);

  /// What the tenant answers a simple poll's `continue` with: `rewindStateToLastRenderedUI`, which
  /// both SDKs turn back into the previous form, with its retries carried over.
  static Map<String, Object?> pollingContinueSubmitted(String baseUrl) =>
      _node(captured.pollingContinueSubmitted, baseUrl);

  /// The key of [pollingContinueForm]'s flow button that ends the branch.
  static const finishButton = 'Finish';

  /// What the tenant answers [finishButton] with: a "Message: Done" label.
  static Map<String, Object?> pollingDone(String baseUrl) =>
      _node(captured.pollingDone, baseUrl);

  /// The `Challenge Polling` branch: [pollingContinueForm]'s fields, the `POLLING` in challenge
  /// mode, with the node's `_links.self` and `interactionId` the status endpoint needs.
  static Map<String, Object?> pollingChallengeForm(String baseUrl) =>
      _node(captured.pollingChallengeForm, baseUrl);

  /// The `Challenge Polling QRCode` branch: `LABEL` ×2, an `ERROR_DISPLAY`, a `QR_CODE`, a
  /// challenge-mode `POLLING`, a `FLOW_LINK`, and a `PROTECT` (an add-on field).
  static Map<String, Object?> pollingQrCodeForm(String baseUrl) =>
      _node(captured.pollingQrCodeForm, baseUrl);

  /// [node] with its `POLLING` field's interval and retries replaced, so a hermetic poll is quick.
  static Map<String, Object?> withPolling(
    Map<String, Object?> node, {
    required int intervalMillis,
    required int retries,
  }) {
    final fields =
        ((node['form']! as Map)['components']! as Map)['fields']! as List;
    fields.cast<Map<Object?, Object?>>().firstWhere(
        (field) => field['type'] == 'POLLING',
      )
      ..['pollInterval'] = '$intervalMillis'
      ..['pollRetries'] = '$retries';
    return node;
  }

  /// The challenge-status endpoint's answer while the challenge is pending, as captured, or once
  /// it has completed with [status].
  static Map<String, Object?> challengeStatus({String? completedWith}) {
    final body = _node(captured.challengeStatusPending, '');
    if (completedWith != null) {
      body
        ..['isChallengeComplete'] = true
        ..['status'] = completedWith;
    }
    return body;
  }

  /// The metadata / image / QR code flow's first node: a menu whose `Metadata`
  /// (`SUBMIT_BUTTON`), `Image` and `QRCode` (`FLOW_BUTTON`s) keys name the branches.
  static Map<String, Object?> metadataImageMenu(String baseUrl) =>
      _node(captured.metadataImageMenu, baseUrl);

  /// The [metadataImageMenu] key that leads to [metadataForm], through a `SUBMIT_BUTTON`.
  static const metadataBranch = 'Metadata';

  /// The [metadataImageMenu] key that leads to [qrCodeForm], through a `FLOW_BUTTON`.
  static const qrCodeBranch = 'QRCode';

  /// The `Metadata` branch: a lone `METADATA` field (`sdkMetadata`) with the payload
  /// `{"testkey": "testValue"}`.
  static Map<String, Object?> metadataForm(String baseUrl) =>
      _node(captured.metadataForm, baseUrl);

  /// What the tenant answers a metadata result with: an `ERROR_DISPLAY`, a `LABEL` and a submit
  /// button.
  static Map<String, Object?> metadataSubmitted(String baseUrl) =>
      _node(captured.metadataSubmitted, baseUrl);

  /// The `QRCode` branch: a `LABEL`, an `ERROR_DISPLAY`, a `QR_CODE` (`qr-code`) with a
  /// `fallbackText`, and a submit button.
  static Map<String, Object?> qrCodeForm(String baseUrl) =>
      _node(captured.qrCodeForm, baseUrl);

  /// The QR code's data URI in [qrCodeForm], as the server sent it.
  static String qrCodeContent() =>
      (((((_node(captured.qrCodeForm, '')['form']! as Map)['components']!
                          as Map)['fields']!
                      as List)
                  .cast<Map<Object?, Object?>>())
              .firstWhere((field) => field['type'] == 'QR_CODE')['content'])!
          as String;

  /// The MFA device flow's first node: a menu whose `DEVICE_REGISTRATION` (`SUBMIT_BUTTON`),
  /// `DEVICE_AUTHENTICATION` and `USER_*` (`FLOW_BUTTON`s) keys name the branches.
  static Map<String, Object?> mfaDeviceMenu(String baseUrl) =>
      _node(captured.mfaDeviceMenu, baseUrl);

  /// The [mfaDeviceMenu] key that leads to [deviceRegistrationForm], through a `SUBMIT_BUTTON`.
  static const deviceRegistrationBranch = 'DEVICE_REGISTRATION';

  /// The `DEVICE_REGISTRATION` branch: an `ERROR_DISPLAY` and a required `DEVICE_REGISTRATION`
  /// (`device-registration`) offering `EMAIL`, `SMS` and `VOICE`. No button: choosing a device
  /// submits.
  static Map<String, Object?> deviceRegistrationForm(String baseUrl) =>
      _node(captured.deviceRegistrationForm, baseUrl);

  /// What the tenant answers an `EMAIL` registration with: an "Enter Email" form.
  static Map<String, Object?> deviceRegistrationSubmitted(String baseUrl) =>
      _node(captured.deviceRegistrationSubmitted, baseUrl);

  /// [deviceRegistrationForm] with the field retyped `DEVICE_AUTHENTICATION`
  /// (`device-authentication`) and its devices given ids `fixture-device-1`…`3`, the first the
  /// default: derived by `capture_fixtures.dart`, since only a signed-in user reaches the real one.
  static Map<String, Object?> deviceAuthenticationForm(String baseUrl) =>
      _node(captured.deviceAuthenticationForm, baseUrl);

  static Map<String, Object?> _node(String json, String baseUrl) =>
      (jsonDecode(json.replaceAll('{{baseUrl}}', baseUrl)) as Map)
          .cast<String, Object?>();
}

/// The 17 collector keys the native `davinci` module registers on both platforms at 2.2.0:
/// Android's `CollectorRegistry.kt`, and the canonical half of iOS's `DaVinci.swift` table.
const coreCollectorTypes = <String>{
  'TEXT',
  'PASSWORD',
  'PASSWORD_VERIFY',
  'SUBMIT_BUTTON',
  'ACTION',
  'LABEL',
  'SINGLE_SELECT',
  'MULTI_SELECT',
  'BOOLEAN',
  'DEVICE_REGISTRATION',
  'DEVICE_AUTHENTICATION',
  'PHONE_NUMBER',
  'READ_ONLY_TEXT',
  'POLLING',
  'QR_CODE',
  'IMAGE',
  'METADATA',
};

/// The six alias keys only iOS registers. Real payloads carry a canonical `inputType`, which both
/// factories resolve first, so these never decide which collector Android builds.
const iosAliasCollectorTypes = <String>{
  'FLOW_BUTTON',
  'FLOW_LINK',
  'DROPDOWN',
  'RADIO',
  'COMBOBOX',
  'CHECKBOX',
};
