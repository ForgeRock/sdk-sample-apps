<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

# Journey app using React Native

Ping provides these React Native samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

This repository contains an example React Native project making full use of the Ping Orchestration SDK for React Native. The sample supports the OOTB Login Journey with Username and Password, along with device binding, FIDO/WebAuthn, external IdP, device profile, push, and OATH callback integrations.

## Requirements

- Node.js >= 18
- React Native CLI environment set up for [iOS](https://reactnative.dev/docs/set-up-your-environment?platform=ios) and [Android](https://reactnative.dev/docs/set-up-your-environment?platform=android)
- Xcode: Latest version recommended (iOS 16+)
- Android Studio: Latest version recommended with Java 21 (Android API level 29+)
- Ruby >= 3.3.6 + Bundler (iOS only)
- Ping AIC, PingAM, or PingOne server

## Getting Started

1. **Configure Ping Services**: Register an OAuth 2.0 application for native mobile apps in PingAM/AIC. Refer to the official [Server Configuration Guide](https://developer.pingidentity.com/orchsdks/journey/try-it-out/react-native/00_before-you-begin.html) for more details.

2. **Clone the repository**:

   ```sh
   git clone https://github.com/ForgeRock/sdk-sample-apps.git
   cd sdk-sample-apps/reactnative/reactnative-journey
   ```

3. **Configure the app**: SDK runtime configuration is selected in the app, not from `.env`. Two sources are supported:
   - **JSON presets**: add a JSON file to `assets/configs/`. The file name without `.json` becomes the preset name in the Configuration screen. Copy `journeyJsonConfig.json` as a starting point.
   - **Custom configs**: create, edit, and delete configs directly on the app's Configuration screen. Custom configs persist on the device; they are not committed to the repo.

   The files use the unified SDK configuration schema shared with the native Android and iOS sample apps:

   | Key                                                | Required                      | Description                                                                                                                                                  |
   | -------------------------------------------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
   | `timeout`                                          | No                            | Request timeout in milliseconds                                                                                                                              |
   | `log`                                              | No                            | `NONE`, `WARN`, or `DEBUG`                                                                                                                                   |
   | `journey.serverUrl`                                | Yes when `journey` is present | Journey server base URL                                                                                                                                      |
   | `journey.realm`                                    | No                            | Authentication realm                                                                                                                                         |
   | `journey.cookieName`                               | No                            | Session cookie name (mapped to the SDK's `cookie` option)                                                                                                    |
   | `oidc.clientId`                                    | Yes when `oidc` is present    | OAuth 2.0 client ID                                                                                                                                          |
   | `oidc.discoveryEndpoint`                           | Yes when `oidc` is present    | OIDC discovery endpoint URL                                                                                                                                  |
   | `oidc.scopes`                                      | Yes when `oidc` is present    | Array of OAuth scopes                                                                                                                                        |
   | `oidc.redirectUri`                                 | Yes when `oidc` is present    | Redirect URI, must match the app's registered scheme                                                                                                         |
   | `oidc.openId.*`                                    | No                            | Endpoint overrides (`authorizationEndpoint`, `tokenEndpoint`, `userinfoEndpoint`, `endSessionEndpoint`, `revocationEndpoint`, `deviceAuthorizationEndpoint`) |
   | `oidc.par`                                         | No                            | Enable Pushed Authorization Requests                                                                                                                         |
   | `oidc.acrValues`, `oidc.additionalParameters`, ... | No                            | Other optional OIDC parameters; unknown keys are ignored                                                                                                     |

   See `assets/configs/*.json` for worked examples. A file that fails validation is skipped at startup with a logged warning naming the offending field.

4. **Redirect URI**: the app's redirect URI scheme is pre-wired to `org.forgerock.demo://oauth2redirect`. The `oidc.redirectUri` in your JSON config must match `manifestPlaceholders["appRedirectUriScheme"]` in `android/app/build.gradle` and the `oauth2redirect` entry of `CFBundleURLTypes` in `ios/PingSampleApp/Info.plist`.

5. **Optional native features**: external IdP (social login) and passkey (FIDO2) need build-time credentials that `.env` supplies at build time — see `.env.example` for the keys (`FACEBOOK_*`, `GOOGLE_IOS_*`, `ASSOCIATED_DOMAIN`; on iOS copy `ios/Config.local.example.xcconfig` to `ios/Config.local.xcconfig` instead). Without them the rest of the app works; the social login button and passkey ceremonies fail with an error naming the missing platform setup.

6. **Install dependencies**:

   ```sh
   yarn install
   ```

7. **iOS only** — install CocoaPods:

   ```sh
   cd ios
   bundle install
   bundle exec pod install
   cd ..
   ```

8. **Android only — keystore setup**: `android/app/build.gradle` signs the debug build with `android/app/debug.keystore` using the alias `androiddebugkey`, and reads the keystore/key passwords from Gradle properties named `KEYSTORE_PASSWORD` and `KEY_PASSWORD`, which aren't set anywhere in this repo. Locate the TODO comment above `signingConfigs` in `android/app/build.gradle` and generate your own debug keystore with that filename and alias:

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

9. **Run the app**:

   ```sh
   yarn ios
   # or
   yarn android
   ```

## Features

This sample demonstrates:

- Journey-based authentication with callback handling
- Device binding and biometric authentication
- FIDO2/WebAuthn registration and authentication
- External identity provider integration (Google, Facebook)
- Device profile collection
- Push authentication
- OATH callback integration

## Additional Resources

- [Journey SDK documentation](https://developer.pingidentity.com/orchsdks/journey/index.html)
- [Journey use case tutorials](https://developer.pingidentity.com/orchsdks/journey/use-cases.html)
- [Ping SDK documentation](https://developer.pingidentity.com/orchsdks/)

## License

This software may be modified and distributed under the terms of the MIT license. See the LICENSE file for details.

© Copyright 2024-2026 Ping Identity Corporation. All rights reserved.
