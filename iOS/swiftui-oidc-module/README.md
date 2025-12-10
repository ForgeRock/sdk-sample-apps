![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)

# SwiftUI OIDC Module Sample Application 

A comprehensive iOS sample application demonstrating browser-based OIDC (OpenID Connect) authentication using the Ping iOS SDK's OIDC Module and `OidcWeb.createOidcWeb` API.

## Overview

This sample application showcases how to implement centralized, browser-based authentication using the **PingOidc** module. Unlike embedded authentication flows, this approach redirects users to a browser-based login experience, allowing them to authenticate through a centralized identity provider such as PingOne, PingFederate, or PingAM.

### Key Features

- Browser-based OIDC authentication using ASWebAuthenticationSession
- OAuth 2.0/OIDC authorization code flow with PKCE
- Access token management and refresh
- User profile information retrieval
- Secure logout with session termination
- Clean MVVM architecture with SwiftUI

### Authentication Flow

This sample implements the **OIDC (Redirect) Login** deployment model:
- Users are redirected to a browser for authentication
- Centralized login experience using hosted pages or Login Widget
- OAuth 2.0 tokens are securely exchanged and stored
- Session management handled by the SDK

## Architecture

### Project Structure

```
OidcExample/
├── OidcExampleApp.swift              # App entry point
├── ContentView.swift                 # Main navigation view
├── ViewModels/
│   ├── OidcLoginViewModel.swift      # OIDC authentication logic
│   ├── AccessTokenViewModel.swift    # Token management
│   ├── UserInfoViewModel.swift       # User profile data
│   └── LogoutViewModel.swift         # Logout functionality
└── Views/
    ├── OidcLoginView.swift           # Login UI
    ├── AccessTokenView.swift         # Token display
    ├── UserInfoView.swift            # User profile display
    └── LogoutView.swift              # Logout UI
```

### Key Components

#### OidcLoginViewModel.swift
The core configuration file that initializes the OIDC Web instance using `OidcWeb.createOidcWeb`:

```swift
public let oidcLogin = OidcWeb.createOidcWeb { config in
    config.browserMode = .login
    config.browserType = .authSession
    config.logger = LogManager.standard

    config.module(PingOidc.OidcModule.config) { oidcValue in
        oidcValue.clientId = "your-client-id"
        oidcValue.scopes = Set(["openid", "profile", "email"])
        oidcValue.redirectUri = "your-redirect-uri"
        oidcValue.discoveryEndpoint = "your-discovery-endpoint"
    }
}
```

**Configuration Parameters:**
- `browserMode`: Set to `.login` for authentication flows
- `browserType`: Set to `.authSession` to use ASWebAuthenticationSession
- `module(PingOidc.OidcModule.config)`: Configures OIDC-specific settings
- `scopes`: **Must be `Set<String>`**, not `[String]` array
- `discoveryEndpoint`: OIDC discovery URL (e.g., `https://auth.pingone.com/{envId}/as/.well-known/openid-configuration`)

#### Navigation Flow

1. **ContentView**: Main navigation hub with options for:
   - Launch OIDC Login
   - View Access Token
   - View User Info
   - Logout

2. **OidcLoginView**: Initiates the authentication flow by calling:
   ```swift
   let result = try await oidcLogin.authorize { options in
       // Optional: Add additional parameters
   }
   ```

3. **Post-Authentication Views**:
   - **AccessTokenView**: Displays the OAuth access token
   - **UserInfoView**: Shows user profile data from the /userinfo endpoint
   - **LogoutView**: Terminates the session

## Dependencies

The application uses the following Ping iOS SDK modules (version 1.3.1):

- **PingOrchestrate**: Core orchestration framework
- **PingOidc**: OIDC authentication capabilities
- **PingBrowser**: Browser-based authentication support
- **PingLogger**: Logging utilities
- **PingStorage**: Secure token storage
- **PingProtect**: (Optional) Device risk signals

Dependencies are managed via Swift Package Manager. See [OidcExample.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved](OidcExample.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved) for exact versions.

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 15.0 or later
- Swift 5.9 or later
- A configured OAuth 2.0 client in PingOne, PingFederate, or PingAM

### OAuth 2.0 Client Configuration

Before running the sample, configure your OAuth 2.0 client with:

1. **Redirect URI**: Must match the URI in your client configuration
   - Example: `com.example.oidcapp://callback`
   - Must be registered in your OAuth provider

2. **Grant Types**: Authorization Code

3. **Response Types**: `code`

4. **Scopes**: At minimum `openid`, optionally `profile`, `email`, `address`, `phone`

5. **PKCE**: Enabled (required for mobile apps)

### Installation Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-org/sdk-sample-apps.git
   cd sdk-sample-apps/iOS/swiftui-oidc-module
   ```

2. **Open the project**:
   ```bash
   open OidcExample.xcodeproj
   ```
   **Important**: Always open `.xcodeproj` for this sample (no workspace needed).

3. **Configure OAuth settings** in [OidcExample/ViewModels/OidcLoginViewModel.swift](OidcExample/ViewModels/OidcLoginViewModel.swift):
   ```swift
   config.module(PingOidc.OidcModule.config) { oidcValue in
       oidcValue.clientId = "your-client-id"
       oidcValue.scopes = Set(["openid", "profile", "email"])
       oidcValue.redirectUri = "com.yourapp://callback"
       oidcValue.discoveryEndpoint = "https://auth.pingone.com/{envId}/as/.well-known/openid-configuration"
   }
   ```

4. **Update URL Scheme** in Xcode:
   - Select the project in Project Navigator
   - Go to **Info** tab
   - Expand **URL Types**
   - Add a new URL Scheme matching your redirect URI scheme (e.g., `com.yourapp`)

5. **Build and run** on a simulator or physical device

## Understanding OidcWeb.createOidcWeb

### What is OidcWeb?

`OidcWeb` is the primary interface for implementing browser-based OIDC authentication in iOS applications using the Ping iOS SDK. It handles:
- OAuth 2.0 authorization code flow with PKCE
- Browser session management
- Token acquisition, storage, and refresh
- User profile retrieval
- Secure logout

### Creating an OidcWeb Instance

The `OidcWeb.createOidcWeb` method creates a configured OIDC client:

```swift
public let oidcLogin = OidcWeb.createOidcWeb { config in
    // Browser configuration
    config.browserMode = .login        // Use for authentication
    config.browserType = .authSession  // ASWebAuthenticationSession
    config.logger = LogManager.standard

    // OIDC-specific configuration
    config.module(PingOidc.OidcModule.config) { oidcValue in
        oidcValue.clientId = "your-client-id"
        oidcValue.scopes = Set(["openid", "profile", "email"])
        oidcValue.redirectUri = "your-redirect-uri"
        oidcValue.discoveryEndpoint = "your-discovery-endpoint"
        // Optional: Authentication Context Class Reference
        // oidcValue.acrValues = "acr_value"
    }
}
```

**Key Configuration Options:**

| Property | Description | Required |
|----------|-------------|----------|
| `browserMode` | Set to `.login` for authentication | Yes |
| `browserType` | `.authSession` uses ASWebAuthenticationSession | Yes |
| `clientId` | OAuth 2.0 client identifier | Yes |
| `scopes` | **Must be `Set<String>`** - OAuth scopes | Yes |
| `redirectUri` | Registered redirect URI for your app | Yes |
| `discoveryEndpoint` | OIDC discovery URL | Yes |
| `acrValues` | (Optional) Authentication context class reference | No |
| `logger` | (Optional) Logging instance | No |

### Initiating Authentication

Start the OIDC flow by calling the `authorize` method:

```swift
let result = try await oidcLogin.authorize { options in
    // Optional: Add custom parameters to the authorization request
    // options.additionalParameters = ["login_hint": "user@example.com"]
}
```

The SDK will:
1. Generate PKCE code challenge and verifier
2. Build the authorization URL with required parameters
3. Open the authorization URL in ASWebAuthenticationSession
4. Handle the callback and exchange the authorization code for tokens
5. Return a `Result<User, OidcError>` with the authenticated user

### Accessing User Data

After successful authentication, you can access user information:

**Get the Access Token:**
```swift
let token = await oidcLogin.user()?.token()
switch token {
case .success(let accessToken):
    print("Access Token: \(accessToken)")
case .failure(let error):
    print("Error: \(error)")
case .none:
    print("No active session")
}
```

**Get User Profile:**
```swift
let userInfo = await oidcLogin.user()?.userinfo(cache: false)
switch userInfo {
case .success(let userInfoDictionary):
    print("User Info: \(userInfoDictionary)")
case .failure(let error):
    print("Error: \(error)")
case .none:
    print("No active session")
}
```

### Logging Out

End the user session:

```swift
await oidcLogin.user()?.logout()
```

This will:
- Revoke tokens with the authorization server
- Clear locally stored session data
- (Optional) Open browser for server-side logout if configured

## Important Conventions

### Critical iOS SDK Patterns

1. **Scopes Must Be `Set<String>`**
   ```swift
   // Correct
   oidcValue.scopes = Set(["openid", "profile", "email"])

   // Wrong - will cause compilation error
   oidcValue.scopes = ["openid", "profile", "email"]
   ```

2. **Use `PingOidc.OidcModule.config` for OIDC Web**
   ```swift
   // Correct - for OidcWeb
   config.module(PingOidc.OidcModule.config) { oidcValue in
       // Configuration
   }

   // Wrong - this is for DaVinci flows
   config.module(PingDavinci.OidcModule.config) { oidcValue in
       // Configuration
   }
   ```

3. **Instance Naming Convention**
   - Use camelCase: `oidcLogin`, never `oidc_login` or `OidcLogin`
   - ViewModels: Suffix with `ViewModel` (e.g., `OidcLoginViewModel`)

4. **Import Order**
   ```swift
   import Foundation
   import PingOrchestrate
   import PingOidc
   import PingBrowser
   import PingLogger
   import SwiftUI
   ```

## Testing

### Simulator Testing
- Most functionality works in iOS Simulator
- Browser-based login fully supported

### Physical Device Testing
Physical device **required** for:
- Testing with corporate VPN or restrictive network policies
- Production-like environment testing
- App Store submission preparation

### Testing Checklist

- [ ] Successful login with valid credentials
- [ ] Error handling for invalid credentials
- [ ] Access token retrieval and display
- [ ] User info retrieval from /userinfo endpoint
- [ ] Logout functionality
- [ ] Token refresh (if refresh tokens enabled)
- [ ] Proper URL scheme handling

## Troubleshooting

### Common Issues

**Issue**: "Invalid redirect URI" error during login
**Solution**:
- Verify the redirect URI in [OidcLoginViewModel.swift:34](OidcExample/ViewModels/OidcLoginViewModel.swift#L34) matches exactly with your OAuth client configuration
- Ensure the URL scheme is registered in Xcode Info.plist

**Issue**: "Type `[String]` cannot be assigned to `Set<String>`"
**Solution**: Scopes must be a `Set`, not an array:
```swift
oidcValue.scopes = Set(["openid", "profile"])
```

**Issue**: Browser doesn't open or shows blank page
**Solution**:
- Verify your discovery endpoint is accessible
- Check that `browserType = .authSession` is set
- Ensure your OAuth client allows the configured redirect URI

**Issue**: "No user session found" error
**Solution**: Complete the login flow in [OidcLoginView.swift](OidcExample/Views/OidcLoginView.swift) before accessing token or user info views

**Issue**: Build fails with "Cannot find 'PingOidc' in scope"
**Solution**:
- Go to **File > Packages > Resolve Package Versions**
- Clean build folder: **Product > Clean Build Folder**
- Restart Xcode

## Comparison with Other Authentication Methods

### OIDC Web vs. DaVinci Embedded

| Feature | OIDC Web (This Sample) | DaVinci Embedded |
|---------|----------------------|------------------|
| Login UI | Browser-based (centralized) | Native app UI |
| Configuration | `OidcWeb.createOidcWeb` | `DaVinci.createDaVinci` |
| Module | `PingOidc.OidcModule.config` | `PingDavinci.OidcModule.config` |
| Flow Control | OAuth provider | DaVinci orchestration |
| Customization | Limited (provider's UI) | Full control |
| SSO Support | Native browser SSO | App-specific |
| Use Case | Centralized identity, SSO | Custom UX, embedded flows |

## Additional Resources

- [Ping Identity iOS SDK Documentation](https://docs.pingidentity.com/sdks)
- [OIDC Specification](https://openid.net/specs/openid-connect-core-1_0.html)
- [OAuth 2.0 for Native Apps (RFC 8252)](https://tools.ietf.org/html/rfc8252)
- [Ping iOS SDK GitHub Repository](https://github.com/ForgeRock/ping-ios-sdk)

## Server Configuration

### PingOne Configuration
1. Create an OAuth 2.0 application in PingOne
2. Set application type to **Native**
3. Add your redirect URI (e.g., `com.example.oidcapp://callback`)
4. Enable **Authorization Code** grant type
5. Note your discovery endpoint: `https://auth.pingone.com/{envId}/as/.well-known/openid-configuration`

### PingFederate Configuration
1. Create an OAuth client in PingFederate
2. Set client type to **Public**
3. Enable **Authorization Code** grant type
4. Require PKCE
5. Add redirect URI
6. Note your discovery endpoint: `https://your-pf-server.com/{instance}/.well-known/openid-configuration`

### PingAM Configuration
1. Create an OAuth 2.0 client in PingAM/Advanced Identity Cloud
2. Set client type to **Public**
3. Add redirect URI
4. Enable **Authorization Code** grant type
5. Note your discovery endpoint: `https://your-tenant.forgeblocks.com/am/oauth2/.well-known/openid-configuration`

## Security Considerations

- **PKCE**: The SDK automatically implements PKCE (Proof Key for Code Exchange) for enhanced security
- **Token Storage**: Tokens are securely stored using the iOS Keychain via PingStorage module
- **Redirect URI Validation**: Always validate that redirect URIs match exactly between app and server configuration
- **State Parameter**: The SDK automatically generates and validates state parameters to prevent CSRF attacks

## License

This sample application is provided under the MIT License. See the LICENSE file for details.

Copyright (c) 2025 Ping Identity Corporation. All rights reserved.

## Disclaimer

This is a sample application provided "as is" for demonstration purposes only. It is not an official product of Ping Identity and should not be used in production without proper security review and testing.

## Support

For issues related to:
- **This sample application**: Open an issue in the [sdk-sample-apps repository](https://github.com/your-org/sdk-sample-apps/issues)
- **Ping iOS SDK**: Open an issue in the [ping-ios-sdk repository](https://github.com/ForgeRock/ping-ios-sdk/issues)
- **Ping Identity products**: Contact [Ping Identity Support](https://support.pingidentity.com)
