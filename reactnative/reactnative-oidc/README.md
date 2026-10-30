<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

# OIDC app using React Native

Ping provides these React Native samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

This repository contains an example React Native project demonstrating OIDC (redirect) authentication using the Ping Orchestration SDK for React Native. Can be used with PingOne Advanced Identity Cloud, PingOne and PingAM.

## Requirements

- Node.js >= 18
- React Native CLI environment set up for [iOS](https://reactnative.dev/docs/set-up-your-environment?platform=ios) and [Android](https://reactnative.dev/docs/set-up-your-environment?platform=android)
- Xcode: Latest version recommended (iOS 16+)
- Android Studio: Latest version recommended with Java 17 (Android API level 29+)
- Ruby >= 3.3.6 + Bundler (iOS only)
- Ping AIC, PingAM or PingOne server

## Getting Started

1. **Configure Ping Services**: Register an OAuth 2.0 / OIDC application for native mobile apps. Refer to the official [Server Configuration Guide](https://developer.pingidentity.com/orchsdks/journey/try-it-out/react-native/00_before-you-begin.html) for more details.

2. **Clone the repository**:

   ```sh
   git clone https://github.com/ForgeRock/sdk-sample-apps.git
   cd sdk-sample-apps/reactnative/reactnative-oidc
   ```

3. **Configure the app**: SDK runtime configuration is selected in the app, not from `.env`. This sample has no build-time native settings and needs no `.env` file. Two sources are supported:
   - **JSON presets**: add a JSON file to `assets/configs/`. The file name without `.json` becomes the preset name in the Configuration screen. Copy `openIdJsonConfig.json` as a starting point.
   - **Custom configs**: create, edit, and delete configs directly on the app's Configuration screen. Custom configs persist on the device; they are not committed to the repo.

   The files use the unified SDK configuration schema shared with the native Android and iOS sample apps. Top-level `timeout` (request timeout in milliseconds) and `log` (`NONE`, `WARN`, or `DEBUG`) are optional. Required keys inside the `oidc` block are `clientId`, `discoveryEndpoint`, `scopes` (array), and `redirectUri`; optional keys include `openId.*` endpoint overrides (`authorizationEndpoint`, `tokenEndpoint`, `userinfoEndpoint`, `endSessionEndpoint`, `revocationEndpoint`), `par`, `acrValues`, and `additionalParameters`. Unknown keys are ignored; a file that fails validation is skipped at startup with a logged warning naming the offending field. See `assets/configs/openIdJsonConfig.json` for a worked example.

4. **Redirect URI**: the app's redirect URI scheme is pre-wired to `org.forgerock.oidc://oauth2redirect`. The `oidc.redirectUri` in your JSON config must match `manifestPlaceholders["appRedirectUriScheme"]` in `android/app/build.gradle` and the `oauth2redirect` entry of `CFBundleURLTypes` in `ios/PingSampleApp/Info.plist`.

5. **Install dependencies**:

   ```sh
   yarn install
   ```

6. **iOS only** — install CocoaPods:

   ```sh
   cd ios
   bundle install
   bundle exec pod install
   cd ..
   ```

7. **Android only — keystore setup**: `android/app/build.gradle` signs the debug build with `android/app/debug.keystore` using the alias `androiddebugkey`, and reads the keystore/key passwords from Gradle properties named `KEYSTORE_PASSWORD` and `KEY_PASSWORD`, which aren't set anywhere in this repo. Generate your own debug keystore with that filename and alias:

   ```sh
   keytool -genkeypair -v \
     -keystore android/app/debug.keystore \
     -alias androiddebugkey \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -storepass <your-password> -keypass <your-password> \
     -dname "CN=Android Debug,O=Android,C=US"
   ```

   Then add your credentials to your global `~/.gradle/gradle.properties` (create the file if it doesn't exist):

   ```properties
   KEYSTORE_PASSWORD=<your-password>
   KEY_PASSWORD=<your-password>
   ```

   Skipping this step causes the build to fail signing, which then fails app installation.

8. **Run the app**:

   ```sh
   yarn ios
   # or
   yarn android
   ```

## Additional Resources

- [OIDC SDK documentation](https://developer.pingidentity.com/orchsdks/oidc/index.html)
- [Ping SDK documentation](https://developer.pingidentity.com/orchsdks/)

## License

This software may be modified and distributed under the terms of the MIT license. See the LICENSE file for details.

© Copyright 2024-2026 Ping Identity Corporation. All rights reserved.
