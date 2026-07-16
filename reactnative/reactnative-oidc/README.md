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

3. **Configure the app**: Copy the example env file and fill in your server details.

    ```sh
    cp .env.example .env
    ```

    Locate the TODO comment in `.env.example` and replace the placeholder values in `.env` with your configuration.

4. **Redirect URI**: the app's redirect URI scheme is pre-wired to `org.forgerock.oidc://oauth2redirect`. If you pick a different scheme, update the redirect URI values in `.env`, `manifestPlaceholders["appRedirectUriScheme"]` in `android/app/build.gradle`, and the `oauth2redirect` entry of `CFBundleURLTypes` in `ios/PingSampleApp/Info.plist`.

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

7. **Run the app**:

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
