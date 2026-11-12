[![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)](https://github.com/ForgeRock/sdk-sample-apps)

# Ping Example app using Flutter

Ping provides these Flutter samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

## Introduction

One Flutter app that demonstrates all three Ping authentication flows through the `ping_journey`,
`ping_davinci` and `ping_oidc` bridge plugins (see [`../flutter-sdk-bridge/`](../flutter-sdk-bridge/)).
It combines the [`flutter-journey`](../flutter-journey/), [`flutter-davinci`](../flutter-davinci/) and
[`flutter-oidc`](../flutter-oidc/) samples behind a Home screen:

- **Journey** — a PingAM / Advanced Identity Cloud authentication tree, rendered natively from callbacks.
- **DaVinci** — a PingOne DaVinci flow, rendered natively from collectors, with no browser.
- **OIDC** — centralized login in the system browser, then tokens, userinfo, refresh and revoke.

Each flow opens straight onto its one editable input (the journey name for Journey, the `acr_values`
for DaVinci, the login button for OIDC), then runs the flow and shows the session. The tune icon on
Home opens a read-only **Environments** screen with every flow's configuration; values still set to a
`<placeholder>` are flagged, and tapping a value copies it. Flow screens are nested under Home, so
their back arrow returns to it.

### One active session at a time

The native Ping SDKs keep OIDC tokens in one default storage slot (on iOS, a single Keychain account),
and the bridge does not expose per-client storage. Signing in with one flow would therefore overwrite
another's tokens. The app tracks the active session in `SessionCoordinator`
(`lib/core/session/`) and, before starting a different flow, asks you to sign out of the current one.
Home shows the active session with **View Session** and **Sign Off**.

## Requirements

- Flutter 3.44.x stable / Dart 3.12.x or newer
- Android: API level 29+, Java 17
- iOS: 16.0+, Xcode with Swift Package Manager support
- For each flow you want to try: a PingAM / Advanced Identity Cloud journey with an OAuth 2.0 client
  (Journey), a PingOne application running a DaVinci flow (DaVinci), and an OAuth 2.0 client with a
  browser redirect URI (OIDC). More details in this
  [documentation](https://backstage.forgerock.com/docs/sdks/latest/sdks/serverconfiguration/pingone/create-oauth2-client.html).

## Getting Started

1. Clone this repo and, from `sdk-sample-apps/flutter/`, run `flutter pub get` to resolve the pub
   workspace.
2. Configure each flow you want to try by replacing the `<placeholder>` defaults in its `Env` class, or
   by passing the values at build time with `--dart-define` / `--dart-define-from-file=.env`:

   | Flow | Env class | Keys |
   | --- | --- | --- |
   | Journey | `lib/features/journey/config/journey_env.dart` | `PINGAIC_JOURNEY_SERVER_URL`, `_REALM`, `_COOKIE`, `_DISCOVERY_ENDPOINT`, `_CLIENT_ID`, `_REDIRECT_URI`, `_SCOPES` |
   | DaVinci | `lib/features/davinci/config/davinci_env.dart` | `PINGONE_DISCOVERY_ENDPOINT`, `_CLIENT_ID`, `_REDIRECT_URI`, `_SCOPES`, `_ACR_VALUES` |
   | OIDC | `lib/features/oidc/config/oidc_env.dart` | `PINGAIC_OIDC_DISCOVERY_ENDPOINT`, `_CLIENT_ID`, `_REDIRECT_URI`, `_SIGN_OUT_REDIRECT_URI`, `_SCOPES` |

   A `.env` file in this folder is gitignored by the repo, so keep your tenant values there rather
   than in the classes. Nothing secret belongs in either place: every flow collects the user's
   credentials itself.
3. Run the app: `flutter run --dart-define-from-file=.env` from this directory, or open `ios/Runner.xcworkspace` in Xcode / the
   `android/` project in Android Studio.

## Redirect URI setup

Only the **OIDC** flow opens a browser and is redirected back to the app.

### Android

The native `browser` module (2.2.0+) requires the `appRedirectUriScheme` manifest placeholder, or the
manifest merge fails. It is set in `android/app/build.gradle.kts` and **must match the scheme of
`OidcEnv.redirectUri`**:

```kotlin
defaultConfig {
    manifestPlaceholders["appRedirectUriScheme"] = "com.pingidentity.flutter.oidc"
}
```

### iOS

No `Info.plist` change is required: `ASWebAuthenticationSession`'s callback scheme is set
programmatically from the redirect URI.

### Journey and DaVinci

Neither flow is redirected anywhere, so their redirect URIs only need to match one registered on the
server for the client. They need no manifest or `Info.plist` entry.

## Testing

Like the other samples, this app ships no feature tests: the behaviour it demonstrates is covered by the
bridge packages' unit and integration tests (see [`../flutter-sdk-bridge/`](../flutter-sdk-bridge/)).
`test/widget_test.dart` only checks that Home lists the three flows and that each opens its config screen.

## Native SDK version

Both platforms pin the native Ping SDK to **2.2.0** — Android via Maven
(`com.pingidentity.sdks:*`), iOS via Swift Package Manager
(`github.com/ForgeRock/ping-ios-sdk`, exact `2.2.0`).

## Additional Resources

Ping SDK Documentation: https://docs.pingidentity.com/sdks/latest/sdks/index.html

## License

This software may be modified and distributed under the terms of the MIT license. See the LICENSE file for details.

© Copyright 2026 Ping Identity Corporation. All rights reserved.
