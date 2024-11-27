<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://cdn.forgerock.com/logo/interim/Logo-PingIdentity-ForgeRock-Hor-FullColor.svg" alt="Logo">
  </a>
  <hr/>
</p>

# OIDC Sample app using SwiftUI

Ping provides these iOS samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

This repository contains an example iOS project written in SwiftUI making use of the SDK. The sample supports OIDC flows using PingAM, Ping Advanced Identity Cloud, PingOne, Davinci and PingFed.

## Requirements

- Xcode: Latest version recommended
- Ping One DaVinci or PingAM, or AIC, or PingFed
- iOS 16.6 or higher

## Getting Started

To try out the iOS OIDC sample, perform these steps:
1. Configure Ping Services
   Ensure that you registered an OAuth 2.0 application for native mobile apps in PingOne. More details in this [documentation](https://backstage.forgerock.com/docs/sdks/latest/sdks/serverconfiguration/pingone/create-oauth2-client.html).

2. Alternatively, configure PingAM/AIC. Ensure that you registered an OAuth 2.0 application for native mobile apps in PingAM/AIC. More details in this [documentation](https://backstage.forgerock.com/docs/sdks/latest/sdks/serverconfiguration/onpremise/index.html)

2. Clone this repo:

    ```
    git clone https://github.com/ForgeRock/sdk-sample-apps.git
    ```
3. Open the iOS OIDC sample project in XCode.
4. Open the `ConfigurationManager.swift` file within the project.
5. Locate the TODO and replace the placeholder strings in the Oidc module configuration with the values of your registered OAuth 2.0 application.
6. Launch the app on an iOS Device or a Simulator.

## Additional Resources
Ping SDK Documentation: https://docs.pingidentity.com/sdks/latest/sdks/index.html