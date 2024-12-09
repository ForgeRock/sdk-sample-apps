<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

# DaVinci app using Kotlin

Ping provides these Android samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

This repository contains an example Android project written in Kotlin making use of the SDK. The sample supports the OOTB DaVinci Login flow.

## Requirements

- Android Studio: Latest version recommended
- Ping One DaVinci
- Android API Level: 28 (Android 9.0) or higher

## Getting Started

To try out the DaVinci Android SDK sample, perform these steps:
1. Configure Ping Services
   Ensure that you registered an OAuth 2.0 application for native mobile apps in PingOne. More details in this [documentation](https://backstage.forgerock.com/docs/sdks/latest/sdks/serverconfiguration/pingone/create-oauth2-client.html).

2. Clone this repo:

    ```
    git clone https://github.com/ForgeRock/sdk-sample-apps.git
    ```
3. Open the Android sample project(kotlin-davinci) in [Android Studio](https://developer.android.com/studio).
4. Open the `DaVinciViewModel.kt` file within the project.
5. Locate the TODO and replace the placeholder strings in the Oidc module configuration with the values of your registered OAuth 2.0 application.
6. Connect an Android device or emulator.
7. On the **Run** menu, click **Run 'app'**.

## Additional Resources
Ping SDK Documentation: https://docs.pingidentity.com/sdks/latest/sdks/index.html