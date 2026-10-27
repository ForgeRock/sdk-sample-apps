[![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)](https://github.com/ForgeRock/sdk-sample-apps)

# DaVinci app using Flutter

Ping provides these Flutter samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

## Introduction

This sample is a Flutter application that uses the `ping_davinci` bridge plugin (see
[`../flutter-sdk-bridge/`](../flutter-sdk-bridge/)) to run a PingOne DaVinci flow natively, with no
browser. It demonstrates:

- Configuring a `DaVinciClient` from a discovery endpoint, client id, redirect URI and scopes, and
  choosing the flow to run with `acr_values` (the flow policy id), which the start screen lets you
  change per run.
- Rendering each `ContinueNode`'s collectors as a dynamic form: text, password (with verify),
  submit and flow buttons, labels, read-only text, single/multi select, boolean, phone number,
  image, polling, QR code, device registration/authentication, and metadata.
- Local validation before submit, and showing the server's per-field errors from an `ErrorNode`
  on the same form so the user can correct and retry.
- Listing any field the app can't render (`unsupportedFields`) instead of failing the whole form.
- Reading the authorization code, tokens and userinfo after a successful flow, reloading the
  token (the native SDK refreshes it if it has expired), and signing off.

The bridge wraps the published native Android and iOS Ping SDKs (native-wrapper approach) rather
than a pure-Dart reimplementation. Unlike the OIDC sample, a DaVinci flow never opens the system
browser: every step is a form your app renders from the node the SDK returns.

## Requirements

- Flutter 3.44.x stable / Dart 3.12.x
- A PingOne environment with a DaVinci flow, and a PingOne OIDC application whose policy runs it
- Android: API level 29+, Java 17
- iOS: 16.0+, Xcode with Swift Package Manager support

## Getting Started

To try out the DaVinci Flutter sample, perform these steps:

1. Register an OAuth 2.0 application for native mobile apps in PingOne, with a policy that runs
   your DaVinci flow. More details in this
   [documentation](https://backstage.forgerock.com/docs/sdks/latest/sdks/serverconfiguration/pingone/create-oauth2-client.html).
2. Clone this repo:

   ```
   git clone https://github.com/ForgeRock/sdk-sample-apps.git
   ```
3. From `sdk-sample-apps/flutter/`, run `flutter pub get` to resolve the pub workspace
   (`flutter-sdk-bridge/ping_core`, `flutter-sdk-bridge/ping_davinci`, `flutter-davinci`).
4. Open [`lib/config/env.dart`](lib/config/env.dart) and replace the TODO placeholders with your
   application's `discoveryEndpoint`, `clientId`, `redirectUri` and `scopes`, and optionally the
   `acrValues` that select your flow. Each value can instead be passed at build time with
   `--dart-define` (or `--dart-define-from-file=../.env`) using the key named next to it:
   `PINGONE_DISCOVERY_ENDPOINT`, `PINGONE_CLIENT_ID`, `PINGONE_REDIRECT_URI`, `PINGONE_SCOPES` and
   `PINGONE_ACR_VALUES`.
5. If you change the redirect URI's scheme, update the Android placeholder to match — see
   § Redirect URI setup below.
6. Run the app: `flutter run` from this directory (`flutter-davinci/`), or open
   `ios/Runner.xcworkspace` in Xcode / the Android project in Android Studio.

## Redirect URI setup

A DaVinci flow doesn't redirect anywhere, but PingOne still checks `redirect_uri` on the authorize
request, so `Env.redirectUri` must be one of the redirect URIs registered on your application.

### Android

The native SDK pulls in the `browser` module, which since `2.2.0` requires the app to set the
`appRedirectUriScheme` manifest placeholder, or the manifest merge fails. This sample sets it in
`android/app/build.gradle.kts`:

```kotlin
defaultConfig {
    manifestPlaceholders["appRedirectUriScheme"] = "com.pingidentity.flutter.davinci"
}
```

Keep it in sync with the scheme of `Env.redirectUri`.

### iOS

**No `Info.plist` change is required.** Nothing is ever redirected back to the app.

## Testing

**This sample ships no tests, by design.** Sample apps in this repository are reference
implementations meant to be read and run, not test fixtures — the same convention the Kotlin,
Swift, React Native, Journey and OIDC Flutter samples follow.

Test coverage for the behaviour this app demonstrates lives in the bridge package instead:

- **Unit tests** — `../flutter-sdk-bridge/ping_davinci/test/` (collector and node mapping,
  validation, error translation). Run with `flutter test` from the `flutter/` workspace root.
- **Integration tests** — `../flutter-sdk-bridge/ping_davinci/example/integration_test/`, which
  drive the real `DaVinciClient` API against a hermetic mock DaVinci server, with no UI in the
  loop. See [that package's README](../flutter-sdk-bridge/ping_davinci/README.md) for how to run
  them, including against a live tenant.

If you want to verify a full flow against your own tenant, run this app (`flutter run`) and walk
it by hand.

## Native SDK version

Both platforms pin the native Ping SDK to **2.2.0** — Android via Maven
(`com.pingidentity.sdks:*`), iOS via Swift Package Manager
(`github.com/ForgeRock/ping-ios-sdk`, exact `2.2.0`).

## Additional Resources

Ping SDK Documentation: https://docs.pingidentity.com/sdks/latest/sdks/index.html

## License

This software may be modified and distributed under the terms of the MIT license. See the LICENSE file for details.

© Copyright 2026 Ping Identity Corporation. All rights reserved.
