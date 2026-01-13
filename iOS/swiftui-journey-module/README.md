<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

# Journey Module app using Swift/SwiftUI

Ping provides these iOS samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

### Integrate with PingAM/AIC Journey Module:

- An example iOS project written in Swift/SwiftUI making use of the SDK. The sample supports journey-based authentication flows with PingAM/AIC, including advanced features like device binding, FIDO authentication, external IdP integration, and PingOne Protect.

## Requirements

- Xcode: Latest version recommended
- PingAM/AIC server with configured authentication journeys
- iOS 16.6 or higher

## Getting Started

To try out the Journey Module iOS SDK sample, perform these steps:
1. Configure Ping Services
   Ensure that you have a PingAM/AIC server configured with authentication journeys and an OAuth 2.0 application for native mobile apps. More details in this [documentation](https://backstage.forgerock.com/docs/sdks/latest/sdks/serverconfiguration/pingone/create-oauth2-client.html).

2. Clone this repo:

    ```
    git clone https://github.com/ForgeRock/sdk-sample-apps.git
    ```
3. Open the iOS sample project(swiftui-journey-module) in [Xcode](https://developer.apple.com/xcode/).
4. Open the `JourneyViewModel.swift` file within the project.
5. Locate the TODO and replace the placeholder strings with your server configuration:
   - `serverUrl`: Your PingAM/AIC server URL
   - `realm`: Your authentication realm
   - `cookie`: Your session cookie name
   - OAuth 2.0 client details in the `PingJourney.OidcModule.config` section
6. Launch the app on an iOS Device or a Simulator.

## Features

This sample demonstrates:
- Journey-based authentication with callback handling
- Device binding and biometric authentication
- FIDO2/WebAuthn registration and authentication
- External identity provider integration (Google, Facebook)
- PingOne Protect device risk assessment
- Multi-user support with isolated storage
- Session management and token handling

## Additional Resources
Ping SDK Documentation: https://docs.pingidentity.com/sdks/latest/sdks/index.html
