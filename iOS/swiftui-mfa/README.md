![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)

# SwiftUI MFA Sample Application

A comprehensive iOS sample application demonstrating Multi-Factor Authentication (MFA) using the Ping iOS SDK's OATH, Push, and Journey modules.

## Overview

This sample application showcases how to implement a full-featured MFA authenticator using the **PingOath**, **PingPush**, and **PingJourney** modules.

### Key Features

- OATH credential management (TOTP auto-refresh, HOTP manual generation)
- QR code scanning and manual entry for credential registration
- Push authentication with three notification types: Default, Biometric, and Challenge
- Journey-based login flow with automatic MFA registration via `HiddenValueCallback`
- Biometric authentication (Face ID / Touch ID) for push approval and app security
- Account grouping, reordering, editing, and deletion
- Diagnostic logs viewer for troubleshooting
- Clean MVVM architecture with a Manager layer and SwiftUI

### Authentication Flow

This sample implements embedded MFA authentication:
- OATH credentials are registered via QR code scan or manual URI entry
- TOTP codes auto-refresh; HOTP codes are generated on demand
- Push notifications are delivered via APNs and approved/denied in-app
- Journey flows handle server-side authentication and trigger MFA registration callbacks

## Architecture

### Layer Structure

```
┌─────────────────────────────────────┐
│         Views (SwiftUI)             │  ← Presentation Layer
├─────────────────────────────────────┤
│      ViewModels (@MainActor)        │  ← Coordination Layer
├─────────────────────────────────────┤
│      Managers (SDK Wrappers)        │  ← Business Logic Layer
├─────────────────────────────────────┤
│     SDK Clients (ping-ios-sdk)      │  ← SDK Layer
└─────────────────────────────────────┘
```

### Project Structure

```
MfaSample/
├── App/
│   ├── MfaSampleApp.swift                  # App entry point
│   └── AppDelegate.swift                   # APNs registration & notification handling
├── Core/
│   ├── Configuration/
│   │   ├── AppConfiguration.swift          # SDK initialization
│   │   └── UserPreferences.swift           # UserDefaults wrapper
│   ├── Managers/
│   │   ├── OathManager.swift               # OATH SDK wrapper
│   │   ├── PushManager.swift               # Push SDK wrapper
│   │   ├── JourneyManager.swift            # Journey authentication wrapper
│   │   ├── AccountGroupingManager.swift    # Credential grouping logic
│   │   └── BiometricManager.swift          # LocalAuthentication wrapper
│   └── Services/
│       └── DiagnosticLogger.swift
├── Models/
│   ├── AccountGroup.swift                  # Main display model
│   ├── PushNotificationItem.swift
│   ├── ThemeMode.swift
│   └── AppError.swift
├── ViewModels/
│   ├── AccountsViewModel.swift             # Main screen coordinator
│   ├── QRScannerViewModel.swift
│   ├── ManualEntryViewModel.swift
│   ├── LoginViewModel.swift
│   ├── AccountDetailViewModel.swift
│   ├── PushNotificationsViewModel.swift
│   ├── NotificationResponseViewModel.swift
│   ├── SettingsViewModel.swift
│   ├── DiagnosticLogsViewModel.swift
│   ├── EditAccountsViewModel.swift
│   └── AboutViewModel.swift
└── Views/
    ├── ContentView.swift                   # Main navigation hub
    └── Screens/                            # Main screens
        ├── AccountsScreen.swift
        ├── QRScannerScreen.swift
        ├── ManualEntryScreen.swift
        ├── LoginScreen.swift
        ├── AccountDetailScreen.swift
        ├── PushNotificationsScreen.swift
        ├── NotificationResponseScreen.swift
        ├── EditAccountsScreen.swift
        ├── SettingsScreen.swift
        ├── DiagnosticLogsScreen.swift
        └── AboutScreen.swift
```

### Key Components

#### AppConfiguration.swift
Initializes both SDK clients in parallel at app startup:

```swift
func initialize() async {
    async let oathResult = Task.detached(priority: .userInitiated) {
        try await OathClient.createClient()
    }.value
    async let pushResult = Task.detached(priority: .userInitiated) {
        try await PushClient.createClient()
    }.value

    let (oathClient, pushClient) = try await (oathResult, pushResult)
    OathManager.shared.setClient(oathClient)
    PushManager.shared.setClient(pushClient)
}
```

#### OathManager.swift
Wraps `OathClient` to manage OATH credentials and code generation:

```swift
// Load all stored OATH credentials
let credentials = try await oathManager.loadCredentials()

// Add a credential from a scanned QR code URI
let credential = try await oathManager.addCredentialFromUri("otpauth://totp/...")

// Generate a TOTP/HOTP code
let code = try await oathManager.generateCode(for: credentialId)
```

#### PushManager.swift
Wraps `PushClient` for push credential and notification management:

```swift
// Register a push credential from a QR code URI
let credential = try await pushManager.addCredentialFromUri("pingone://...")

// Update device token after APNs registration
try await pushManager.setDeviceToken(deviceToken)

// Retrieve pending push notifications
let notifications = try await pushManager.getPendingNotifications()

// Approve or deny a push notification
try await pushManager.respondToNotification(notification, approved: true)
```

#### JourneyManager.swift
Wraps `Journey` to drive server-side authentication flows. Fill in the `TODO` values for your PingAM / AIC environment:

```swift
journey = Journey.createJourney { journeyConfig in
    journeyConfig.serverUrl = "https://<tenant>.forgeblocks.com/am"
    journeyConfig.realm     = "alpha"
    journeyConfig.cookie    = "iPlanetDirectoryPro"

    journeyConfig.module(PingJourney.OidcModule.config) { oidcConfig in
        oidcConfig.clientId          = "<your-client-id>"
        oidcConfig.redirectUri       = "com.example.mfasample://oauth2redirect"
        oidcConfig.discoveryEndpoint = "https://<tenant>.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration"
        oidcConfig.scopes            = ["openid", "profile", "email"]
    }
}

// Start a Journey flow (replace "Login" with your Journey tree name)
try await journeyManager.startJourney(journeyName: "Login")

// Advance to the next node after filling in callbacks
try await journeyManager.submitNode()
```

#### Navigation Flow

1. **AccountsScreen**: Home screen displaying grouped OATH and Push credentials
2. **QRScannerScreen**: Camera-based QR code scanning to register credentials
3. **ManualEntryScreen**: Form-based manual OATH credential entry
4. **LoginScreen**: Journey-based authentication flow
5. **AccountDetailScreen**: View and edit individual credential details
6. **PushNotificationsScreen**: Pending and historical push notifications
7. **NotificationResponseScreen**: Approve or deny push requests with optional biometrics
8. **EditAccountsScreen**: Reorder and delete credentials
9. **SettingsScreen**: App preferences (copy OTP on tap, biometric lock, theme, etc.)
10. **DiagnosticLogsScreen**: In-app log viewer for debugging
11. **AboutScreen**: App version and SDK information

## Dependencies

The application uses the following Ping iOS SDK modules (version: `2.0.0+`):

| Module | Purpose |
|--------|---------|
| **PingOath** | TOTP/HOTP credential management and code generation |
| **PingPush** | Push notification credential management and approval flows |
| **PingJourney** | Journey-based authentication flows and MFA registration |
| **PingOidc** | OIDC/OAuth2 token exchange after Journey authentication |
| **PingLogger** | Logging utilities |
| **PingStorage** | Secure Keychain-backed credential storage |
| **PingOrchestrate** | Core workflow orchestration (transitive dependency) |

Dependencies are managed via Swift Package Manager, pointing to `https://github.com/ForgeRock/ping-ios-sdk`.

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 16.0 or later
- Swift 6.0 or later
- A configured PingAM or PingOne Advanced Identity Cloud (AIC) environment with MFA capabilities
- An Apple Push Notification service (APNs) certificate or key for push features

### Server Configuration

#### PingAM / PingOne Advanced Identity Cloud (AIC)
1. Enable the OATH and Push authentication modules in your realm.
2. Configure the Journey (authentication tree) with an OATH Registration or Push Registration node.
3. Ensure the `HiddenValueCallback` is configured to relay the registration URI to the app.
4. Register an OAuth2/OIDC client in AM with a custom redirect URI (e.g. `com.example.mfasample://oauth2redirect`) and grant the `openid`, `profile`, and `email` scopes.

### Installation Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-org/sdk-sample-apps.git
   cd sdk-sample-apps/iOS/swiftui-mfa
   ```

2. **Open the project**:
   ```bash
   open MfaSample/MfaSample.xcodeproj
   ```

3. **Resolve Swift Package dependencies** (Xcode does this automatically on first open, or via **File > Packages > Resolve Package Versions**).

4. **Configure the Journey connection** in [MfaSample/Core/Managers/JourneyManager.swift](MfaSample/MfaSample/Core/Managers/JourneyManager.swift) by filling in the `TODO` values:

   ```swift
   journey = Journey.createJourney { journeyConfig in
       journeyConfig.serverUrl = "https://<tenant>.forgeblocks.com/am"  // TODO: your AM URL
       journeyConfig.realm     = "alpha"                                 // TODO: your realm
       journeyConfig.cookie    = "iPlanetDirectoryPro"                   // TODO: your cookie name

       journeyConfig.module(PingJourney.OidcModule.config) { oidcConfig in
           oidcConfig.clientId          = "<your-client-id>"             // TODO: OAuth2 client ID
           oidcConfig.redirectUri       = "com.example.mfasample://oauth2redirect" // TODO: redirect URI
           oidcConfig.discoveryEndpoint = "https://<tenant>.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration"
           oidcConfig.scopes            = ["openid", "profile", "email"]
       }
   }
   ```

   > **Note:** `AppConfiguration.swift` initialises the OATH and Push SDK clients only — you do not need to modify it unless you want to customise `OathClient` or `PushClient` storage/logging options.

   > **URL scheme registration:** The `redirectUri` scheme (e.g. `com.example.mfasample`) must be registered in `Info.plist` under `CFBundleURLTypes` / `CFBundleURLSchemes`, otherwise the OAuth2 redirect will not be handled by the app at runtime. In Xcode: **Target → Info → URL Types → +**, set the URL Scheme to the scheme portion of your redirect URI.

5. **Set the Journey name** in [MfaSample/ViewModels/LoginViewModel.swift](MfaSample/MfaSample/ViewModels/LoginViewModel.swift):
   ```swift
   // TODO: Replace "Login" with the name of the Journey tree on your server
   try await journeyManager.startJourney(journeyName: "Login")
   ```
   The name must match exactly (case-sensitive) the tree name configured in AM Admin > Authentication > Trees.

6. **Configure APNs** for push notifications:
   - Add your push notification entitlement in `MfaSample.entitlements`.
   - Register your APNs certificate or key in your PingAM / AIC environment.

7. **Build and run** on a physical device (recommended for push and biometric features).

## Understanding the SDK Modules

### OathClient

`OathClient` is the primary interface for OATH credential management:

```swift
// Create with default Keychain storage
let client = try await OathClient.createClient()

// Or create with custom configuration
let client = try await OathClient.createClient { config in
    config.storage = OathKeychainStorage()
    config.logger = LogManager.standard
}

// List all credentials
let credentials = try await client.getCredentials()

// Add credential from otpauth:// URI
let credential = try await client.addCredential(uri: "otpauth://totp/issuer:account?secret=BASE32SECRET&issuer=issuer")

// Generate OTP code
let codeInfo = try await client.generateCode(for: credential.id)
print("Code: \(codeInfo.code), valid for \(codeInfo.timeRemaining)s")

// Delete a credential
try await client.deleteCredential(id: credential.id)
```

### PushClient

`PushClient` manages push authentication credentials and notifications:

```swift
// Create with default configuration
let client = try await PushClient.createClient()

// Register device token with APNs
try await client.setDeviceToken(apnsToken)

// Add push credential from a registration URI
let credential = try await client.addCredential(uri: "pingone://mfa/...")

// Fetch pending notifications
let pending = try await client.getPendingNotifications()

// Respond to a notification (approve = true, deny = false)
try await client.respond(to: notification, approved: true)
```

### Journey (PingJourney)

`Journey` drives server-side authentication flows with callback handling. See `JourneyManager.swift` for the full configuration block including OIDC token exchange.

```swift
// See JourneyManager.swift for Journey.createJourney { ... } configuration

// Start a Journey flow
let node = await journey.start("Login")   // replace "Login" with your Journey tree name

switch node {
case let continueNode as ContinueNode:
    // Fill in callbacks and advance to the next node
    for callback in continueNode.callbacks {
        if let nameCallback = callback as? NameCallback {
            nameCallback.name = "username"
        }
    }
    let nextNode = await continueNode.next()

case is SuccessNode:
    print("Authentication successful")

case let failureNode as FailureNode:
    // FailureNode.cause is non-optional
    print("Failed: \(failureNode.cause.localizedDescription)")

default:
    break
}
```

## Important Conventions

### Push Notifications Require a Physical Device

APNs push notifications are not delivered to iOS Simulators. To test push authentication:
- Run the app on a **physical iOS device**
- Ensure you have a valid APNs certificate or key configured on the server
- Grant notification permissions when prompted

### OATH Works on Simulator and Device

TOTP/HOTP code generation and QR scanning work on both Simulator and physical devices, though camera access for QR scanning requires a physical device.

### Swift Concurrency and Actor Isolation

All managers use `@MainActor` for `@Published` state and `Task.detached` for SDK I/O to avoid blocking the main thread:

```swift
// Correct — offload SDK I/O to a background task
let credentials = try await Task.detached(priority: .userInitiated) {
    try await client.getCredentials()
}.value
```

### SDK Initialization

Always initialize `AppConfiguration` before accessing any manager:

```swift
// In your App or root view
.task {
    await AppConfiguration.shared.initialize()
}
```

## Testing

### Simulator Testing

The following features work in iOS Simulator:
- OATH credential management (add via manual entry, generate codes)
- Journey authentication flows to register OATH credentials
- Settings and account management UI

### Physical Device Testing

A physical device is **required** for:
- QR code scanning (camera access)
- Push notification delivery and approval
- Biometric authentication (Face ID / Touch ID)
- End-to-end MFA registration flows

### Testing Checklist

- [ ] OATH credential registration via QR scan
- [ ] OATH credential registration via manual entry
- [ ] TOTP code auto-refresh every 30 seconds
- [ ] HOTP code generation on demand
- [ ] Push credential registration via QR scan
- [ ] Push notification receipt and in-app approval/denial
- [ ] Biometric approval for push notifications
- [ ] Journey login with username/password callbacks
- [ ] MFA auto-registration via `HiddenValueCallback`
- [ ] Account grouping (OATH + Push under the same issuer)
- [ ] Credential editing and deletion
- [ ] Settings persistence across launches

## Troubleshooting

### Common Issues

**Issue**: Push notifications are not received
**Solution**:
- Verify you are running on a physical device, not a Simulator
- Confirm APNs entitlement is enabled in `MfaSample.entitlements`
- Ensure your Amazon SNS credential is correctly configured on the server
- Check that the device token is successfully registered by reviewing diagnostic logs

**Issue**: OATH code is rejected by the server
**Solution**:
- Verify the device clock is synchronized (TOTP is time-sensitive)
- Confirm the TOTP window configured on the server allows for clock drift
- Check that the correct secret was scanned or entered during registration

**Issue**: Journey authentication fails with "Configuration error"
**Solution**:
- Verify `serverUrl`, `realm`, `cookie`, `clientId`, `redirectUri`, and `discoveryEndpoint` values in [JourneyManager.swift](MfaSample/MfaSample/Core/Managers/JourneyManager.swift)
- Ensure the Journey name in [LoginViewModel.swift](MfaSample/MfaSample/ViewModels/LoginViewModel.swift) matches the tree name configured on the server (case-sensitive)
- Check network connectivity and server availability in the diagnostic logs

**Issue**: Build fails with "Cannot find 'PingOath' in scope"
**Solution**:
- Go to **File > Packages > Resolve Package Versions**
- Clean build folder: **Product > Clean Build Folder**
- Restart Xcode

**Issue**: Biometric prompt does not appear
**Solution**:
- Biometrics require a physical device with Face ID or Touch ID enrolled
- Ensure biometric lock is enabled in **Settings** within the app
- Check that the app has `NSFaceIDUsageDescription` in `Info.plist`

## Additional Resources

- [Ping Identity iOS SDK Documentation](https://docs.pingidentity.com/sdks)
- [PingOath Module README](https://github.com/ForgeRock/ping-ios-sdk/tree/main/Oath)
- [PingPush Module README](https://github.com/ForgeRock/ping-ios-sdk/tree/main/Push)
- [PingJourney Module README](https://github.com/ForgeRock/ping-ios-sdk/tree/main/Journey)
- [Ping iOS SDK GitHub Repository](https://github.com/ForgeRock/ping-ios-sdk)

## Security Considerations

- **Keychain Storage**: All credentials are stored securely in the iOS Keychain via the `PingStorage` module
- **Biometric Protection**: Push approval and app unlock can be protected with Face ID / Touch ID
- **APNs Token Rotation**: The app handles token refresh on every launch via `AppDelegate`
- **No Hardcoded Secrets**: Server configuration should use environment-specific values; never commit credentials

## License

This sample application is provided under the MIT License. See the LICENSE file for details.

Copyright (c) 2026 Ping Identity Corporation. All rights reserved.

## Disclaimer

This is a sample application provided "as is" for demonstration purposes only. It is not an official product of Ping Identity and should not be used in production without proper security review and testing.

## Support

For issues related to:
- **This sample application**: Open an issue in the [sdk-sample-apps repository](https://github.com/your-org/sdk-sample-apps/issues)
- **Ping iOS SDK**: Open an issue in the [ping-ios-sdk repository](https://github.com/ForgeRock/ping-ios-sdk/issues)
- **Ping Identity products**: Contact [Ping Identity Support](https://support.pingidentity.com)
