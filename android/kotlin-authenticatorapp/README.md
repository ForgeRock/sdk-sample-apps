[![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)](https://github.com/ForgeRock/ping-android-sdk)

# Ping Authenticator Sample App

This sample application demonstrates how to implement multi-factor authentication using the Ping Identity SDK. The app allows users to register and manage both OATH credentials (TOTP/HOTP) and Push authentication credentials.

## Disclaimer

This application is a sample and not intended for production use. It is provided for educational purposes to demonstrate the use of the Ping Identity SDK.

The application uses a public reverse geocoding service for location mapping. This service is not guaranteed to be accurate or available. For a production application, it is recommended to use a more robust and reliable geocoding service.

## Features

### OATH Authentication
- **QR Code Scanning**: Register accounts by scanning QR codes containing OATH credentials
- **Manual Entry**: Manually enter account details
- **Journey Authentication**: Register accounts through authenticated Journey login flows
- **TOTP Support**: Automatic generation of time-based one-time passwords with countdown timer
- **HOTP Support**: Counter-based one-time passwords with refresh capability
- **Copy OTP**: Copy to clipboard functionality

### Push Authentication
- **QR Code Registration**: Register for push authentication by scanning QR codes
- **Journey Authentication**: Register for push authentication through authenticated Journey login flows
- **Push Notifications**: Receive and respond to authentication requests
- **System Notifications**: Display system notifications when push requests are received
- **Direct Actions**: Approve or deny authentication requests directly from system notification tray (DEFAULT type)
- **Push Biometric Authentication**: Authenticate using fingerprint or face recognition (BIOMETRIC type)
- **Push Challenge Verification**: Verify challenge numbers for enhanced security (CHALLENGE type)
- **Location Display**: View location information when provided in push notifications
- **Notification Management**: Clean up old notifications via Settings screen
- **Device Token Management**: View device token information

### Journey-based Credential Enrollment
- **User Authentication**: Allow the app to authenticate users through Journey flows
- **Seamless Integration**: MFA registration integrated directly into authentication flows
- **User Association**: Journey-registered credentials are automatically associated with the authenticated user

### Common
- **Account Management**: View, organize, and delete accounts
- **Account Grouping**: Group MFA accounts with the same issuer/account name

## Architecture overview

The Ping Authenticator App sample is a modular Android application built on Model-View-ViewModel architecture with Kotlin, Jetpack Compose, and the Ping SDK for secure multi-factor authentication (MFA).

```
┌─────────────────────────────┐
│      Presentation Layer     │  ← UI: Jetpack Compose screens, navigation
├─────────────────────────────┤
│        Domain Layer         │  ← ViewModels, business logic, state
├─────────────────────────────┤
│     Data/Service Layer      │  ← Managers, services, secure storage
├─────────────────────────────┤
│         SDK Layer           │  ← Ping SDK: push, oath, and journey modules
└─────────────────────────────┘
```

- **Presentation Layer**: Android Activities/Fragments for user interaction.
- **Domain Layer**: Handles business logic, orchestrates feature flows, and manages state.
- **Data/Service Layer**: Integrates with Ping SDK modules (`push`, `oath`, `journey`) and other services.
- **SDK Layer**: Abstracts the complexity to deal with MFA capabilities and comunication with Ping backend.

The application follows modern Android development practices:

- **Kotlin**: 100% Kotlin codebase
- **Jetpack Compose**: Declarative UI toolkit for building native UI
- **ViewModel**: Architecture component for managing UI-related data in a lifecycle conscious way
- **Coroutines**: For asynchronous operations
- **Navigation**: For handling navigation between screens
- **Material 3**: For modern, adaptive UI components
- **Firebase Cloud Messaging**: For receiving push notifications
- **OpenStreetMap**: For displaying location information in push notifications

## Implementation Details

### Code Structure Overview

```
src/main/kotlin/com/pingidentity/authenticatorapp/
├── AuthenticatorApp.kt             # App initialization, SDK clients (Push, OATH, Journey)
├── managers/
│   ├── JourneyManager.kt           # Journey logic, state, integration
│   ├── PushManager.kt              # Push logic, state, integration
│   └── OathManager.kt              # OATH logic, state, integration
├── ui/
│   ├── AccountsScreen.kt           # Account management UI
│   ├── PushNotificationsScreen.kt  # Push notification UI
│   └── ...                         # Other Compose screens
├── data/
│   ├── AuthenticatorViewModel.kt   # Coordinates between Push and OATH managers and handles UI-specific logic
│   ├── LoginViewModel.kt           # Coordinates between Journey and other managers handling UI-specific logic
│   ├── DiagnosticLogger.kt         # Logging
│   └── UserPreferences.kt          # Preferences
└── ...
```

**Key Classes & Structure:**

- `AuthenticatorApp.kt`: Initializes Push, OATH, and Journey clients, manages global app state.
- `managers/`: Integrates Ping SDK modules.
- `managers/JourneyManager.kt`: Handles Journey lifecycle with MFA registration.
- `managers/PushManager.kt`: Encapsulates push notification logic and state.
- `managers/OathManager.kt`: Handles OATH token lifecycle and OTP generation.
- `ui/`: Compose screens and components for account and notification management.
- `data/`: Models, preferences, logging.

### Push Module
- **Device Registration**: Registers device with Ping backend for push authentication.
- **Notification Handling**: Listens for push requests, displays actionable notifications.
- **User Actions**: Approve/deny requests from notification or app UI.
- **Result Reporting**: Communicates user decisions to Ping backend securely.

**Class:** `PushManager.kt`

**Flow Diagram (textual):**
```
Push Request → PushManager → Notification UI → User Action → Ping Backend
```

#### Push Authentication Types

The app handles three different types of push authentication:

1. **DEFAULT**: Simple approval/denial directly from the notification
   ```kotlin
   // Approve a standard notification
   pushClient.approveNotification(notificationId)
   ```

2. **BIOMETRIC**: Authentication using biometric verification
   ```kotlin
   // Approve with biometric authentication
   pushClient.approveBiometricNotification(notificationId)
   ```

3. **CHALLENGE**: Verification using challenge numbers
   ```kotlin
   // Get challenge numbers
   val numbers = pushNotification.getNumbersChallenge()
   
   // Approve with challenge response
   pushClient.approveChallengeNotification(notificationId, challengeResponse)
   ```


### OATH Module
- **Token Provisioning**: Enrolls OATH tokens via QR/manual entry or Journey authentication flows.
- **Code Generation**: Generates OTP codes (TOTP/HOTP) for authentication.
- **Token Management**: UI for listing, renaming, deleting tokens.
- **Security**: OTP codes can be hidden (optional).

**Class:** `OathManager.kt`

**Flow Diagram (textual):**
```
Enroll Token → OathManager → Generate OTP → Display in UI → User enters code
Journey Flow → Auto-Register → Associate with User → Mark as Journey-enabled
```

### Journey Module
- **Authentication Flows**: Handles PingOne Advanced Identity Cloud (AIC) authentication journeys.
- **MFA Registration**: Automatically registers MFA credentials during authentication flows.
- **User Association**: Associates registered credentials with authenticated users.

**Class:** `LoginViewModel.kt`

**Flow Diagram (textual):**
```
Start Journey → Authentication Steps → MFA Registration → Success → Associate Credentials
```

### QR Code Scanning

The app uses CameraX and ML Kit to scan and decode QR codes:

#### OATH QR Codes (otpauth:// URIs):
```
otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example&algorithm=SHA1&digits=6&period=30
```

#### Push QR Codes (pushauth:// URIs):
```
pushauth://push/Example:bob@example.com?pushauth_uri=https://example.com/push&client_id=clientId123
```

### Journey-Based Registration

The app also supports registering MFA credentials through authenticated Journey flows:

#### Journey Authentication Flow:
1. **Start Journey**: Initiate authentication with PingOne Advanced Identity Cloud
2. **Authentication Steps**: Complete required authentication steps (username/password, etc.)
3. **MFA Registration**: Journey automatically provides MFA registration URIs during the flow
4. **Auto-Registration**: App automatically registers OATH/Push credentials from Journey callbacks
5. **User Association**: Successfully authenticated credentials are associated with the user session

This provides a seamless user experience where MFA credentials are automatically registered during the authentication process without requiring separate QR code scanning.

## Getting Started

### Prerequisites

- Android Studio Koala | 2024.1.1 or newer
- Android SDK 29 or higher
- Gradle 8.7 or newer

### Building the App

1. Clone the repository
2. Open the project in Android Studio
3. Build and run on your device or emulator

## Testing

### Testing OATH Functionality

To test the app's OATH functionality, you can:

1. **QR Code Method**:
   - Use any TOTP/HOTP QR code generator
   - Create test credentials using command line tools like `oathtool`
   - Use online TOTP testing services

2. **Journey Method**:
   - Configure a PingOne Advanced Identity Cloud environment with OATH MFA
   - Set up Journey flows that include MFA registration steps
   - Test the full authentication flow including automatic credential registration

### Testing Push Functionality

To test the app's Push functionality, you need:

1. **QR Code Method**:
   - A PingAM account with push authentication configured
   - FCM configured for your Android application
   - The app properly registered with FCM to receive push notifications

2. **Journey Method**:
   - A PingOne Advanced Identity Cloud environment with Push MFA configured
   - Journey flows that include Push registration steps
   - FCM properly configured to receive push notifications
   - Test environment to generate push authentication requests

### Testing Journey Integration

To test the Journey-based MFA registration:

1. Set up a PingOne Advanced Identity Cloud environment
2. Configure Journey flows with MFA registration callbacks
3. Test the complete flow: authentication → MFA registration → credential association
4. Verify that registered credentials show user session indicators in the UI

## Contributing

Contributions are welcome! Please read the [contributing guidelines](../../CONTRIBUTING.md) for more information.

## Troubleshooting

- **Push notifications are not being received**: 
  - Ensure that your device has a valid internet connection.
  - Verify that the device token is correctly registered with the push notification service.
  - Check the server logs to see if the push notification is being sent successfully.
- **QR code is not scanning**:
  - Make sure that the QR code is well-lit and in focus.
  - Try scanning the QR code from a different distance or angle.
  - Ensure that the QR code is in the correct format.

## License

Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
This software may be modified and distributed under the terms of the MIT license. See the [LICENSE](../LICENSE) file for details.

© Copyright 2025-2026 Ping Identity Corporation. All Rights Reserved
