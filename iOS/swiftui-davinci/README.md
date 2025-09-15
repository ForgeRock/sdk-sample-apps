<p align="center">
  <a href="https://github.com/ForgeRock/sdk-sample-apps">
    <img src="https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg" alt="Ping Identity Logo">
  </a>
  <hr/>
</p>

# DaVinci app using Swift/SwiftUI

Ping provides these iOS samples to help demonstrate SDK functionality/implementation. They are provided "as is" and are not official products of Ping and are not officially supported.

### Dual Authentication Options:

This sample app demonstrates two authentication approaches:

1. **PingOne DaVinci Flow**: Complete orchestrated authentication journey with custom flows
2. **OIDC Direct Login**: Standard OIDC/OAuth 2.0 authentication flow

- An example iOS project written in Swift/SwiftUI making use of the Ping SDK. The sample supports both DaVinci orchestrated flows and direct OIDC authentication.

## Requirements

- Xcode: Latest version recommended
- PingOne DaVinci (for DaVinci flows)
- PingOne OIDC Application (for OIDC flows)
- iOS 16.6 or higher

## Authentication Flows

### DaVinci Flow
The DaVinci flow provides orchestrated authentication with custom journeys, multi-factor authentication, and complex business logic. This flow is ideal for:
- Custom authentication experiences
- Multi-step authentication processes
- Integration with external identity providers
- Complex policy enforcement

### OIDC Login Flow
The OIDC login flow provides standard OAuth 2.0/OIDC authentication. This flow is ideal for:
- Simple username/password authentication
- Standard OAuth 2.0 compliance
- Quick integration with existing OIDC providers
- Minimal setup requirements

## Getting Started

To try out the iOS SDK sample with dual authentication support, perform these steps:

### 1. Configure Ping Services
Ensure that you registered an OAuth 2.0 application for native mobile apps in PingOne. More details in this [documentation](https://backstage.forgerock.com/docs/sdks/latest/sdks/serverconfiguration/pingone/create-oauth2-client.html).

### 2. Clone this repo:

```
git clone https://github.com/ForgeRock/sdk-sample-apps.git
```

### 3. Open the iOS sample project
Open the iOS sample project (swiftui-davinci) in [Xcode](https://developer.apple.com/xcode/).

### 4. Configure OAuth 2.0 Settings

#### For DaVinci Flow:
Update the configuration in `DavinciViewModel.swift`:
```swift
public let daVinci = DaVinci.createDaVinci { config in
    config.module(PingDavinci.OidcModule.config) { oidcValue in
        oidcValue.clientId = "<#CLIENT_ID#>"
        oidcValue.scopes = Set(["openid", "email", "address", "phone", "profile"])
        oidcValue.redirectUri = "<#REDIRECT_URI#>"
        oidcValue.acrValues = "<#ACR_VALUES#>"
        oidcValue.discoveryEndpoint = "<#DISCOVERY_ENDPOINT#>"
    }
}
```

#### For OIDC Login Flow:
Update the configuration in `OidcLoginViewModel.swift`:
```swift
public let oidcLogin = OidcWeb.createOidcWeb { config in
    config.module(PingOidc.OidcModule.config) { oidcValue in
        oidcValue.clientId = "<#CLIENT_ID#>"
        oidcValue.scopes = Set(["openid", "email", "address", "phone", "profile"])
        oidcValue.redirectUri = "<#REDIRECT_URI#>"
        oidcValue.acrValues = "<#ACR_VALUES#>"
        oidcValue.discoveryEndpoint = "<#DISCOVERY_ENDPOINT#>"
    }
}
```

### 5. Replace Placeholder Values
Replace the placeholder values with your registered OAuth 2.0 application details:
- `<#CLIENT_ID#>`: Your PingOne application client ID
- `<#REDIRECT_URI#>`: Your configured redirect URI (e.g., `com.yourcompany.yourapp://oauth2redirect`)
- `<#ACR_VALUES#>`: Your DaVinci flow policy ID (for DaVinci flow)
- `<#DISCOVERY_ENDPOINT#>`: Your PingOne discovery endpoint URL

### 6. Launch the Application
Launch the app on an iOS Device or a Simulator and choose your authentication method:
- **"Launch DaVinci"**: Experience the full DaVinci orchestrated flow
- **"Launch OIDC Login"**: Use direct OIDC authentication

## Features

### Dual Authentication Support
- **Unified User Management**: Both flows integrate seamlessly, allowing users to authenticate via either method
- **Token Management**: Access tokens and user information from either authentication source
- **Consistent Logout**: Proper logout handling for both authentication types

### ViewModels Included
- `DavinciViewModel.swift`: Manages DaVinci orchestrated flows
- `OidcLoginViewModel.swift`: Handles direct OIDC authentication
- `AccessTokenViewModel.swift`: Retrieves access tokens from either authentication source
- `UserInfoViewModel.swift`: Fetches user information from either authentication source
- `LogOutViewModel.swift`: Handles logout for both authentication types

## Additional Resources
Ping SDK Documentation: https://docs.pingidentity.com/sdks/latest/sdks/index.html
