# PingOne MFA Android Sample App

A Kotlin/Jetpack Compose sample application demonstrating PingOne MFA SDK integration, including
account pairing via QR code, TOTP (one-time passcode) display, and push-notification approval flows.

## Requirements

- Java 17+
- Gradle 8.6+
- Android API level 29+ (Android 10)
- A PingOne MFA environment with at least one application configured for MFA
- A Firebase project with FCM enabled and `google-services.json` placed in `app/`

## Getting Started

1. Clone the repository.
2. Place your `google-services.json` in `android/kotlin-pingonemfa/app/`.
3. Open `android/kotlin-pingonemfa` in Android Studio.
4. Build and run the `app` module on a physical device or emulator (API 29+).

## Features

- **Account pairing** — scan a PingOne MFA QR code or enter a pairing key manually to register a
  device with a PingOne user account.
- **TOTP display** — shows the current one-time passcode for all paired accounts with a live
  countdown to expiry and automatic refresh.
- **Push authentication** — receives FCM push notifications for authentication requests and
  presents an approve/deny screen, including number-challenge and dry-run (test) push types.
- **Server-cancel handling** — if the server cancels an in-flight authentication request (e.g.
  approved on another device), the in-app screen and system tray banner are both dismissed
  automatically.
- **Diagnostic logs** — in-app log viewer that captures all SDK and app events, with share and
  clear actions.

## Project Structure

```
kotlin-pingonemfa/
├── app/
│   └── src/main/
│       ├── java/com/pingidentity/samples/pingonesample/
│       │   ├── PingOneSampleApplication.kt   # Process-scoped SDK init & FCM token registration
│       │   ├── MainActivity.kt               # Entry-point activity
│       │   ├── AuthApp.kt                    # Root composable & navigation graph
│       │   ├── data/
│       │   │   ├── PingOneViewModel.kt       # Accounts, OTP, and pairing state
│       │   │   └── DiagnosticLogger.kt       # In-memory log capture
│       │   ├── notification/
│       │   │   ├── NotificationHelper.kt         # System notification builder
│       │   │   ├── NotificationActionReceiver.kt # Approve/deny from tray actions
│       │   │   ├── NotificationCancelBus.kt      # In-process cancel signal bus
│       │   │   ├── PushNotificationActivity.kt   # Full-screen push approval UI
│       │   │   ├── PushNotificationViewModel.kt  # Approve/deny SDK calls
│       │   │   └── PushNotificationStore.kt      # In-process notification slot
│       │   ├── service/
│       │   │   └── PushNotificationService.kt    # FCM message handler
│       │   ├── ui/
│       │   │   ├── AccountsScreen.kt         # Paired accounts list + TOTP
│       │   │   ├── QrScannerScreen.kt        # Camera QR scanner + manual entry
│       │   │   ├── PushNotificationScreen.kt # Approve/deny UI
│       │   │   ├── DiagnosticLogsScreen.kt   # In-app log viewer
│       │   │   └── components/               # Reusable UI components
│       │   └── util/
│       │       └── QrCodeAnalyzer.kt         # ML Kit barcode analyzer
│       └── res/                              # String resources, drawables, theme
├── gradle/
│   └── libs.versions.toml                    # Version catalog
├── build.gradle.kts
└── settings.gradle.kts
```

## Architecture

The app follows a single-ViewModel-per-screen pattern with unidirectional data flow:

- `PingOneViewModel` owns accounts, OTP state, and pairing. It is shared across the main
  navigation graph (accounts → QR scanner).
- `PushNotificationViewModel` owns approve/deny state for the push approval flow, scoped to
  `PushNotificationActivity`.
- All SDK calls run in `viewModelScope` (or in `PingOneSampleApplication`'s process-lifetime
  scope for init/token registration) so they survive configuration changes.

## Push Notification Flow

1. FCM delivers a data message to `PushNotificationService`.
2. The service decodes it with `PingOneMFA.processRemoteNotification`.
3. **Foreground**: `PushNotificationActivity` is started directly via `startActivity`.
4. **Background / screen off**: a system notification with a full-screen intent is posted;
   the OS launches `PushNotificationActivity` from the lock screen automatically.
5. **Cancel push**: the in-app screen and tray banner are both dismissed without user interaction.

## License

This software may be modified and distributed under the terms of the MIT license. See the
[LICENSE](../../LICENSE) file for details.

© Copyright 2026 Ping Identity Corporation. All rights reserved.
