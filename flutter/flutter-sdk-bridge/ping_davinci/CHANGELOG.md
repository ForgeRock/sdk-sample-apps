## Unreleased

#### Added
- Added `ping_davinci`, a Pigeon-generated bridge over the native Ping DaVinci SDK, pinned to native `2.2.0` (Android Maven, iOS SPM) [SDKS-5267]
- `configureDaVinci` builds and registers a native DaVinci workflow, configuring OIDC from either hoisted fields or a `ping_oidc` client handle (`oidcClientId`), and rejecting both-or-neither with a typed `argument` error [SDKS-5267]
- `start` and `next` drive the native flow, returning a sealed `DaVinciNode` (`ContinueNode`/`SuccessNode`/`ErrorNode`/`FailureNode`); `next` applies the app's collector values by `{type, index}` with strict type checks, failing with a typed `argument` error [SDKS-5267]
- `validate` runs the native SDKs' local validation without a network call and returns a sealed, structured `ValidationError` per failure, attached to its collector; `ContinueNode.canSubmit` checks required fields in Dart [SDKS-5267]
- `ErrorNode` carries `status`, the server's `input`, typed `errorDetails`, a flat per-field `fieldErrors` map, and the `continueNode` to retry from, whose collectors carry their `serverError` [SDKS-5267]
- Android: server error `details` decode when `rawResponse` lacks `id`/`code`/`message`, where native `ErrorNode.details()` throws [SDKS-5267]
- iOS: the factory awaits its own registration of the 23 core collector keys before returning, closing the native `createDaVinci` detached-`Task` registration race [SDKS-5267]
- Typed `QRCodeCollector` (data URI and `imageBytes`), `PollingCollector`, `DeviceRegistrationCollector`/`DeviceAuthenticationCollector` (`selectDevice`) and `MetadataCollector` (`setResult`/`setError`), completing the 17 core collector keys [SDKS-5267]
- Every call that reads or moves a flow (`start`, `next`, `validate`, `startPolling`, `signOff`, `dispose`) is serialized per handle, and `dispose` removes the handle first: a `next` or `startPolling` in flight when `dispose` is called can no longer leave a cached node or a running poll behind [SDKS-5267]
- iOS: detaching the Flutter engine stops reporting every running poll, as Android's does [SDKS-5267]
- A diagnostic `retainedState()` host method reports the handles, cached nodes and sessions, flow locks and polls the bridge holds, for the configure-to-dispose leak check (`davinci_lifecycle_leak_test`) [SDKS-5267]
- `DaVinciClient.poll` streams a polling collector's native statuses as a sealed `PollingStatus`, over one Pigeon event channel, in the same order on both platforms; the flow moving on ends the poll [SDKS-5267]
