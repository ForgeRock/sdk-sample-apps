[![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)](https://github.com/ForgeRock/sdk-sample-apps)

# ping_device_profile

Device profile bridge plugin for the Flutter Ping SDK bridge — see [`../README.md`](../README.md) for the bridge overview and its architecture diagrams.

Wraps the native Ping Device Profile SDK (Android `com.pingidentity.sdks:device-profile`, iOS SPM `PingDeviceProfile`, both pinned to `2.2.0`) so a Journey that contains a Device Profile Collector node completes from Flutter. It is an add-on to `ping_journey`: it depends on `ping_core` at both the Dart and native levels, and on `ping_journey` at the Dart level only.

The module is deliberately small and stateless. The live native callback lives in `ping_journey`'s handle (see `ping_core`'s `ActiveNodeAccess` seam), so this package has no configure call, no handle of its own, and no dispose: every call resolves the callback fresh from the journey's current node, under the same lock that serializes the journey's `next()`.

## Usage

```dart
final node = await client.start('Login');
final callback = node.callbacks.whereType<DeviceProfileCallback>().single;

final profile = await callback.collect();   // native collection; never log the result
final next = await client.next(node);       // the profile rides natively on next()
```

There is normally nothing to render: collection is automatic, so a UI shows a progress indicator while `collect` runs. The callback's server-sent display fields are available as `callback.metadata`, `callback.location` and `callback.message`.

`collect()` returns the profile (`Map<String, Object?>`) for display or audit. The app does not send it back: the native SDK stores it on the callback itself (`input()`), and the generic `JourneyClient.next` submits it. After `next()`, the node is gone — collecting with the old callback throws `PingException` type `state`.

## Registration

`DeviceProfileCallback` is registered with `ping_journey`'s add-on callback registry **automatically**: the package declares `dartPluginClass: DeviceProfileCallback`, so Flutter's generated plugin registrant calls `DeviceProfileCallback.registerWith()` before `main()` on both platforms. No app code is needed.

The same static method works as a manual fallback (`PingDeviceProfile.registerWith()` is not required; import `DeviceProfileCallback` and call `DeviceProfileCallback.registerWith()`), with identical semantics — a later registration replaces an earlier one.

If the type is somehow not registered, a Device Profile node falls back to the placeholder `TextOutputCallback` that `ping_journey` renders for unknown callbacks, and the flow can still be submitted.

## Errors

`collect()` throws a typed `PingException`:

| `type` | When | Platform |
|---|---|---|
| `state` | Unknown journey id, or the journey has no active node (e.g. collecting after `next`) | both |
| `argument` | The node no longer holds a `DeviceProfileCallback` at the requested index | both |
| `permission` | A collection permission was denied (`SecurityException`) | Android only |
| `unknown` | Any native collection failure, including denied location access | iOS (see below) |

The platform difference is native, not bridge-made: Android's SDK throws a typed `SecurityException` for denied permissions, while iOS's location errors (`LocationError.authorizationDenied` and friends) are `internal` to the native module and cannot be type-matched from here. The mapper's doc comment records this.

## Native registration of the callback type

The native SDKs register `DeviceProfileCallback` with the native Journey callback registry themselves:

- **Android**: the module's own manifest declares an AndroidX Startup initializer (`CallbackInitializer`), which merges into the app when the dependency is present. It also declares the module's transparent `LocationRequestActivity` for permission prompts.
- **iOS**: `Journey` reaches optional modules by reflection at configuration time (`NSClassFromString("PingDeviceProfile.DeviceProfile")` → `registerCallbacks()`). Once the product is linked, nothing else is needed.

The registration runs asynchronously during `configure`, before any `start()` completes, so a `collect()` cannot race it in practice.

## Permissions

The bridge declares none. Requesting location is the integrating app's privacy decision:

- **Android**: add `ACCESS_NETWORK_STATE` (harmless, used by the network collector) and, if the server asks for location, `ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION` to your app manifest. The native module shows its own permission prompt and continues without location when denied.
- **iOS**: if the server asks for location, add `NSLocationWhenInUseUsageDescription` to your app's Info.plist. See the native SDK's `LocationManager` documentation for the variants it distinguishes.

The integration tests run with `metadata: true, location: false` so no OS dialog can block them.

## Privacy

The collected profile contains a device identifier and, when enabled, location. The bridge never logs it — and your app shouldn't either.

## Tests

- Dart unit tests: `flutter test` from this directory.
- Integration tests (hermetic, on a device/emulator): `flutter test integration_test/ -d <device>` from `example/` — see [`example/README.md`](example/README.md).
- Android JVM unit tests: `./gradlew testDebugUnitTest` from this package's `android/` directory.
- iOS native tests: none (a package test target can't link `Flutter.framework`; see the bridge README's Testing section).
