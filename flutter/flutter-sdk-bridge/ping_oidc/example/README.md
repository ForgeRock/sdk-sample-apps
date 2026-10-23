# ping_oidc integration-test host

This is not a sample app. If you are looking for one, see [`flutter-oidc`](../../../flutter-oidc).

The `integration_test` package can only run from a Flutter *application*, and `ping_oidc` is a
plugin. This app exists solely to give the plugin's integration tests a process to run in. Its
`lib/main.dart` is a deliberately empty screen — the tests drive `OidcClient` directly and never
pump a widget tree.

## Running the tests

Hermetically, against an in-process mock discovery server. No tenant, no configuration, no network
beyond loopback:

```sh
cd flutter-sdk-bridge/ping_oidc/example
flutter test integration_test/
```

This is what CI runs. A device or emulator must be attached, because the tests exercise the native
SDK through the platform channel.

Against a real OAuth 2.0 client on a real tenant:

```sh
flutter test integration_test/ \
  --dart-define=E2E_CLIENT_ID=my-client \
  --dart-define=E2E_DISCOVERY_ENDPOINT=https://openam.example.com/oauth2/.well-known/openid-configuration \
  --dart-define=E2E_REDIRECT_URI=com.example.app://oauthredirect
```

Credentials are read through `String.fromEnvironment`, so they live in your shell or your CI
secret store and are never written to a file in this repository — this is a public samples repo.

## What this suite does not cover

A real interactive login. `OidcClient.authorize()` opens the system browser, and nothing under
`integration_test/` can type credentials into a Custom Tab / `ASWebAuthenticationSession`. So against
a **live** tenant this suite can't reach a signed-in session, and the live success path of
`token`/`refresh`/`userInfo`/`revoke`/`signOff` stays a manual check against the `flutter/flutter-oidc`
sample app (see its README).

**Hermetically** one browser round trip *is* covered. `oidc_openid_only_authorize_test.dart` points an
explicit-`openId` client at `MockOidcProvider`, whose `/oauth2/authorize` answers the browser's first
request with a `302` straight to the redirect URI. The browser follows it into the app with no UI
interaction, and the native SDK redeems the code. That proves authorize → token → userinfo works with
an `openId`-only config and **no discovery request**, on both platforms (impossible on iOS before
native 2.2.0, SDKS-5301).

## What runs in which mode

| Scenario | Hermetic | Live |
| --- | --- | --- |
| `oidc_configure_test.dart` | yes | yes |
| `oidc_no_session_test.dart` | yes | yes |
| `oidc_openid_only_authorize_test.dart` | yes | skips (needs the mock's auto-redirect) |

## Preconditions for the browser scenario

- **Android:** Chrome must have completed its first-run screen on the emulator/device at least once
  (open Chrome by hand and get through the welcome screens). Otherwise Chrome's `FirstRunActivity`
  intercepts the Custom Tab and `authorize()` never reaches the mock; the scenario fails after 60 s
  with a message saying so. The test host sets `manifestPlaceholders["appRedirectUriScheme"] =
  "pingoidcexample"` so the redirect lands back in the app.
- **iOS:** none. The scenario uses `ephemeralAuthSession`, which shows no "wants to use … to sign in"
  consent alert. Run from a clean Keychain (`xcrun simctl keychain <udid> reset`) if an earlier run
  left a session behind.

## The mock server

`integration_test/support/mock_discovery_server.dart` is an in-process `HttpServer` serving a
syntactically-valid discovery document. Because it runs inside the test process *on the device*,
`127.0.0.1` is correct on both the Android emulator and the iOS simulator — there is no `10.0.2.2`
special case. Two platform permissions make that work, scoped as narrowly as possible: an Android
network security config that permits cleartext for loopback only, placed in `src/debug/` so it
cannot reach a release build, and `NSAllowsLocalNetworking` in the iOS `Info.plist`.

(`MockDiscoveryServer` only. The browser scenario uses its own `MockOidcProvider`, described above.)
Its purpose is the opposite of `ping_journey`'s mock server: proving discovery is *never* fetched
by the calls this suite can reach. Native discovery (`config.init()`) is lazy — it only runs inside
calls that need resolved endpoints, and every one of those (`token`, `refresh`, `userInfo`) first
resolves a signed-in session and fails before touching the network when none exists. So
`MockDiscoveryServer.requests` staying empty for an entire scenario is the assertion, not
incidental — if a future native change starts resolving discovery eagerly at configure time, this
is what will catch it.
