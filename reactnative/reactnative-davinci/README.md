<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

# DaVinci app using React Native

Ping provides these React Native samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

This repository contains an example React Native project demonstrating PingOne DaVinci orchestration using the Ping Orchestration SDK for React Native. The sample renders the DaVinci collector matrix natively — forms, polling and QR, social login, FIDO2 passkeys, device registration/authentication, and PingOne Protect signals — plus the OAuth 2.0 device authorization grant.

## Requirements

- Node.js >= 18
- React Native CLI environment set up for [iOS](https://reactnative.dev/docs/set-up-your-environment?platform=ios) and [Android](https://reactnative.dev/docs/set-up-your-environment?platform=android)
- Xcode: Latest version recommended (iOS 16+)
- Android Studio: Latest version recommended with Java 17 (Android API level 29+)
- Ruby >= 3.3.6 + Bundler (iOS only)
- A PingOne tenant with DaVinci enabled

## Getting Started

1. **Configure Ping services**: create a PingOne OIDC application whose policies point at your DaVinci flow. The DaVinci flow is addressed entirely by the OIDC discovery endpoint of the environment that hosts it:
   `https://auth.pingone.<region>/<environment-id>/as/.well-known/openid-configuration`

2. **Clone the repository**:

   ```sh
   git clone https://github.com/ForgeRock/sdk-sample-apps.git
   cd sdk-sample-apps/reactnative/reactnative-davinci
   ```

3. **Configure the app**: SDK runtime configuration is selected in the app, not from `.env`. Two sources are supported:
   - **JSON presets**: add a JSON file to `assets/configs/`. The file name without `.json` becomes the preset name in the Configuration screen. Copy `DaVinciJsonConfig.json` as a starting point.
   - **Custom configs**: create, edit, and delete configs directly on the app's Configuration screen. Custom configs persist on the device; they are not committed to the repo.

   The files use the unified SDK configuration schema shared with the native Android and iOS sample apps:

   | Key                              | Required | Description                                                                                                                                                                                                                           |
   | -------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
   | `timeout`                        | No       | Request timeout in milliseconds                                                                                                                                                                                                       |
   | `log`                            | No       | `NONE`, `WARN`, or `DEBUG`                                                                                                                                                                                                            |
   | `oidc.clientId`                  | Yes      | OAuth 2.0 client ID                                                                                                                                                                                                                   |
   | `oidc.discoveryEndpoint`         | Yes      | DaVinci environment discovery endpoint (see step 1)                                                                                                                                                                                   |
   | `oidc.scopes`                    | Yes      | Array of OAuth scopes                                                                                                                                                                                                                 |
   | `oidc.redirectUri`               | Yes      | Redirect URI, must match the app's registered scheme                                                                                                                                                                                  |
   | `oidc.openId.*`                  | No       | Endpoint overrides (`authorizationEndpoint`, `tokenEndpoint`, `userinfoEndpoint`, `endSessionEndpoint`, `revocationEndpoint`, `deviceAuthorizationEndpoint`). In this sample they apply to the device authorization grant client only |
   | `oidc.par`                       | No       | Enable Pushed Authorization Requests; enable only when the discovery document advertises a PAR endpoint                                                                                                                               |
   | `oidc.acrValues`                 | No       | Authentication context class reference (your DaVinci flow's ACR value)                                                                                                                                                                |
   | `oidc.additionalParameters`, ... | No       | Other optional OIDC parameters; unknown keys are ignored                                                                                                                                                                              |
   | `protect.envId`                  | No       | PingOne environment ID for PingOne Protect signals; required only when your tenant's Protect initialization rejects a missing environment ID                                                                                          |

   See `assets/configs/*.json` for worked examples. A file that fails validation is skipped at startup with a logged warning naming the offending field.

4. **Redirect URI**: the app's redirect URI scheme is pre-wired to `org.forgerock.demo://oauth2redirect`. The `oidc.redirectUri` in your JSON config must match `manifestPlaceholders["appRedirectUriScheme"]` in `android/app/build.gradle` and the `org.forgerock.demo` entry of `CFBundleURLTypes` in `ios/PingSampleApp/Info.plist`.

5. **Optional native features**: some collectors need build-time platform credentials that `.env` supplies at build time — see `.env.example` for the keys and for which platform needs which. On iOS, copy `ios/Config.local.example.xcconfig` to `ios/Config.local.xcconfig` instead. All keys are optional: without them the rest of the app works, and the affected collectors fail with an error naming the missing platform setup.

   | Feature                                       | When credentials are needed                                                                                                                                                                                                                                                                                                                                                                                                                                         |
   | --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
   | Social login connector backed by **Facebook** | Both platforms. Set the `FACEBOOK_*` keys in `.env`                                                                                                                                                                                                                                                                                                                                                                                                                 |
   | Social login connector backed by **Google**   | iOS only. Set the `GOOGLE_IOS_*` keys in `.env`; on iOS they feed the `GIDClientID` and reversed-client-ID URL scheme in `Info.plist`. Android takes the Google client ID from the DaVinci flow's social login connector, so no app-side configuration is needed                                                                                                                                                                                                    |
   | Social login connector backed by **Apple**    | iOS only, no keys: Apple sign-in uses the `com.apple.developer.applesignin` entitlement already configured in the app. On Android the flow falls back to the browser-based connector                                                                                                                                                                                                                                                                                |
   | **FIDO2** registration/authentication         | Both platforms, when your DaVinci flow relies on credential delegation (webauthn credentials synced through the platform). Set `ASSOCIATED_DOMAIN`: Android builds it into the `asset_statements` resource and iOS uses it as the `webcredentials:` associated-domain entitlement. The domain must host the platform's delegation file (`apple-app-site-association` on iOS, `.well-known/assetlinks.json` on Android) and match the Apple App ID capability on iOS |

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

   On first launch after a DaVinci configuration is selected, the app initializes PingOne Protect, passing the optional `protect.envId` from the selected config. If initialization fails, the DaVinci flow entry stays disabled until Protect succeeds, since Protect signals are part of the flow; the failure message explains how to supply `protect.envId` when your tenant requires it. The device authorization grant screens do not require Protect.

## Supported DaVinci Collectors

The sample renders the collectors that the React Native SDK 1.1.0 supports:

**PingOne Forms connectors**

- Text → `TEXT` (`DaVinciTextField`)
- Password → `PASSWORD`, `PASSWORD_VERIFY` (`DaVinciPasswordField`, with password policy rules and structured validation errors)
- Submit → `SUBMIT_BUTTON` (`DaVinciSubmitButton`)
- Checkbox (single) → `SINGLE_CHECKBOX` (`DaVinciBooleanField`)
- Checkbox List and Combobox → `MULTI_SELECT`, `CHECKBOX`, `COMBOBOX` (`DaVinciMultiSelectField`)
- Dropdown and Radio → `SINGLE_SELECT`, `DROPDOWN`, `RADIO` (`DaVinciSingleSelectField`)
- Phone Number Input → `PHONE_NUMBER` (`DaVinciPhoneNumberField`, incl. extension)
- Flow Button → `FLOW_BUTTON` (`DaVinciFlowButton`)

**Toolbox connectors**

- Agreement → `READ_ONLY_TEXT` (`DaVinciReadOnlyTextField`)
- FIDO2 → `FIDO2` (`DaVinciFidoField`, via `registerForDaVinci`/`authenticateForDaVinci`)
- Flow Link → `FLOW_LINK` (`DaVinciFlowButton`)
- MFA Device Selection (registration and authentication) → `DEVICE_REGISTRATION`, `DEVICE_AUTHENTICATION` (`DaVinciDeviceField`)
- Polling → `POLLING` (`DaVinciPollingField`, terminal statuses advance the flow)
- QR Code → `QR_CODE` (`DaVinciQrCodeField`)
- Social Login → `SOCIAL_LOGIN_BUTTON` (`DaVinciIdpField`, via `authorizeForDaVinci`)
- Translatable Rich Text → `LABEL` (`DaVinciLabelField` with `RichTextLabel`)

**HTTP connector fields** (Text, Password, Submit, Flow Button, Label, Radio/Dropdown) render through the same collector components as their PingOne Forms counterparts above.

**SK-components**

- `skIDP` → social login (`DaVinciIdpField`)
- `skrisk` → PingOne Protect (`collectProtect` runs headlessly before advancing the flow)

## Known Limitations

- The **Image** connector surfaces as an unsupported field in this release (no `IMAGE` collector in the React Native SDK 1.1.0).
- The **New Password** (ValidatedPassword) connector is not supported on React Native (JavaScript only).
- The DaVinci SDK Integrator **Metadata** collector, PingOne MFA **Mobile Pairing** collector, SKPolling components, and images embedded in HTML templates are not supported on React Native.
- **FIDO2** error classification is simplified in this release: cancel detection is available, but fine-grained error codes arrive in a later release.
- **reCAPTCHA Enterprise** verification is not available in the published 1.1.0 packages.
- A polling connector that times out renders a failure node on iOS and an error node on Android (native SDK parity issue).

## Additional Resources

- [DaVinci SDK documentation](https://developer.pingidentity.com/orchsdks/davinci/index.html)
- [Ping SDK documentation](https://developer.pingidentity.com/orchsdks/)

## License

This software may be modified and distributed under the terms of the MIT license. See the LICENSE file for details.

© Copyright 2024-2026 Ping Identity Corporation. All rights reserved.
