# ping_journey integration-test host

This is not a sample app. If you are looking for one, see [`flutter-journey`](../../../flutter-journey).

The `integration_test` package can only run from a Flutter *application*, and `ping_journey` is a
plugin. This app exists solely to give the plugin's integration tests a process to run in. Its
`lib/main.dart` is a deliberately empty screen — the tests drive `JourneyClient` directly and never
pump a widget tree.

## Running the tests

Hermetically, against an in-process mock AM server. No tenant, no configuration, no network:

```sh
cd flutter-sdk-bridge/ping_journey/example
flutter test integration_test/
```

This is what CI runs. A device or emulator must be attached, because the tests exercise the native
SDK through the platform channel.

Against a real PingAM or PingOne Advanced Identity Cloud tenant:

```sh
flutter test integration_test/ \
  --dart-define=E2E_SERVER_URL=https://openam.example.com/openam \
  --dart-define=E2E_USERNAME=testuser \
  --dart-define=E2E_PASSWORD="$AM_PASSWORD"
```

Adding `E2E_CLIENT_ID`, `E2E_DISCOVERY_ENDPOINT`, and `E2E_REDIRECT_URI` additionally enables the
token-exchange scenario. `E2E_REALM`, `E2E_JOURNEY`, `E2E_COOKIE`, and `E2E_SCOPES` override the
defaults (`root`, `Login`, `iPlanetDirectoryPro`, and `openid profile email`).

Credentials are read through `String.fromEnvironment`, so they live in your shell or your CI secret
store and are never written to a file in this repository. Do not add a config file with real values —
this repo is public. The native SDKs make the same choice: the Android SDK fills
`assets/test_config.properties` from a CI secret, and the iOS SDK commits a `Config.json` containing
placeholders only.

## What runs in which mode

| Scenario | Hermetic | Live |
| --- | --- | --- |
| `journey_login_test.dart` | yes | yes |
| `journey_oidc_session_test.dart` | yes | yes, with an OAuth 2.0 client |
| `journey_sign_off_test.dart` | yes | yes |
| `journey_failure_node_test.dart` | yes | yes |
| `journey_callback_mapping_test.dart` | yes | skipped |
| `journey_error_node_test.dart` | yes | skipped |

The two hermetic-only scenarios need a response a real tenant will not produce on request: twelve
unrelated callbacks on a single page, and a specific authentication-failure body. They skip themselves
with an explanation rather than assert a shape that happens to match one tenant's configuration.

`journey_failure_node_test.dart` runs in both modes because it needs neither — it points the SDK at a
loopback port nobody is listening on.

## Why one scenario per file

The native SDK persists the AM session cookie in platform secure storage, and it survives across
`JourneyClient` instances within a single app install. Two login scenarios in one file would therefore
influence each other: the second would find the first one's session and could skip authentication
entirely. `flutter test integration_test/` runs each file in its own process, so one scenario per file
keeps them independent.

Storage outlives the process, though, not just the test. `journey_sign_off_test.dart` deletes the
stored token as part of what it asserts; the others leave it behind. If a scenario ever fails in a way
that looks like "it was already logged in", uninstall the app from the device and run again.

## The mock server

`integration_test/support/mock_am_server.dart` is an in-process `HttpServer` that speaks enough of
AM's `/json/realms/{realm}/authenticate` protocol and the OIDC endpoints to drive the SDK. Because it
runs inside the test process *on the device*, `127.0.0.1` is correct on both the Android emulator and
the iOS simulator — there is no `10.0.2.2` special case. Two platform permissions make that work, and
both are scoped as narrowly as possible: an Android network security config that permits cleartext for
loopback only, placed in `src/debug/` so it cannot reach a release build, and `NSAllowsLocalNetworking`
in the iOS `Info.plist`.

Scenarios script the `/authenticate` responses in order and then assert on what the SDK actually sent —
query parameters, headers, and the `IDTokenN` values in the submitted payload. When a node assertion
fails, the harness attaches the full request log to the failure message, because "expected
SuccessNode, got ContinueNode" is rarely enough to tell you why.

`integration_test/support/journey_fixtures.dart` holds the response bodies. Its doc comment records
the wire details that are easy to get wrong — chiefly that `failedPolicies` is an array of
JSON-*encoded strings*, and that a callback's `input` array names are load-bearing because the native
SDK copies them positionally into the payload it submits.
