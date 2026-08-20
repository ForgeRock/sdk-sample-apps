<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

# Passkeys Sample App using Swift/SwiftUI

Ping provides these iOS samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

### Integrate with PingAM/AIC using Journeys and Passkeys:

An example iOS project written in Swift/SwiftUI using the Ping iOS SDK, showcasing how to protect an application using Journeys and Passkeys. Based on the ["Set up passwordless authentication with Passkeys"](https://docs.pingidentity.com/sdks/latest/sdks/use-cases/how-to-go-passwordless-with-passkeys.html) blog post.

## Requirements

- Xcode: Latest version recommended
- iOS 18.0 or higher
- A physical iOS device or simulator
- PingAM/AIC server configured with the following journeys:
  - `Login` — standard username and password authentication
  - `BlogWebAuthnRegistration` — passkey registration
  - `BlogWebAuthnAuthentication` — passkey-based sign-in

## Getting Started

To try out this sample, perform the following steps:

1. Configure Ping Services  
   Ensure you have a PingAM/AIC server set up with the required authentication journeys and an OAuth 2.0 application for native mobile apps. See the [documentation](https://docs.pingidentity.com/sdks/latest/sdks/serverconfiguration/pingone/create-oauth2-client.html) for details.

2. Clone this repo:

    ```
    git clone https://github.com/ForgeRock/sdk-sample-apps.git
    ```

3. Open the workspace in Xcode:

    ```
    open iOS/swiftui-journey-module-passkeys/PasskeysSwiftUI/PasskeysSwiftUI.xcworkspace
    ```

4. Open `PasskeysSwiftUI/Config/AppConfiguration.swift` and update `ServerConfig` with your environment values:

    ```swift
    static let serverUrl        = "https://your-server.example.com/am"
    static let realm            = "alpha"
    static let cookieName       = "your-cookie-name"
    static let clientId         = "your-client-id"
    static let redirectUri      = "yourapp://callback"
    static let discoveryEndpoint = "https://your-server.example.com/am/oauth2/alpha/.well-known/openid-configuration"
    ```

5. Update the Associated Domains entitlement in `Config/PasskeysSwiftUI.entitlements` to match your server domain (required for the WebAuthn relying party ID):

    ```xml
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>webcredentials:your-server.example.com</string>
        <string>webcredentials:your-server.example.com?mode=develop</string>
    </array>
    ```

6. Build and run the app on a physical iOS device.

## Features

This sample demonstrates:

- Journey-based authentication with callback handling (username/password)
- FIDO2/WebAuthn passkey registration via `FidoRegistrationCallback`
- FIDO2/WebAuthn passkey authentication via `FidoAuthenticationCallback`
- Conditional login flow — automatically uses passkey sign-in when a passkey is registered
- Session management and sign-out via the Journey SDK
- OIDC user info display after successful authentication

## Additional Resources

- Ping SDK Documentation: https://docs.pingidentity.com/sdks/latest/sdks/index.html
- Passwordless with Passkeys blog: https://docs.pingidentity.com/sdks/latest/sdks/use-cases/how-to-go-passwordless-with-passkeys.html
