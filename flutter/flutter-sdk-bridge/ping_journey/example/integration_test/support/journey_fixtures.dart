/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// PingAM `/json/realms/{realm}/authenticate` response bodies, shaped the way a real server shapes
/// them, for use with [MockAmServer].
///
/// The shapes here are not invented — they follow what the native SDKs actually parse:
///
/// * A response containing `authId` is a continue node; one without it is a success node. The
///   presence of `authId` is the *only* discriminator, on both platforms.
/// * Every callback carries an `output` array of `{name, value}` pairs (what the server tells the
///   client) and an `input` array (what the client fills in and sends back). The `input` entry
///   **names matter**: the native `AbstractCallback.input(...)` helper copies the names out of the
///   original `input` array positionally, so a fixture that omits `input` produces a payload with
///   empty names and the server-side assertions in these tests will not match.
/// * `failedPolicies` is an array of **JSON-encoded strings**, not an array of objects — the native
///   SDKs call `parseToJsonElement` on each element. Fixtures that use it deliberately keep it
///   non-empty, because Pigeon's generated decoder does an unchecked cast on nested collection
///   element types that only throws once a real map element arrives over the wire.
/// * `TextOutputCallback.messageType` is the numeric AM code (`0` information, `1` warning,
///   `2` error, `4` script), sent as a string.
/// * `header`, `description`, and `stage` are top-level fields on the response, not callbacks — the
///   native `ContinueNode` extensions read them straight off the response JSON.
abstract final class JourneyFixtures {
  /// A stand-in for AM's opaque `authId` continuation token. Its contents are never interpreted by
  /// the SDK — it is echoed back verbatim on the next request — so a readable placeholder is fine.
  static const authId = 'mock-auth-id-token';

  /// The classic login page: a `NameCallback` for the username and a `PasswordCallback`.
  static Map<String, Object?> usernamePasswordNode({
    String header = 'Sign In',
    String description = 'Enter your credentials',
    String? stage,
  }) => continueNode(
    header: header,
    description: description,
    stage: stage,
    callbacks: <Map<String, Object?>>[
      callback(
        'NameCallback',
        id: 0,
        output: <String, Object?>{'prompt': 'User Name'},
        input: <String, Object?>{'IDToken1': ''},
      ),
      callback(
        'PasswordCallback',
        id: 1,
        output: <String, Object?>{'prompt': 'Password'},
        input: <String, Object?>{'IDToken2': ''},
      ),
    ],
  );

  /// A single page exercising every callback type the v1 bridge maps, so one round-trip covers the
  /// whole mapping surface. Deliberately unrealistic as a Journey — realism here would cost coverage.
  static Map<String, Object?> allCallbackTypesNode() => continueNode(
    header: 'Everything',
    description: 'One page per mapped callback type',
    stage: 'MappingCoverage',
    callbacks: <Map<String, Object?>>[
      callback(
        'NameCallback',
        id: 0,
        output: <String, Object?>{'prompt': 'User Name'},
        input: <String, Object?>{'IDToken1': ''},
      ),
      callback(
        'PasswordCallback',
        id: 1,
        output: <String, Object?>{'prompt': 'Password'},
        input: <String, Object?>{'IDToken2': ''},
      ),
      callback(
        'ValidatedCreateUsernameCallback',
        id: 2,
        output: <String, Object?>{
          'policies': usernamePolicies,
          'failedPolicies': <Object?>[],
          'validateOnly': false,
          'prompt': 'Username',
        },
        input: <String, Object?>{'IDToken3': '', 'IDToken3validateOnly': false},
      ),
      callback(
        'ValidatedCreatePasswordCallback',
        id: 3,
        output: <String, Object?>{
          'echoOn': false,
          'policies': passwordPolicies,
          // Non-empty on purpose: this is the element shape that trips an unchecked cast if the
          // Dart side ever stops doing an elementwise cast on `failedPolicies`.
          'failedPolicies': <Object?>[lengthPolicyFailure],
          'validateOnly': false,
          'prompt': 'Password',
        },
        input: <String, Object?>{'IDToken4': '', 'IDToken4validateOnly': false},
      ),
      callback(
        'ChoiceCallback',
        id: 4,
        output: <String, Object?>{
          'prompt': 'Second factor',
          'choices': <Object?>['Email', 'SMS', 'Authenticator'],
          'defaultChoice': 1,
        },
        input: <String, Object?>{'IDToken5': 1},
      ),
      callback(
        'KbaCreateCallback',
        id: 5,
        output: <String, Object?>{
          'prompt': 'Select a security question',
          'predefinedQuestions': <Object?>[
            "What's your favorite colour?",
            'Who was your first employer?',
          ],
          'allowUserDefinedQuestions': false,
        },
        input: <String, Object?>{
          'IDToken6question': '',
          'IDToken6answer': '',
        },
      ),
      callback(
        'TermsAndConditionsCallback',
        id: 6,
        output: <String, Object?>{
          'version': '0.0',
          'terms': 'Be excellent to each other.',
          'createDate': '2026-01-15T00:00:00.000Z',
        },
        input: <String, Object?>{'IDToken7': false},
      ),
      callback(
        'TextInputCallback',
        id: 7,
        output: <String, Object?>{
          'prompt': 'Nickname',
          'defaultText': 'anonymous',
        },
        input: <String, Object?>{'IDToken8': ''},
      ),
      // Output-only: contributes no value on next(), so it has no `input` array at all.
      callback(
        'TextOutputCallback',
        id: 8,
        output: <String, Object?>{
          'message': 'Your session will expire soon.',
          'messageType': '1',
        },
      ),
      callback(
        'StringAttributeInputCallback',
        id: 9,
        output: <String, Object?>{
          'name': 'givenName',
          'prompt': 'First Name',
          'required': true,
          'policies': attributePolicies('givenName'),
          'failedPolicies': <Object?>[requiredPolicyFailure],
          'validateOnly': false,
          'value': '',
        },
        input: <String, Object?>{
          'IDToken10': '',
          'IDToken10validateOnly': false,
        },
      ),
      callback(
        'NumberAttributeInputCallback',
        id: 10,
        output: <String, Object?>{
          'name': 'age',
          'prompt': 'Age',
          'required': false,
          'policies': attributePolicies('age'),
          'failedPolicies': <Object?>[],
          'validateOnly': false,
          'value': 21,
        },
        input: <String, Object?>{
          'IDToken11': 21,
          'IDToken11validateOnly': false,
        },
      ),
      callback(
        'BooleanAttributeInputCallback',
        id: 11,
        output: <String, Object?>{
          'name': 'preferences/marketing',
          'prompt': 'Send me marketing email',
          'required': false,
          'policies': attributePolicies('preferences/marketing'),
          'failedPolicies': <Object?>[],
          'validateOnly': false,
          'value': false,
        },
        input: <String, Object?>{
          'IDToken12': false,
          'IDToken12validateOnly': false,
        },
      ),
    ],
  );

  /// A terminal success response. `tokenId` is the SSO session token the native SDK persists and
  /// replays as the `iPlanetDirectoryPro` header on subsequent requests.
  static Map<String, Object?> success({
    String tokenId = 'mock-sso-token',
    String realm = '/',
  }) => <String, Object?>{
    'tokenId': tokenId,
    'successUrl': '/am/console',
    'realm': realm,
  };

  /// AM's authentication-failure body. Returned with HTTP 401, this maps to an `ErrorNode` on both
  /// platforms — recoverable, so the caller can re-collect credentials and start over.
  static Map<String, Object?> authenticationFailed({
    String message = 'Authentication Failed',
  }) => <String, Object?>{
    'code': 401,
    'reason': 'Unauthorized',
    'message': message,
    'detail': <String, Object?>{'failureUrl': ''},
  };

  /// Assembles a continue-node response. Only `authId` and `callbacks` are load-bearing; the rest is
  /// page metadata the bridge surfaces on [ContinueNode].
  static Map<String, Object?> continueNode({
    required List<Map<String, Object?>> callbacks,
    String? header,
    String? description,
    String? stage,
  }) => <String, Object?>{
    'authId': authId,
    'header': ?header,
    'description': ?description,
    'stage': ?stage,
    'callbacks': callbacks,
  };

  /// Builds one callback entry, converting the friendlier map form of [output]/[input] into AM's
  /// array-of-`{name, value}` wire form.
  static Map<String, Object?> callback(
    String type, {
    required int id,
    Map<String, Object?> output = const <String, Object?>{},
    Map<String, Object?>? input,
  }) => <String, Object?>{
    'type': type,
    'output': <Object?>[
      for (final entry in output.entries)
        <String, Object?>{'name': entry.key, 'value': entry.value},
    ],
    if (input != null)
      'input': <Object?>[
        for (final entry in input.entries)
          <String, Object?>{'name': entry.key, 'value': entry.value},
      ],
    '_id': id,
  };

  /// A `policyRequirement` failure string, in the JSON-encoded-string form AM uses.
  static const lengthPolicyFailure =
      '{ "policyRequirement": "LENGTH_BASED", "params": '
      '{ "max-password-length": 0, "min-password-length": 8 } }';

  /// A required-attribute failure string, in the JSON-encoded-string form AM uses.
  static const requiredPolicyFailure =
      '{ "policyRequirement": "REQUIRED", "params": {} }';

  /// Server-side username policy metadata, as AM reports it on a validated username callback.
  static const usernamePolicies = <String, Object?>{
    'name': 'userName',
    'policyRequirements': <Object?>['REQUIRED', 'VALID_TYPE', 'UNIQUE'],
  };

  /// Server-side password policy metadata, as AM reports it on a validated password callback.
  static const passwordPolicies = <String, Object?>{
    'name': 'password',
    'policyRequirements': <Object?>['LENGTH_BASED', 'CANNOT_CONTAIN_OTHERS'],
  };

  /// Server-side policy metadata for the identity attribute [name].
  static Map<String, Object?> attributePolicies(String name) =>
      <String, Object?>{
        'name': name,
        'policyRequirements': <Object?>['REQUIRED', 'VALID_TYPE'],
      };
}
