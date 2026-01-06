<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

# Journey app using Kotlin

Ping provides these Android samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

This repository contains an example Android project written in Kotlin making use of the SDK. The sample supports the OOTB Journey Login flow.

# Introduction

This sample application demonstrates how to integrate the ForgeRock Android SDK into a basic application. The sample app includes examples of the following:

- OOTB Journey Login flow

- Displaying authenticated user status.

- Displaying authenticated token.

- Ability to logout existing user and restart the login flow.

- Built with modern Android components (Jetpack Compose, Kotlin).

## Requirements

- Android Studio: Latest version recommended
- Ping AIC
- Android API Level: 28 (Android 9.0) or higher

## Getting Started

To try out the Journey Android SDK sample, perform these steps:
1. Configure Ping Services
   Ensure that you registered an OAuth 2.0 application for native mobile apps in AIC. More details in this [documentation](https://backstage.forgerock.com/docs/sdks/latest/sdks/serverconfiguration/pingone/create-oauth2-client.html).

2. Clone this repo:

    ```
    git clone https://github.com/ForgeRock/sdk-sample-apps.git
    ```
3. Open the Android sample project(kotlin-journey) in [Android Studio](https://developer.android.com/studio).
4. Open the `EnvViewModel.kt` file within the project.
5. Locate the TODO and replace the placeholder strings in the Oidc module configuration with the values of your registered OAuth 2.0 application.
   - You can add multiple configurations as shown with `testConfig` and `prodConfig` depending on you Oidc module configuration.
6. Go to `journey\build.gradle.kts` and update the value of `appRedirectUriScheme` with the redirect URI schema from your OIDC configuration.
7. Connect an Android device or emulator.
8. On the **Run** menu, click **Run 'app'**.

## Additional Resources
Ping SDK Documentation: https://docs.pingidentity.com/sdks/latest/sdks/index.html
