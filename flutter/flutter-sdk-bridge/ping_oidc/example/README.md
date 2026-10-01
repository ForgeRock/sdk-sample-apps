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

`OidcClient.authorize()` opens the system browser, and nothing under `integration_test/` can drive
or complete that UI — there is no headless equivalent the way `ping_journey`'s OIDC-in-Journey
flow has, because that flow authorizes with the AM session cookie as a request header, while this
one requires an actual user to interact with a Custom Tab / `ASWebAuthenticationSession`. That
means a genuine signed-in session is unreachable from this suite in either mode, so neither can
this suite cover the success path of `token`/`refresh`/`userInfo`/`revoke`/`signOff` — only the
"no session yet" failure path each of them takes before it would need one.

The real, end-to-end round trip — browser login → token → userinfo → refresh → revoke/sign-off —
is a manual check against the `flutter/flutter-oidc` sample app; see its README.

## What runs in which mode

| Scenario | Hermetic | Live |
| --- | --- | --- |
| `oidc_configure_test.dart` | yes | yes |
| `oidc_no_session_test.dart` | yes | yes |

## The mock server

`integration_test/support/mock_discovery_server.dart` is an in-process `HttpServer` serving a
syntactically-valid discovery document. Because it runs inside the test process *on the device*,
`127.0.0.1` is correct on both the Android emulator and the iOS simulator — there is no `10.0.2.2`
special case. Two platform permissions make that work, scoped as narrowly as possible: an Android
network security config that permits cleartext for loopback only, placed in `src/debug/` so it
cannot reach a release build, and `NSAllowsLocalNetworking` in the iOS `Info.plist`.

Its purpose is the opposite of `ping_journey`'s mock server: proving discovery is *never* fetched
by the calls this suite can reach. Native discovery (`config.init()`) is lazy — it only runs inside
calls that need resolved endpoints, and every one of those (`token`, `refresh`, `userInfo`) first
resolves a signed-in session and fails before touching the network when none exists. So
`MockDiscoveryServer.requests` staying empty for an entire scenario is the assertion, not
incidental — if a future native change starts resolving discovery eagerly at configure time, this
is what will catch it.
