[![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)](https://github.com/ForgeRock/sdk-sample-apps)

# ping_davinci

DaVinci bridge plugin for the Flutter Ping SDK bridge — see [`../README.md`](../README.md) for the bridge overview.

Wraps the native Ping DaVinci SDK (Android `com.pingidentity.sdks:davinci`, iOS SPM `PingDavinci`, both pinned to `2.2.0`) behind a Pigeon-generated `HostApi`. Depends on `ping_core` for the shared `CoreRuntime.davinciRegistry` and the OIDC handle seam.

> **Status:** in progress — see [`IMPLEMENTATION_PLAN_DAVINCI.md`](../../IMPLEMENTATION_PLAN_DAVINCI.md). `configure`, `start`, `next`, `validate`, `poll`, the post-success calls (`getSession`, `getToken`, `getUserInfo`, `signOff`), and `dispose` work. All 17 collector keys the native `davinci` module registers are typed; add-on collectors (social login, FIDO, Protect, mobile pairing) are Plan 3.

## Node engine

`DaVinciClient.start()` returns a sealed `DaVinciNode` — `ContinueNode`, `SuccessNode`, `ErrorNode`, or `FailureNode` — so a `switch` over it is exhaustive. A `ContinueNode` carries the form's `id`, `name`, `pageDescription`, `category`, and its `collectors`.

To submit, set `value` on the collectors you filled in, call `select()` on the button pressed, and call `next(node)`. Only collectors whose value was set are sent, addressed natively by `{type, index}` (`index` is the position in `collectors`) against the cached native node. Native type-checks every value strictly, so a caller of the raw host API that sends a wrong type gets `PingException(type: 'argument')` and nothing is submitted. Passwords are never sent back to Dart.

## Validation and server errors

**Local validation.** `DaVinciClient.validate(node)` sends the values the app set (as `next` would) and runs the native SDK's own rules, with no network call: `required`, the server's regex, and the password policy. It returns a sealed `ValidationError` per failure (`RequiredError`, `RegexError`, `InvalidLengthError`, `UniqueCharacterError`, `MaxRepeatError`, `MinCharactersError`), each with its parameters and an English `message` default; `switch` over it to render localized text. Each `FieldCollector.validationErrors` holds its own. `next` never validates, as in both native SDKs: call `validate` first. `ContinueNode.canSubmit` is a cheap Dart-only check that every required field is filled.

**Server errors.** A `4xx` from the flow is an `ErrorNode` with `status`, `input` (the JSON body, whose `code` names the error), `errorDetails` (the native `details()`, typed), and `fieldErrors`: one message per field, flattened from the details (`ErrorDetail.fieldErrors` documents the rule). When `continueNode` is non-null the flow can be retried: it is the form just submitted, its collectors keep the values sent (passwords are empty again), and each carries its `serverError`. Correct it and `next(error.continueNode!)`.

The keys of `fieldErrors` are the server's targets. PingOne names its own attributes (`password`), which match a form's keys only when the form uses those names; a sign-on with wrong credentials on the test tenant names no field at all, so show `ErrorNode.message` too.

**Platform differences** (native 2.2.0), passed through unchanged and pinned by tests:

| | Android | iOS |
|---|---|---|
| A polling timeout (`code: "timedOut"`) | recoverable `ErrorNode` | `FailureNode` |
| An unanchored server regex | must match the whole value | may match any part |
| A required box left unchecked, with a server `errorMessage` | `RequiredError` | `RegexError(errorMessage)` |
| Password length and character counts | UTF-16 code units | characters |

The bridge does correct one Android gap: `ErrorNode.details()` throws on a response whose `rawResponse` lacks `id`/`code`/`message` (the tenant's wrong-password body), because its nullable fields have no defaults (ping-android-sdk 2.2.0 bug). The Android mapper decodes the same model with absent keys as `null`, one element at a time, as iOS does.

## Session, tokens, and sign-off

A `SuccessNode` means the flow is complete. Four calls follow it:

- **`getSession()`** returns a `DaVinciSession` holding the OAuth **authorization code**, or `null` before a `SuccessNode` (and after the client starts over or signs off). It is *not* `ping_journey`'s token-bearing `Session`. The native SDK redeems the code itself, so it is already spent: don't try to exchange it.
- **`getToken()`** returns a `DaVinciToken`, read from native secure storage and refreshed natively if expired. With no signed-in user it throws `PingException(type: 'state')`, never an empty token.
- **`getUserInfo({cache = false})`** returns the claims. `cache` defaults to `false` on both platforms (the native defaults differ: Android `false`, iOS `true`).
- **`signOff()`** ends the OIDC session, revokes the stored tokens, deletes the session cookies, and drops the cached node; `getToken()` then throws `state`. It returns `false` if the native sign-off threw and `true` otherwise, which does not prove a session existed.

Tokens are stored only natively. Their values cross the bridge for the app to use; Dart never persists them, and no token is ever sent from Dart to native.

**Platform differences**, smoothed over by the bridge:

| | Android | iOS | Bridge |
|---|---|---|---|
| When the code is exchanged | at `SuccessNode` time | on the first `token()` | none needed; exactly one exchange either way |
| What finds the user | `oidcUser()` only while the `ST`/`ST-NO-SS` session cookie is stored | the user cached at `SuccessNode` time, then the cookie | drops the iOS cache on `signOff`, which the SDK keeps; otherwise iOS would still find a user, and redeem a never-exchanged code |
| A `SuccessNode` with no code | `AuthorizeException` | `""` | both are `PingException(type: 'auth')` |

Before a `SuccessNode`, `getToken()` throws `state` when no session cookie is stored. With one left by an earlier run, both SDKs return a user that can't sign in, and `token()` fails with `auth` instead.

## Collectors

`Collector` is a sealed hierarchy, so a form builder that `switch`es over it is checked for exhaustiveness:

| Dart type | Server `type`s | `value` |
|---|---|---|
| `TextCollector` | `TEXT` | `String`, plus `validation` (regex + message) |
| `PasswordCollector` | `PASSWORD`, `PASSWORD_VERIFY` | `String` (always starts empty), plus `passwordPolicy` |
| `SingleSelectCollector` | `DROPDOWN`, `RADIO` | `String`, plus `options` and `validation` |
| `MultiSelectCollector` | `CHECKBOX`, `COMBOBOX` | unmodifiable `List<String>`, plus `options` |
| `BooleanCollector` | `SINGLE_CHECKBOX` | `bool`, plus `appearance`, `errorMessage`, `richContent` |
| `PhoneNumberCollector` | `PHONE_NUMBER` | `PhoneNumberValue` (`countryCode`, `phoneNumber`, `phoneExtension`) |
| `SubmitCollector`, `FlowCollector` (`ButtonCollector`) | `SUBMIT_BUTTON`; `FLOW_BUTTON`, `FLOW_LINK` | `select()` sets it to the key |
| `DeviceRegistrationCollector`, `DeviceAuthenticationCollector` (`DeviceCollector`) | `DEVICE_REGISTRATION`; `DEVICE_AUTHENTICATION` | `Device?`, set with `selectDevice` from `devices` |
| `MetadataCollector` | `METADATA` | `MetadataResult?`, set with `setResult(map)` / `setError(code, message)`; plus `metadata` |
| `PollingCollector` | `POLLING` | none from the app — `DaVinciClient.poll` sets it natively |
| `LabelCollector`, `ReadOnlyTextCollector`, `ImageCollector`, `QRCodeCollector` | `LABEL`; `AGREEMENT`; `IMAGE`; `QR_CODE` | none — display-only |
| `AddOnCollector` | add-on modules' | the open branch, see below |

The Dart subtype follows the **native class** (`CollectorMessage.kind`), never the `type` string: `PASSWORD`/`PASSWORD_VERIFY` share a class, and `DROPDOWN`/`RADIO` are both `SINGLE_SELECT`. `type` stays the server's, so an app can still draw a dropdown and a radio group differently.

**Fields with no collector.** `ContinueNode.unsupportedFields` lists every form field that arrived without one, each with a `reason`: `knownIgnorable` (`ERROR_DISPLAY`, a server-UI placeholder on most real forms), `addOnRequired` (`PROTECT`, `FIDO2`, `SOCIAL_LOGIN_BUTTON`, `MOBILE_PAIRING` with the add-on not linked natively), `notBridged` (native built a collector this package has no Dart type for), or `unknown`. The rest of the form maps and submits normally.

**Add-on collectors.** An add-on package subclasses `AddOnCollector` and calls `Collector.registerAddOn(kind, factory)` with the kind its native mapper reports. Until it does, `Collector.fromMessage` throws an `UnsupportedError` naming the type, and `DaVinciClient` reports the collector as `notBridged` instead of failing the node.

**Devices and metadata.** Dart names a device by `{id, type}` and native re-resolves it in the collector's own list, so the payload is the SDK's (`type` for registration; `type`, `id`, `description` for authentication). A `MetadataCollector` is required until the app sets a result, whatever its `required` flag says, as in both SDKs: `validate` reports a `RequiredError` and `canSubmit` is `false`.

**QR codes.** `QRCodeCollector.content` is the server's data URI on both platforms (iOS gained it in 2.2.0); `imageBytes` decodes its base64. Render with `Image.memory` and show `fallbackText` from its `errorBuilder`.

**Platform normalizations.** Both native mappers send the same message for the same field: an empty validation regex, an empty rich-content `href`/`target`, an empty polling `challenge` or device `title`/`description`/`iconSrc`, and an unbounded password-policy limit (`Int.MAX_VALUE` on Android, `Int.max` on iOS) all become `null`; an iOS device with no `default` is `false`, as on Android. Android's `PhoneNumberCollector` loses `extensionLabel` when the server prefills the number (ping-android-sdk 2.2.0 bug), so the Android mapper reads it back from the field. One difference is left as is: a `BooleanCollector` with no server `errorMessage` reports Android's English default on Android and `null` on iOS.

## Polling

`DaVinciClient.poll(collector)` runs a `PollingCollector`'s native poll and returns a `Stream<PollingStatus>`: zero or more `PollingContinue(retryCount, maxRetries)`, then one terminal `PollingComplete(status)`, `PollingTimedOut`, `PollingExpired` or `PollingError`, then done. Then submit the node with `next`: the native collector holds the value the poll ended with. Cancelling the subscription, `next`, `start`, `signOff` and `dispose` end a poll, closing its stream without a terminal status.

- **Simple mode** is one terminal status per cycle, usually `PollingComplete('continue')`. Submitting it makes the server rewind to the same form, which both SDKs rebuild with `retriesAllowed` one lower, until the last cycle times out.
- **Challenge mode** polls the challenge-status endpoint every `pollInterval`, with a `PollingContinue` per incomplete attempt.

**Bridge shape.** One Pigeon `@EventChannelApi` stream carries every poll's statuses, each tagged with a poll id Dart picks before it calls `startPolling`: Pigeon's event-channel methods take no parameters, and a channel per poll would need native registration and teardown each time. Native owns the retry and timeout policy; Dart never re-implements it.

**Platform differences** (native 2.2.0):

| | Android | iOS | Bridge |
|---|---|---|---|
| Order of a challenge attempt's `Continue` | after the attempt comes back incomplete | before the attempt's request | iOS's held until the next status: same sequence on both |
| Simple mode | one `Complete("continue")` / `TimedOut` | the same, after an extra `continue` | iOS's extra `continue` dropped |
| A `5xx` status response | `Error` | retried | passed through |
| A `4xx` status response | `Expired` only with `serviceName: challengeExpired`, else `Error` | `Expired` | passed through |
| Ending a poll | stops its network polling (the `Flow` is cold) | **can't**: the SDK polls in a `Task {}` nobody can cancel, which goes on sending status requests, unreported, for up to `pollRetries × pollInterval` | pinned by `davinci_polling_cancel_test` |

## Configuration

DaVinci always runs through an OIDC module, so `DaVinciConfigMessage` configures the OIDC client through **exactly one** of two paths:

- the hoisted OIDC fields (`clientId`, `redirectUri`, and `discoveryEndpoint` and/or `openId` required; `scopes`, `acrValues`, … optional), or
- `oidcClientId` — the `handleId` of an `OidcClient` already configured with `ping_oidc`, resolved from `CoreRuntime.oidcClientRegistry`.

Both at once, or neither, fails natively with `PingException(type: 'argument')`. `acrValues` is what selects the DaVinci flow on PingOne.

## Wire schema (`pigeons/messages.dart`)

The full collector/node/token surface is declared up front so later phases only fill in native mapping. Field renames forced by Pigeon or by reserved words: `pageDescription`, `imageDescription`, `deviceDescription` (`description` is rejected), `isDefault` (`default`), `phoneExtension` (`extension`). `SessionMessage` carries the **authorization code** — DaVinci's `SuccessNode.session` is not a token; tokens come from `getToken`.

After editing the schema, regenerate from this directory and check in the generated files:

```sh
dart run pigeon --input pigeons/messages.dart
```

## Native implementation shape

| Concern | Android | iOS |
|---|---|---|
| Pigeon-generated types | `Messages.g.kt` | `Messages.g.swift` |
| Plugin registration | `PingDaVinciPlugin.kt` | `PingDaVinciPlugin.swift` |
| `HostApi` implementation | `DaVinciHostApiImpl.kt` | `DaVinciHostApiImpl.swift` |
| Config → native DaVinci workflow | `DaVinciConfigParser.kt` | `DaVinciConfigParser.swift` |
| Build + register the handle | `DaVinciFactory.kt` | `DaVinciFactory.swift` |
| Collector registration race fix | — (AndroidX Startup registers eagerly) | `CoreCollectorRegistration.swift` |
| Native error → wire error | `error/DaVinciErrorMapper.kt` (+ codes) | `Error/DaVinciErrorMapper.swift` (+ codes) |
| Node / collector → wire message | `mapper/DaVinciNodeMapper.kt`, `mapper/DaVinciCollectorMapper.kt` | `Mapper/DaVinciNodeMapper.swift`, `Mapper/DaVinciCollectorMapper.swift` |
| Local validation → wire errors | `mapper/DaVinciValidationMapper.kt` | `Mapper/DaVinciValidationMapper.swift` |
| Dropped fields (`unsupportedFields`) | the factory's registered keys | core keys, plus a factory probe for any other |
| Polling → `pollingEvents` stream | `polling/DaVinciPolling.kt` | `Polling/DaVinciPolling.swift` (+ `PollingStatusNormalizer`) |

**iOS collector registration.** `DaVinci.createDaVinci` registers its collectors in a detached `Task {}` with nothing to await. The iOS factory re-registers the same 23 keys itself (17 core + 6 iOS aliases) and awaits that before returning the handle. The key table lives in `CoreCollectorRegistration.swift`; an SDK bump that adds a core collector is a one-line change there. The race is rare (about 1 in 50 constructions when probed with no gap, per `CollectorRegistrationRaceTests`) and never shows through the Flutter channel, but the awaited registration closes it.

## Tests

- Dart unit tests: `flutter test` from this directory.
- Both native suites map node JSON captured from the live tenant, read from `example/integration_test/support/fixtures/` (Android as test resources, iOS from the source tree).
- Android unit tests: `JAVA_HOME=<jdk-21> ./gradlew :ping_davinci:testDebugUnitTest` from `example/android`.
- iOS XCTests live in `example/ios/RunnerTests` (a package `.testTarget` can't link `Flutter.framework`). Run them on one simulator from `example/ios`, after `flutter build ios --config-only` in `example/`:

  ```sh
  xcodebuild test -workspace Runner.xcworkspace -scheme Runner \
    -destination 'platform=iOS Simulator,id=<udid>' -only-testing:RunnerTests
  ```
- Integration tests: `example/` — see [`example/README.md`](example/README.md).
