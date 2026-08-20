[![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)](https://github.com/ForgeRock/sdk-sample-apps)

# Flutter Samples

Ping provides these Flutter samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

Ping ships official React Native, iOS, and Android SDKs but no first-party Flutter SDK. This directory provides one: a native-wrapper **bridge plugin** ([`flutter-sdk-bridge/`](flutter-sdk-bridge/), wrapping the published native Android/iOS Ping SDKs) plus **sample apps** that use it.

This is a native Dart [pub workspace](https://dart.dev/tools/pub/workspaces) — one `flutter pub get` from this directory resolves every package below.

## Samples

- [**Journey — `flutter-journey/`**](flutter-journey/) — authenticates against a PingAM/PingOne Advanced Identity Cloud authentication Journey: dynamic callback rendering, login, self-registration, and post-login token retrieval.

## SDK Bridge

- [`flutter-sdk-bridge/`](flutter-sdk-bridge/) — the `ping_core` + `ping_journey` plugin packages
  the sample above is built on. See its README for how to add a bridge module for a future
  sample (e.g. DaVinci, OIDC).

## Requirements

- Flutter 3.44.x stable / Dart 3.12.x
- Android: API level 29+, Java 17
- iOS: 16.0+, Xcode with Swift Package Manager support

## Native SDK version

Both platforms pin the native Ping SDKs to **2.1.0** — Android via Maven
(`com.pingidentity.sdks:*`), iOS via Swift Package Manager
(`github.com/ForgeRock/ping-ios-sdk`, exact `2.1.0`).

## License

This software may be modified and distributed under the terms of the MIT license. See the LICENSE file for details.

© Copyright 2026 Ping Identity Corporation. All rights reserved.