## Unreleased

#### Added
- Added `ping_device_profile`, a Pigeon-generated bridge over the native Ping Device Profile SDK `2.2.0`: `collect(journeyId, callbackIndex)` runs the native collection on a Journey's `DeviceProfileCallback` and returns the profile. The package registers its Dart callback type with `ping_journey`'s add-on registry automatically (via `dartPluginClass`), so a Journey with a Device Profile Collector node completes end-to-end from Flutter [SDKS-5263]
- The Dart `DeviceProfileCallback` exposes the server's display fields (`metadata`, `location`, `message`) and collects with no arguments; the native SDK stores the profile on the callback, and `JourneyClient.next` submits it [SDKS-5263]

#### Known limitations
- A denied collection permission surfaces as `PingException(type: 'permission')` on Android only. On iOS the native SDK's location error types are internal, so they classify as `unknown` [SDKS-5263]
