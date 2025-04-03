<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

# DaVinci app using Swift/SwiftUI

Ping provides these iOS samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

### Integrate with PingOne DaVinci:

- An example iOS project written in Swift/SwiftUI making use of the SDK. The sample supports the OOTB DaVinci Login flow.

## Requirements

- Xcode: Latest version recommended
- PingOne DaVinci
- iOS 16.6 or higher

## Getting Started

To try out the DaVinci iOS SDK sample, perform these steps:
1. Configure Ping Services
   Ensure that you registered an OAuth 2.0 application for native mobile apps in PingOne. More details in this [documentation](https://backstage.forgerock.com/docs/sdks/latest/sdks/serverconfiguration/pingone/create-oauth2-client.html).

2. Clone this repo:

    ```
    git clone https://github.com/ForgeRock/sdk-sample-apps.git
    ```
3. Open the iOS sample project(swiftui-davinci) in [Xcode](https://developer.apple.com/xcode/).
4. Open the `DavinciViewModel.swift` file within the project.
5. Locate the TODO and replace the placeholder strings in the Oidc module configuration with the values of your registered OAuth 2.0 application.
6. Launch the app on an iOS Device or a Simulator.

## Additional Resources
Ping SDK Documentation: https://docs.pingidentity.com/sdks/latest/sdks/index.html
