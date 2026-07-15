[![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)](https://github.com/ForgeRock/sdk-sample-apps)

# Journey app using Flutter

Ping provides these Flutter samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

## Introduction

This sample is a Flutter application that uses the `ping_journey` bridge plugin (see
[`../flutter-sdk-bridge/`](../flutter-sdk-bridge/)) to authenticate against a PingAM/PingOne
Advanced Identity Cloud authentication Journey. It demonstrates:

- Starting a named Journey and rendering its callbacks dynamically (Name, Password, Validated
  Username/Password, Choice, KBA, Terms and Conditions, Text Input/Output, and String/Number/
  Boolean Attribute Input).
- Advancing the flow (`next()`) and recovering from an `ErrorNode`/`FailureNode` via a "Try Again"
  button.
- Retrieving the access/refresh token and userinfo after a successful login (OIDC module).
- Signing off and restarting.

The bridge wraps the published native Android and iOS Ping SDKs (native-wrapper approach) rather
than a pure-Dart reimplementation.

## Requirements

- Flutter 3.44.x stable / Dart 3.12.x
- A PingAM/PingOne Advanced Identity Cloud server with a configured authentication Journey
- Android: API level 29+, Java 17
- iOS: 16.0+, Xcode with Swift Package Manager support

## Getting Started

To try out the Journey Flutter sample, perform these steps:

1. Configure Ping Services. Ensure you have a PingAM/AIC server configured with an authentication
   Journey (e.g. "Login") and, if you want the post-login token exchange, an OAuth 2.0 application
   for native mobile apps. More details in this
   [documentation](https://backstage.forgerock.com/docs/sdks/latest/sdks/serverconfiguration/pingone/create-oauth2-client.html).
2. Clone this repo:

   ```
   git clone https://github.com/ForgeRock/sdk-sample-apps.git
   ```
3. From `sdk-sample-apps/flutter/`, run `flutter pub get` to resolve the pub workspace
   (`flutter-sdk-bridge/ping_core`, `flutter-sdk-bridge/ping_journey`, `flutter-journey`).
4. Open [`lib/config/env.dart`](lib/config/env.dart) and replace the TODO placeholders:
   - `serverUrl`, `realm`, `cookie` — your tenant's Journey server configuration.
   - `oidcConfig` — your OAuth 2.0 client's `clientId`/`discoveryEndpoint`/`scopes`/`redirectUri`,
     or leave `null` to skip the post-login token exchange (Journey-only, session login).
5. If you set `oidcConfig`, register `redirectUri`'s custom scheme with both native hosts:
   - Android: add an `intent-filter` for the scheme in `android/app/src/main/AndroidManifest.xml`.
   - iOS (SPM): add a `CFBundleURLTypes` entry for the scheme in `ios/Runner/Info.plist`.
6. Run the app: `flutter run` from this directory (`flutter-journey/`), or open
   `ios/Runner.xcworkspace` in Xcode / the Android project in Android Studio.

## Testing

Unit and widget tests run with `flutter test` from this directory (or `flutter/` root). The
integration tests under `integration_test/` drive real Journeys against the configured tenant —
run each file standalone against a booted simulator/emulator or device (not combined in one
`flutter test` invocation — the native SDK persists the AM session cookie on-device across
`Journey` instances within one app install, so running both back-to-back in one process changes
each Journey's first-node response):

```
flutter test integration_test/journey_login_test.dart \
  --dart-define=E2E_USERNAME=<username> --dart-define=E2E_PASSWORD=<password>
flutter test integration_test/journey_registration_test.dart
```

`journey_login_test.dart`'s credentialed assertions (login, Success screen, sign-off) only run
when `E2E_USERNAME`/`E2E_PASSWORD` are supplied, since no test credentials are committed to this
public sample repo. `journey_registration_test.dart` needs no credentials — it signs up a fresh,
uniquely-suffixed user each run.

## Native SDK version

Both platforms pin the native Ping SDK to **2.0.0** — Android via Maven
(`com.pingidentity.sdks:*`), iOS via Swift Package Manager
(`github.com/ForgeRock/ping-ios-sdk`, exact `2.0.0`).

## Additional Resources

Ping SDK Documentation: https://docs.pingidentity.com/sdks/latest/sdks/index.html

## License

This software may be modified and distributed under the terms of the MIT license. See the LICENSE file for details.

© Copyright 2026 Ping Identity Corporation. All rights reserved.