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
- Android Studio: Latest version recommended with Java 17 (Android API level 29+)
- Ruby >= 3.3.6 + Bundler (iOS only)
- Ping AIC, PingAM, or PingOne server

## Getting Started

1. **Configure Ping Services**: Register an OAuth 2.0 application for native mobile apps in PingAM/AIC. Refer to the official [Server Configuration Guide](https://developer.pingidentity.com/orchsdks/journey/try-it-out/react-native/00_before-you-begin.html) for more details.

2. **Clone the repository**:

    ```sh
    git clone https://github.com/ForgeRock/sdk-sample-apps.git
    cd sdk-sample-apps/reactnative/reactnative-journey
    ```

3. **Configure the app**: Copy the example env file and fill in your server details.

    ```sh
    cp .env.example .env
    ```

    Edit `.env` with your values:

    ```sh
    JOURNEY_SERVER_URL=https://your-journey-host.example.com/am
    JOURNEY_REALM=your-journey-realm
    JOURNEY_COOKIE=your-journey-cookie-name
    JOURNEY_CLIENT_ID=your-journey-client-id
    JOURNEY_DISCOVERY_ENDPOINT=https://your-journey-host.example.com/am/oauth2/your-journey-realm/.well-known/openid-configuration
    JOURNEY_REDIRECT_URI=org.forgerock.demo://oauth2redirect
    JOURNEY_SCOPES=openid,email,profile,address
    ```

    See `.env.example` for the full list of supported keys, including external IdP (Facebook, Google) configuration.

4. **Redirect URI**: the app's redirect URI scheme is pre-wired to `org.forgerock.demo://oauth2redirect`. If you pick a different scheme, update `JOURNEY_REDIRECT_URI` in `.env`, `manifestPlaceholders["appRedirectUriScheme"]` in `android/app/build.gradle`, and the `oauth2redirect` entry of `CFBundleURLTypes` in `ios/PingSampleApp/Info.plist`.

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
- [Ping SDK documentation](https://docs.pingidentity.com/sdks/latest/sdks/index.html)

## License

This software may be modified and distributed under the terms of the MIT license. See the LICENSE file for details.

© Copyright 2024-2026 Ping Identity Corporation. All rights reserved.
