# ping_davinci integration-test host

This is not a sample app. The DaVinci sample will be `flutter-davinci` (not written yet); until then,
[`flutter-journey`](../../../flutter-journey) shows how a sample uses a bridge module.

The `integration_test` package can only run from a Flutter *application*, and `ping_davinci` is a
plugin. This app exists solely to give the plugin's integration tests a process to run in. Its
`lib/main.dart` is a deliberately empty screen — the tests drive the module's Dart API directly and
never pump a widget tree.

## Running the tests

Hermetically, against an in-process mock DaVinci server. No tenant, no configuration, no network:

```sh
cd flutter-sdk-bridge/ping_davinci/example
flutter test integration_test/
```

This is what CI runs. A device or emulator must be attached, because the tests exercise the native
SDK through the platform channel.

Against the live DaVinci test tenant, using the non-secret values in the gitignored `flutter/.env`:

```sh
flutter test integration_test/ --dart-define-from-file=../../../.env
```

Live mode switches on when `E2E_DISCOVERY_ENDPOINT` and `E2E_CLIENT_ID` are both set;
`E2E_REDIRECT_URI`, `E2E_SCOPES`, `E2E_ACR_FORM_FIELDS` and `E2E_ACR_SSO` complete it. Only the
sign-on scenario needs a user; it skips itself without one. Pass `E2E_USERNAME`/`E2E_PASSWORD` from
your shell, never a file — this repo is public:

```sh
flutter test integration_test/ --dart-define-from-file=../../../.env \
  --dart-define=E2E_USERNAME="$E2E_USERNAME" --dart-define=E2E_PASSWORD="$E2E_PASSWORD"
```

## What runs

| Scenario | Hermetic | Live | What it proves |
| --- | --- | --- | --- |
| `davinci_configure_test.dart` | yes | yes | `configureDaVinci` returns a non-empty handle id, and a second call returns a different one |
| `davinci_configure_validation_test.dart` | yes | yes | Both OIDC paths at once, or no `discoveryEndpoint`/`openId`, fail with a typed `PingException` |
| `davinci_collector_registration_test.dart` | yes | yes | Every core collector type resolves the moment `configure` returns. A regression guard: the channel round trip hides the iOS race, which `CollectorRegistrationRaceTests` measures instead |
| `davinci_start_next_test.dart` | yes | yes | `start()` returns the form-fields menu with its collectors, and choosing "Form Fields" advances to a different node |
| `davinci_next_wrong_type_test.dart` | yes | yes | A wrong-typed value sent through the host API fails `next()` with an `argument` error and submits nothing |
| `davinci_collector_mapping_test.dart` | yes | skips | One form with all twelve Phase 3 keys maps each to its `Collector` subtype with its fields intact; `ERROR_DISPLAY` and an unregistered `inputType` come back as `unsupportedFields`; the rest submits, with only value-bearing collectors in `formData` |
| `davinci_sign_on_test.dart` | yes | needs a user | Username + password + `SIGNON` reaches a `SuccessNode` |
| `davinci_form_fields_submit_test.dart` | yes | yes | Select, multi-select, boolean and phone-number values are accepted by the server |
| `davinci_flow_action_test.dart` | yes | yes | A `FLOW_BUTTON` submits with `eventType` `action` and opens its branch; the agreement there is display-only and never submitted |
| `davinci_validation_test.dart` | yes | yes | `validate` catches empty required fields, regex mismatches and every password-policy kind on the Form Validation node, with no network call |
| `davinci_error_node_test.dart` | yes | yes | A registration whose password fails the policy is an `ErrorNode` whose `fieldErrors` name `password`, and a retry from its `continueNode` resubmits the same node with the other values kept. Hermetic, the retry succeeds; live, it uses another rejected password, so no user is created |
| `davinci_wrong_password_test.dart` | yes | yes | Wrong credentials are an `ErrorNode` with no field errors (the tenant names none), and correcting them on its `continueNode` signs in. Live, the sign-in needs a user; without one the retry expects another `ErrorNode` |
| `davinci_polling_timeout_test.dart` | yes | skips | Pins the native divergence: a `code: "timedOut"` `400` is an `ErrorNode` on Android and a `FailureNode` on iOS |
| `davinci_session_test.dart` | yes | needs a user | After a `SuccessNode`, `getSession` returns the authorization code, `getToken` the tokens (the code is exchanged exactly once, and a second call reads the stored token), and `getUserInfo` claims with a `sub` |
| `davinci_sign_off_test.dart` | yes | needs a user | `signOff` returns `true`, then `getToken`/`getUserInfo` fail with a `state` error and `getSession` is null. Signs off before any token is asked for, the case where iOS would otherwise redeem the unused code; hermetic, the sign-off request carries the persisted `ST` cookie |
| `davinci_token_before_success_test.dart` | yes | yes | `getToken` before a `SuccessNode` is a typed `PingException` (`state`, or `auth` when an earlier run left a session cookie behind), never an empty token |

The first three need no server at all; the rest use the mock in hermetic mode and the tenant's
form-fields or SSO flow in live mode. Both modes start at the same menu, so those scenarios run
unchanged.

## The mock server

`integration_test/support/mock_davinci_server.dart` is an in-process `HttpServer` that speaks the
DaVinci flow protocol as the native SDKs use it: discovery, a `GET` of the authorize endpoint with
`response_mode=pi.flow` that returns the first node, and a `POST` to each node's `_links.next.href`
that returns the next one. Scenarios script those node bodies in order and then assert on what the SDK
sent — the `pi.flow` parameter, the `x-requested-with` header, the submitted `actionKey`.

The node bodies are not hand-written. `integration_test/support/capture_fixtures.dart` records them
from the live tenant (anonymously) and writes `davinci_captured_fixtures.dart`, with interaction ids
and tokens scrubbed and the tenant origin replaced by `{{baseUrl}}`. It writes the same nodes as
`support/fixtures/*.json` for the native unit tests. Two bodies can't be captured anonymously and are
marked as such in `davinci_fixtures.dart`: the sign-on success (copied from ping-android-sdk's own
recorded response) and one deliberately unregistered field:

```sh
dart run integration_test/support/capture_fixtures.dart ../../../.env
```

## Native iOS tests

`ios/RunnerTests` also holds `ping_davinci`'s Swift unit tests: config parsing, error mapping, node
and collector mapping, value application, and `CollectorRegistrationRaceTests`, which measures the iOS collector-registration race natively. They
run here because a package test target can't link `Flutter.framework`. See the module
[`README.md`](../README.md#tests) for the command.

## Why one scenario per file

The native SDK persists session state in platform secure storage, and it survives across client
instances within a single app install. Once scenarios start flows, two of them in one file would
influence each other. `flutter test integration_test/` runs each file in its own process, so one
scenario per file keeps them independent. Storage outlives the process too: if a scenario fails in a
way that looks like "it was already logged in", uninstall the app from the device and run again.

## Loopback permissions

The mock server runs inside the test process *on the device*, so `127.0.0.1` is correct on both the
Android emulator and the iOS simulator — there is no `10.0.2.2` special case. Both platforms need
cleartext HTTP allowed for it, in this host only:

- **iOS:** `NSAllowsLocalNetworking` in `ios/Runner/Info.plist`, which exempts only local addresses.
- **Android:** `android/app/src/debug/res/xml/network_security_config.xml`, a debug-only
  `base-config` that permits cleartext. It can't be narrowed to loopback: any `domain-config` makes
  Android reject the Ping SDK's TLS calls, which breaks live mode (the file explains why).
  Certificates are still validated, and `src/debug/` never reaches a release build.
