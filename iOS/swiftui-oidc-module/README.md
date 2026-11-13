![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)

# SwiftUI OIDC Module Sample Application 

A comprehensive iOS sample application demonstrating browser-based OIDC (OpenID Connect) authentication and Rich Authorization Requests (RFC 9396) using the Ping iOS SDK's OIDC Module and `OidcWebClient.createOidcWebClient` API.

## Overview

This sample application showcases how to implement centralized, browser-based authentication using the **PingOidc** module. Unlike embedded authentication flows, this approach redirects users to a browser-based login experience, allowing them to authenticate through a centralized identity provider such as PingOne, PingFederate, or PingAM.

### Key Features

- Browser-based OIDC authentication using ASWebAuthenticationSession
- OAuth 2.0/OIDC authorization code flow with PKCE
- Rich Authorization Requests (RFC 9396): a dedicated login screen with editable `authorization_details` JSON and presets
- Pushed Authorization Requests (RFC 9126, PAR) toggle, sent through the typed `authorizationDetails` path
- "Granted Authorization Details" card showing the `authorization_details` the server granted for a token
- Separate Keychain storage for the RAR token, so the standard and RAR tokens coexist and are revoked independently
- Readable messages for the deny path (`access_denied`), `invalid_authorization_details`, and other OAuth errors
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
├── Configuration/
│   └── RarClientStore.swift          # The dedicated RAR client, its options and its storage account
├── Models/
│   ├── RarJson.swift                 # authorization_details JSON parsing and presets
│   └── OidcError+Display.swift       # Readable messages for OAuth and browser errors
├── ViewModels/
│   ├── OidcLoginViewModel.swift      # Shared client factory and OIDC authentication logic
│   ├── RarLoginViewModel.swift       # RAR login logic: presets, validation, PAR and delivery
│   ├── AccessTokenViewModel.swift    # Token management for the standard and RAR tokens
│   ├── UserInfoViewModel.swift       # User profile data
│   └── LogoutViewModel.swift         # Logout functionality
└── Views/
    ├── OidcLoginView.swift           # Login UI
    ├── RarLoginView.swift            # RAR login UI: JSON editor, PAR toggle, delivery picker
    ├── AccessTokenView.swift         # Token display for the standard and RAR tokens
    ├── AuthorizationDetailsCard.swift # "Granted Authorization Details" card
    ├── UserInfoView.swift            # User profile display
    └── LogoutView.swift              # Logout UI
```

### Key Components

#### OidcLoginViewModel.swift
The core configuration file. The top-level `makeOidcWebClient(overrides:)` factory holds the settings shared by every client in the sample, and each client calls it with its own overrides:

```swift
nonisolated func makeOidcWebClient(overrides: @escaping @Sendable (OidcClientConfig) -> Void = { _ in }) -> OidcWebClient {
    OidcWebClient.createOidcWebClient { config in
        config.browserMode = .login
        config.browserType = .authSession
        config.logger = LogManager.standard

        config.module(PingOidc.OidcModule.config) { oidcValue in
            oidcValue.clientId = <#"Client ID"#>
            oidcValue.scopes = Set([<#"openid"#>, <#"profile"#>, <#"email"#>])
            oidcValue.redirectUri = <#"Redirect URI"#>
            oidcValue.discoveryEndpoint = <#"Discovery Endpoint"#>
            overrides(oidcValue)
        }
    }
}

public let oidcLogin = makeOidcWebClient()
```

**Configuration Parameters:**
- `makeOidcWebClient(overrides:)`: Builds a new client per call; the `overrides` closure runs last so a client can adjust individual settings (for example its token storage) without repeating the shared ones
- `browserMode`: Set to `.login` for authentication flows
- `browserType`: Set to `.authSession` to use ASWebAuthenticationSession
- `module(PingOidc.OidcModule.config)`: Configures OIDC-specific settings
- `scopes`: **Must be `Set<String>`**, not `[String]` array
- `discoveryEndpoint`: OIDC discovery URL (e.g., `https://auth.pingone.com/{envId}/as/.well-known/openid-configuration`)

#### RarClientStore.swift
The client used for Rich Authorization Requests. `RarClientStore` builds it through the same factory with a `KeychainStorage` under the dedicated `ACCESS_TOKEN_STORAGE_RAR` account, and `apply(_:)` rebuilds it when `par` or the config-level `authorizationDetails` change. See [Rich Authorization Requests (RFC 9396)](#rich-authorization-requests-rfc-9396).

#### Navigation Flow

1. **ContentView**: Main navigation hub with sections for:
   - Authentication: Launch OIDC Login
   - User Data: Access Token, User Info
   - Rich Authorization Requests: Launch RAR Login, RAR Access Token
   - Session Management: Logout

2. **OidcLoginView**: Initiates the authentication flow by calling:
   ```swift
   let result = try await oidcLogin.authorize { options in
       // Optional: Add additional parameters
   }
   ```

3. **RarLoginView**: Edits the `authorization_details` JSON, picks a preset, the delivery path, and PAR, then logs in through the dedicated RAR client. On success it shows a confirmation with a button that opens the RAR Access Token screen.

4. **Post-Authentication Views**:
   - **AccessTokenView**: Displays the OAuth access token; the RAR variant adds the "Granted Authorization Details" card and a "Revoke RAR Token" button
   - **UserInfoView**: Shows user profile data from the /userinfo endpoint
   - **LogoutView**: Terminates the session

## Dependencies

The application resolves the [Ping iOS SDK](https://github.com/ForgeRock/ping-ios-sdk) from its `develop` branch rather than a tagged release. The Rich Authorization Requests (RFC 9396) APIs it uses (`AuthorizationDetail`, `OidcOptions.authorizationDetails`, `Token.authorizationDetails` and `OAuthAuthorizationError`) are not available in a tagged release yet. It uses the following SDK modules:

- **PingOrchestrate**: Core orchestration framework
- **PingOidc**: OIDC authentication capabilities
- **PingBrowser**: Browser-based authentication support
- **PingLogger**: Logging utilities
- **PingStorage**: Secure token storage
- **PingProtect**: (Optional) Device risk signals

Dependencies are managed via Swift Package Manager. The exact `ping-ios-sdk` revision that `develop` resolved to, along with all other pinned versions, is recorded in [OidcExample.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved](OidcExample.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved).

## Getting Started

### Prerequisites

- Xcode 26 or later (the sample uses Swift language features that need the Swift 6.1 compiler bundled with recent Xcode releases)
- iOS 16.0 or later
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

3. **Configure OAuth settings** in [OidcExample/ViewModels/OidcLoginViewModel.swift](OidcExample/ViewModels/OidcLoginViewModel.swift) by replacing the editor placeholders in `makeOidcWebClient(overrides:)`:
   ```swift
   oidcValue.clientId = "your-client-id"
   oidcValue.scopes = Set(["openid", "profile", "email"])
   oidcValue.redirectUri = "com.yourapp://callback"
   oidcValue.discoveryEndpoint = "https://auth.pingone.com/{envId}/as/.well-known/openid-configuration"
   ```

4. **Update URL Scheme** in Xcode:
   - Select the project in Project Navigator
   - Go to **Info** tab
   - Expand **URL Types**
   - Add a new URL Scheme matching your redirect URI scheme (e.g., `com.yourapp`)

5. **Build and run** on a simulator or physical device

## Understanding OidcWebClient.createOidcWebClient

### What is OidcWebClient?

`OidcWebClient` is the primary interface for implementing browser-based OIDC authentication in iOS applications using the Ping iOS SDK. It handles:
- OAuth 2.0 authorization code flow with PKCE
- Browser session management
- Token acquisition, storage, and refresh
- User profile retrieval
- Secure logout

### Creating an OidcWebClient Instance

The `OidcWebClient.createOidcWebClient` method creates a configured OIDC client. The sample wraps it in the `makeOidcWebClient(overrides:)` factory so every client shares the same settings:

```swift
nonisolated func makeOidcWebClient(overrides: @escaping @Sendable (OidcClientConfig) -> Void = { _ in }) -> OidcWebClient {
    OidcWebClient.createOidcWebClient { config in
        // Browser configuration
        config.browserMode = .login        // Use for authentication
        config.browserType = .authSession  // ASWebAuthenticationSession
        config.logger = LogManager.standard

        // OIDC-specific configuration
        config.module(PingOidc.OidcModule.config) { oidcValue in
            oidcValue.clientId = <#"Client ID"#>
            oidcValue.scopes = Set([<#"openid"#>, <#"profile"#>, <#"email"#>])
            oidcValue.redirectUri = <#"Redirect URI"#>
            oidcValue.discoveryEndpoint = <#"Discovery Endpoint"#>
            // Optional: Authentication Context Class Reference
            // oidcValue.acrValues = <#"ACR_VALUE"#>
            overrides(oidcValue)
        }
    }
}

// The standard client, built from the shared settings with no overrides
public let oidcLogin = makeOidcWebClient()
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
| `overrides` | (Optional) Closure applied last with the client's own `OidcClientConfig` | No |

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

## Rich Authorization Requests (RFC 9396)

[Rich Authorization Requests (RFC 9396)](https://www.rfc-editor.org/rfc/rfc9396) let a client describe what it is asking the user to approve, instead of encoding the request in flat scopes. The client sends a JSON array of `authorization_details` objects with the authorization request, and the authorization server echoes the details it actually granted back on the token response. The sample demonstrates the full round trip on the **Launch RAR Login** screen:

1. Pick a preset (`payment_initiation`, `account_information`, or a blank custom entry) or edit the `authorization_details` JSON directly. [RarJson.swift](OidcExample/Models/RarJson.swift) validates the text and reports the first problem found in plain language.
2. Choose how the details are delivered and whether PAR is on.
3. Log in through the dedicated RAR client and inspect the granted details on the **RAR Access Token** screen.

### Delivery Paths

`authorization_details` can reach the authorization server two ways; both use the SDK's typed `authorizationDetails` API:

- **Per transaction** (`OidcOptions.authorizationDetails`): the details travel with a single `authorize` call and are sent for that login only:
  ```swift
  let result = try await RarClientStore.shared.client.authorize { options in
      options.authorizationDetails = details
  }
  ```
- **Client config** (`OidcClientConfig.authorizationDetails`): the details are fixed on the client configuration and sent with every authorization made by that client.

A per-transaction value takes precedence over a config-level one. The **Delivery** picker on the RAR Login screen selects between the two.

### Pushed Authorization Requests (PAR)

With [Pushed Authorization Requests (RFC 9126)](https://www.rfc-editor.org/rfc/rfc9126), the authorization parameters are sent to the server in a POST to the discovery document's `pushed_authorization_request_endpoint` before the browser redirect, and the redirect carries only the resulting `request_uri`. The **PAR** toggle on the RAR Login screen sets `par` on the client configuration.

- Toggling PAR rebuilds the RAR client (`RarClientStore.apply(_:)`), because `par` is fixed when a client is built.
- PAR applies only when the discovery document advertises a `pushed_authorization_request_endpoint`. If it does not, the SDK silently falls back to the standard authorization flow.
- **Prefer the typed `authorizationDetails` API over query parameters.** A raw `authorization_details` entry in `OidcOptions.additionalParameters` (or `customParams`) is forwarded when no typed details are set, and the SDK routes it into the PAR body when PAR is on — but the typed value wins when both are set, and a typed entry is validated and decoded rather than passed through as an opaque string. The SDK also logs a warning when both forms are present.

### Token Storage

Every browser-based workflow keeps one token in its own storage, and **starting a new authorization revokes the token held in that client's storage and replaces it**. A RAR login therefore runs on its own client with its own `KeychainStorage` account, `ACCESS_TOKEN_STORAGE_RAR`, so:

- The RAR token and the token from the standard login coexist. Completing a RAR login revokes and replaces only the previous RAR token; the standard token stays valid, and vice versa.
- The two tokens are revoked independently: the **Access Token** screen shows the standard token, and the **RAR Access Token** screen has a **Revoke RAR Token** button that touches only the RAR slot. Logging out on the Logout screen signs out the standard session only.

### Reading the RAR Access Token Screen

The **RAR Access Token** screen shows the token plus a "Granted Authorization Details" card listing each granted object (type, locations, actions, datatypes, privileges, and type-specific fields). The screen distinguishes three outcomes:

- **Card shown**: the server processed the request as RAR and granted the listed details.
- **"The token response carried no authorization_details."**: the `authorization_details` member is absent, so the server did not process the request as a Rich Authorization Request (a server that does not support it, or one with RAR not enabled).
- **"The server returned an empty authorization_details array (no details granted)."**: RAR ran, but the consent flow granted nothing — typically the built-in example consent service, which does not echo details (see [server prerequisites](#pingam-configuration)).

### The Deny Path

When the user declines the consent screen, the authorization redirect carries `error=access_denied`. The sample maps this to **"Consent was denied. The user declined the authorization request."** rather than a raw SDK error string, alongside readable messages for `invalid_authorization_details`, `invalid_request`, and a dismissed sign-in browser (see [OidcError+Display.swift](OidcExample/Models/OidcError+Display.swift)).

### Browser Mode

The sample keeps `browserType = .authSession` (ASWebAuthenticationSession) for the RAR login. A present-only custom browser mode resolves before the consent screen completes, so it cannot observe the full RAR round trip.

### Scope

This sample covers Rich Authorization Requests on the authorization code flow with Advanced Identity Cloud and PingAM (see [PingAM Configuration](#pingam-configuration) for the server prerequisites). PingOne does not currently support the PAR-based RAR flow, and device-flow RAR and native Journey RAR are out of scope.

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
- [ ] RAR login with PAR off: the granted details appear on the RAR Access Token screen
- [ ] RAR login with PAR on (discovery advertises a PAR endpoint): the granted details still appear
- [ ] RAR login with both delivery paths (per transaction, then client config)
- [ ] Denying consent shows "Consent was denied. The user declined the authorization request." and Try Again works
- [ ] Requesting a type not listed on the OAuth client shows the `invalid_authorization_details` message
- [ ] Standard and RAR tokens coexist: log in standard, then RAR (and the reverse); each token stays valid
- [ ] Revoke RAR Token clears only the RAR token; the standard token is unaffected

## Troubleshooting

### Common Issues

**Issue**: "Invalid redirect URI" error during login
**Solution**:
- Verify the redirect URI in [OidcLoginViewModel.swift:38](OidcExample/ViewModels/OidcLoginViewModel.swift#L38) matches exactly with your OAuth client configuration
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
**Solution**: Complete the login flow in [OidcLoginView.swift](OidcExample/Views/OidcLoginView.swift) before accessing token or user info views. Before any login the token screens may instead show an authorization error from the SDK ("No AuthCode is available") — the same fix applies: log in first.

**Issue**: Build fails with "Cannot find 'PingOidc' in scope"
**Solution**:
- Go to **File > Packages > Resolve Package Versions**
- Clean build folder: **Product > Clean Build Folder**
- Restart Xcode

**Issue**: The "Granted Authorization Details" card never appears on the RAR Access Token screen
**Solution**:
- If the screen says the token response carried no `authorization_details`, RAR processing was skipped. Check that Remote Consent and "Enable Rich Authorization Requests with Remote Consent Service" are both on for the OAuth 2.0 provider (see [PingAM Configuration](#pingam-configuration)) — with either off, the server silently ignores `authorization_details`
- If the screen says the server returned an empty array, RAR ran but consent granted nothing. The built-in example consent service does not return `authorization_details`; use a custom Remote Consent Service that echoes the granted details
- Check the Advanced Identity Cloud release: RAR with Remote Consent requires release 23604.0 or later

**Issue**: "The server rejected the authorization_details" (`invalid_authorization_details`)
**Solution**: Every `type` requested must be listed under **Authorization Detail Type(s)** on the OAuth 2.0 client. An unlisted type is rejected with `invalid_authorization_details`.

**Issue**: "The server rejected the authorization request" (`invalid_request`) during a RAR login
**Solution**: Common causes are **Implied Consent** enabled on the OAuth 2.0 client (implied consent rejects `authorization_details` with `invalid_request`; turn it off and use the Remote Consent Service flow) and no Remote Consent Service configured on the flow while RAR is enabled.

**Issue**: PAR is on but the flow behaves the same as with PAR off
**Solution**:
- Check that the discovery document advertises a `pushed_authorization_request_endpoint`. Without it, the SDK silently falls back to the standard authorization flow
- Confirm the details are sent through the typed `authorizationDetails` API. A raw `authorization_details` entry in `OidcOptions.additionalParameters` or `customParams` is forwarded only when no typed details are set, and the typed value wins when both are present

## Comparison with Other Authentication Methods

### OIDC Web vs. DaVinci Embedded

| Feature | OIDC Web (This Sample) | DaVinci Embedded |
|---------|----------------------|------------------|
| Login UI | Browser-based (centralized) | Native app UI |
| Configuration | `OidcWebClient.createOidcWebClient` | `DaVinci.createDaVinci` |
| Module | `PingOidc.OidcModule.config` | `PingDavinci.OidcModule.config` |
| Flow Control | OAuth provider | DaVinci orchestration |
| Customization | Limited (provider's UI) | Full control |
| SSO Support | Native browser SSO | App-specific |
| Use Case | Centralized identity, SSO | Custom UX, embedded flows |

## Additional Resources

- [Ping Identity iOS SDK Documentation](https://docs.pingidentity.com/sdks)
- [OIDC Specification](https://openid.net/specs/openid-connect-core-1_0.html)
- [OAuth 2.0 for Native Apps (RFC 8252)](https://tools.ietf.org/html/rfc8252)
- [Rich Authorization Requests (RFC 9396)](https://www.rfc-editor.org/rfc/rfc9396)
- [Pushed Authorization Requests (RFC 9126)](https://www.rfc-editor.org/rfc/rfc9126)
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

#### Rich Authorization Requests Prerequisites

The RAR login in this sample runs against PingAM/Advanced Identity Cloud with the following configuration. On Advanced Identity Cloud, release 23604.0 or later is required for the granted details to be issued.

1. **OAuth 2.0 provider**: Enable **Remote Consent** and **Enable Rich Authorization Requests with Remote Consent Service**. With either setting off, the provider silently ignores `authorization_details`.
2. **OAuth 2.0 client**:
   - Grant type **Authorization Code** with PKCE (as for the standard login above)
   - List every `type` you will request under **Authorization Detail Type(s)** — a request for an unlisted type is rejected with `invalid_authorization_details`
   - Turn **Implied Consent** off — implied consent with `authorization_details` is rejected with `invalid_request`
3. **Remote Consent Service**: Enable remote consent for the flow and configure a Remote Consent Service that returns the granted `authorization_details`. The built-in example consent service does not return `authorization_details`, so a login against it completes with an empty array on the token — use a custom consent service to see populated cards on the RAR Access Token screen. The [RCS demo](../../rcs/rcs-demo/README.md) in this repository is a ready-made consent service for this purpose.

## Security Considerations

- **PKCE**: The SDK automatically implements PKCE (Proof Key for Code Exchange) for enhanced security
- **Token Storage**: Tokens are securely stored using the iOS Keychain via PingStorage module. The RAR token lives in its own Keychain account (`ACCESS_TOKEN_STORAGE_RAR`), separate from the standard token, so starting a RAR authorization cannot revoke the standard session
- **Token Revocation**: Starting an authorization revokes and replaces the token held in that client's storage. Revoke the standard and RAR tokens independently from their own token screens
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
