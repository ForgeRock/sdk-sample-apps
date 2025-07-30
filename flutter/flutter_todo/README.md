<p align="center">
  <a href="https://github.com/ForgeRock/ping-android-sdk">
    <img src="https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg" alt="Logo">
  </a>
  <hr/>
</p>

# Ping SDKs Sample using Flutter

Ping provides these Flutter samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

- An example Flutter project making use of the iOS and Android SDKs to demonstrate the use of the Native SDKs on a Hybrid framework like flutter with a use of a bridging layer. The app makes use of the [`../javascript/todo-api/`](../javascript/todo-api/) project as a backend storage mechanism for the `To-Do` list. 

## Requirements

- Xcode: Latest version recommended
- Android Studio: Latest version recommended
- VS Code: Latest Version recommended
- VS Code Flutter Plug in: Latest Version recommended
- PingAM, or AIC

## Getting Started

To try out the Ping SDKs Flutter sample, perform these steps:
1. Configure PingAM/AIC. Ensure that you registered an OAuth 2.0 application for native mobile apps in PingAM/AIC. More details in this [documentation](https://backstage.forgerock.com/docs/sdks/latest/sdks/serverconfiguration/onpremise/index.html)
2. Configue the `todo-api` `.env` file and run using `npm start --workspace todo-api` on a Terminal window.
3. Clone this repo:

    ```
    git clone https://github.com/ForgeRock/sdk-sample-apps.git
    ```
4. Open the Flutter sample project in VSCode (Flutter Plug installed).
5. Open the `FRAuthSampleBridge.swift` file within the iOS project.
6. Locate the `Configuration` struct and replace the placeholder strings in the Oidc module configuration with the values of your registered OAuth 2.0 application.
7. Open the `todolist.dart` file and edit the `String API_URL`. Point to the IP and Port of the `todo-api` running on your Machine. (For iOS use `localhost` for Android `10.0.2.2` if running locally. Ex: `String API_URL = "http://10.0.2.2:9443/todos";`) 
8. Launch the app on an iOS Device or a Simulator.
9. Repeat the same steps for the Android Sample altering the configuration on `FRAuthSampleBridge.java`
10. Run on an Android Device or Emulator

## Additional Resources
Ping SDK Documentation: https://docs.pingidentity.com/sdks/latest/sdks/index.html