[![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)](https://github.com/ForgeRock/sdk-sample-apps)

# OIDC app using Flutter

Ping provides these Flutter samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

## Introduction

This sample is a Flutter application that uses the `ping_oidc` bridge plugin (see
[`../flutter-sdk-bridge/`](../flutter-sdk-bridge/)) to perform browser-based, centralized OIDC
login against a PingAM/PingOne Advanced Identity Cloud (or any standard OIDC) authorization
server. It demonstrates:

- Configuring an `OidcClient` from a discovery endpoint (or an explicit `OidcOpenIdConfig`) and a
  client id.
- Opening the system browser (Chrome Custom Tabs on Android, `ASWebAuthenticationSession` on iOS)
  to authenticate, and recovering cleanly if the user cancels.
- Reading the access/refresh/ID token and userinfo claims after a successful login.
- Forcing a token refresh, revoking a token, and signing off.

The bridge wraps the published native Android and iOS Ping SDKs (native-wrapper approach) rather
than a pure-Dart reimplementation. Unlike the Journey sample, there is **no** deep-link/`go_router`
step in this flow: the native SDK captures the browser's redirect and exchanges the authorization
code internally, so no authorization code, `state`, or redirect URI ever crosses the Dart bridge in
either direction.

## Requirements

- Flutter 3.44.x stable / Dart 3.12.x
- An OAuth 2.0/OIDC client registered on a PingAM/PingOne Advanced Identity Cloud server (or any
  standard OIDC provider) that supports a native/mobile redirect URI
- Android: API level 29+, Java 17
- iOS: 16.0+, Xcode with Swift Package Manager support

## Getting Started

To try out the OIDC Flutter sample, perform these steps:

1. Register an OAuth 2.0/OIDC client on your authorization server that allows a custom-scheme
   mobile redirect URI (not a `localhost`/web callback — see § Redirect URI setup below for why).
   More details in this
   [documentation](https://backstage.forgerock.com/docs/sdks/latest/sdks/serverconfiguration/pingone/create-oauth2-client.html).
2. Clone this repo:

   ```
   git clone https://github.com/ForgeRock/sdk-sample-apps.git
   ```
3. From `sdk-sample-apps/flutter/`, run `flutter pub get` to resolve the pub workspace
   (`flutter-sdk-bridge/ping_core`, `flutter-sdk-bridge/ping_oidc`, `flutter-oidc`).
4. Open [`lib/config/env.dart`](lib/config/env.dart) and replace the TODO placeholders with your
   client's `discoveryEndpoint`, `clientId`, `redirectUri`, and `scopes`.
5. Register `redirectUri`'s custom scheme with both native hosts — see § Redirect URI setup below
   for the exact snippets, since this is the step most likely to trip up a first run.
6. Run the app: `flutter run` from this directory (`flutter-oidc/`), or open
   `ios/Runner.xcworkspace` in Xcode / the Android project in Android Studio.

## Redirect URI setup — read this before your first run

This is the single most common source of a first-run failure: a redirect URI that never routes
back to the app leaves the browser open with no way to complete or cancel the flow from the SDK's
point of view.

**`redirectUri` must be a custom-scheme URI (e.g. `com.pingidentity.flutter.oidc://oauthredirect`),
not an HTTPS URL**, unless that HTTPS URL is a verified Android App Link
(`assetlinks.json` + `android:autoVerify="true"`) — a plain HTTPS redirect with none of that
plumbing can never route back to `CustomTabActivity`. `${appRedirectUriScheme}` (see the Android
snippet below) is a Gradle/manifest **build-time placeholder only**; it has no meaning at the Dart
config level and must never appear literally in `env.dart`.

### Android

1. In `android/app/build.gradle.kts`, set the placeholder to your scheme (already done for the
   scheme shipped in this sample):

   ```kotlin
   defaultConfig {
       manifestPlaceholders["appRedirectUriScheme"] = "com.pingidentity.flutter.oidc"
   }
   ```

2. That placeholder alone is **not sufficient** on the native SDK's current published release
   (`browser:2.1.0` ships `CustomTabActivity`'s manifest entry with its scheme already resolved to
   a literal placeholder value, not the unresolved token — see AGENT_NOTES.md for the full
   investigation and the filed SDK ticket). The mechanism that actually works is an app-level
   manifest re-declaration with `tools:node="merge"`, already present in
   [`android/app/src/main/AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml):

   ```xml
   <activity
       android:name="com.pingidentity.browser.CustomTabActivity"
       android:exported="true"
       tools:node="merge">
       <intent-filter>
           <action android:name="android.intent.action.VIEW"/>
           <category android:name="android.intent.category.DEFAULT"/>
           <category android:name="android.intent.category.BROWSABLE"/>
           <data android:scheme="com.pingidentity.flutter.oidc"/>
       </intent-filter>
   </activity>
   ```

   If you change the scheme, update **both** the `manifestPlaceholders` entry and this `<data
   android:scheme="...">` value, and update `env.dart`'s `redirectUri` to match.

### iOS

**No `Info.plist` change is required.** `ASWebAuthenticationSession`'s callback scheme is set
programmatically from `OidcConfig.redirectUri` before the browser ever launches — there is no
`CFBundleURLTypes` entry to add for this flow. (This differs from a classic
`UIApplication.open(url:)`-based OAuth flow, which does need one; standalone OIDC's browser step
doesn't.)

## Testing

**This sample ships no tests, by design.** Sample apps in this repository are reference
implementations meant to be read and run, not test fixtures — the same convention the Kotlin,
Swift, React Native, and Journey Flutter samples follow.

Test coverage for the behaviour this app demonstrates lives in the bridge package instead:

- **Unit tests** — `../flutter-sdk-bridge/ping_oidc/test/` (config/token mapping, error
  translation). Run with `flutter test` from the `flutter/` workspace root.
- **Integration tests** — `../flutter-sdk-bridge/ping_oidc/example/integration_test/`, which drive
  the real `OidcClient` API against a hermetic mock discovery server, with no UI in the loop (the
  browser-authorize step itself can't be scripted — see
  [that package's README](../flutter-sdk-bridge/ping_oidc/example/README.md) for exactly what is
  and isn't covered this way).

If you want to verify the full browser login round trip against your own tenant, run this app
(`flutter run`) and walk the flow by hand.

## Native SDK version

Both platforms pin the native Ping SDK to **2.1.0** — Android via Maven
(`com.pingidentity.sdks:*`), iOS via Swift Package Manager
(`github.com/ForgeRock/ping-ios-sdk`, exact `2.1.0`).

## Additional Resources

Ping SDK Documentation: https://docs.pingidentity.com/sdks/latest/sdks/index.html

## License

This software may be modified and distributed under the terms of the MIT license. See the LICENSE file for details.

© Copyright 2026 Ping Identity Corporation. All rights reserved.
