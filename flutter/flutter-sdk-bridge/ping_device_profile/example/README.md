# ping_device_profile integration-test host

This is not a sample app. If you are looking for one, see [`flutter-journey`](../../../flutter-journey).

The `integration_test` package can only run from a Flutter *application*, and `ping_device_profile`
is a plugin. This app exists solely to give the plugin's integration tests a process to run in. Its
`lib/main.dart` is a deliberately empty screen — the tests drive the package's public API directly
and never pump a widget tree.

## Running the tests

Hermetically, against an in-process mock AM server. No tenant, no configuration, no network beyond
loopback. A device or emulator must be attached, because the tests exercise the native SDK through
the platform channel:

```sh
cd flutter-sdk-bridge/ping_device_profile/example
flutter test integration_test/ -d <device-id>
```

Against a real tenant whose Journey shows a Device Profile Collector node:

```sh
flutter test integration_test/ \
  --dart-define=E2E_SERVER_URL=https://openam.example.com/openam \
  --dart-define=E2E_USERNAME=testuser \
  --dart-define=E2E_PASSWORD='…'
```

Credentials are read through `String.fromEnvironment`, so they live in your shell or your CI
secret store and are never written to a file in this repository.

## What the scenarios cover

- `device_profile_collect_test.dart` — the golden path: the server's `DeviceProfileCallback` maps
  to the add-on Dart type, its display fields parse, the native collection returns a profile with
  an identifier, and `next()` completes the journey end-to-end.
- `device_profile_error_test.dart` — collecting with a stale callback (the node was already
  submitted) throws a typed `PingException` of type `state`.

## What the suite does not cover

Location collection. The mock serves `metadata: true, location: false` so no OS permission dialog
can block a run; a live-tenant journey that asks for location needs the permission granted by hand
(and the manifest/Info.plist entries in the package README's Permissions section).
