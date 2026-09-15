[![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)](https://github.com/ForgeRock/sdk-sample-apps)

# ping_oidc

OIDC bridge plugin for the Flutter Ping SDK bridge — see [`../README.md`](../README.md) for the bridge overview and its architecture diagrams.

Wraps the native Ping OIDC SDK (Android `com.pingidentity.sdks:oidc`, iOS SPM `PingOidc`) behind a Pigeon-generated `HostApi`, exposing browser-based centralized login and post-login token/session operations.

Depends on `ping_core` (for the shared `CoreRuntime` OIDC registries) at both the Dart and native levels.

## The two-handle model

Every configured client is actually two native objects, and the bridge keeps them as two handles:

- **Client handle** (`configureOidc`) — the native `OidcClient`, built once from an `OidcConfigMessage`. Registered in `ping_core`'s `CoreRuntime.oidcClientRegistry` so other modules (`ping_journey`'s `JourneyConfigMessage.oidcClientId`) can reuse the same configuration without a compile-time dependency on this package.
- **Web-client handle** (`createWebClient`) — a browser-capable `OidcWebClient` built from the client handle's stored config. Registered separately, in `CoreRuntime.oidcWebClientRegistry`, because the native SDKs treat login/session operations and browser-flow orchestration as genuinely separate objects with different lifetimes.

Dart's public `OidcClient` (`lib/src/oidc_client.dart`) hides this split — `OidcClient.configure()` creates and binds both handles, and `dispose()` always releases both, so callers only ever see one object.

## Wire schema (`pigeons/messages.dart`)

- `OidcConfigMessage` — flat OIDC client config: `clientId`, `redirectUri`, `par` (required); `discoveryEndpoint` **or** `openId` (at least one required — enforced by `OidcConfigParser`, not by Pigeon); `scopes`, `acrValues`, `signOutRedirectUri` (Android-only at apply time — iOS's `OidcClientConfig` has no such field), `state`, `nonce`, `uiLocales`, `refreshThresholdSeconds`, `loginHint`, `display`, `prompt`, `additionalParameters`.
- `OidcOpenIdConfigMessage` — the explicit "skip discovery" endpoint set: `authorizationEndpoint`, `tokenEndpoint`, `userinfoEndpoint` (required), plus optional `endSessionEndpoint`, `pingEndIdpSessionEndpoint`, `revocationEndpoint`.
- `BrowserOptionsMessage` — **iOS-only** browser presentation knobs, `browserType` (`authSession`/`ephemeralAuthSession` implemented; `nativeBrowserApp`/`sfViewController` rejected with a typed error rather than silently no-op'd) and `browserMode`. Android ignores both — Custom Tabs has no equivalent.
- `TokenMessage` — `accessToken`, `expiresIn` (required); `tokenType`, `scope`, `refreshToken`, `idToken`. Deliberately excludes the expiry-stamp field (`expireAt` on Android vs. `expiresAt` on iOS diverge in name and visibility).
- `AuthorizeResultMessage` / `AuthorizeResultType` — only two cases, `success` or `cancel`. **No authorization code, `state`, or redirect URI ever crosses the bridge in either direction** — the native SDK captures the browser's redirect and exchanges the code internally on both platforms.
- `PingOidcHostApi` (`@HostApi`, all methods `@async`): `configureOidc`, `createWebClient`, `authorize`, `hasUser`, `token`, `refresh`, `userInfo`, `revoke`, `signOff`, `dispose`. Every method takes only handle ids and flags — no method ever takes a token as a parameter.

After editing the schema, regenerate from this directory and check in the generated files:

```sh
dart run pigeon --input pigeons/messages.dart
```

## Dart public API

The generated Pigeon code (`lib/src/messages.g.dart`) is intentionally low-level. `ping_oidc.dart` and the rest of `lib/src/` wrap it in the API the sample app actually uses:

- `oidc_client.dart` — `OidcClient`: `.configure(OidcConfig, {browserOptions})`, `.authorize()`, `.hasUser()`, `.token()`, `.refresh()`, `.userInfo({cache = false})`, `.revoke()`, `.signOff()`, `.dispose()`, and a `handleId` getter (so another module can address this client by id via the shared registry). `OidcConfig`/`OidcOpenIdConfig` themselves live in `ping_core` and are re-exported from this package's barrel so app code doesn't need a direct `ping_core` dependency.
- `oidc_browser_options.dart` — `OidcBrowserOptions`, the Dart-side counterpart to `BrowserOptionsMessage`.
- `oidc_token.dart` — `OidcToken`: `accessToken`, `tokenType`, `scope`, `expiresIn`, `refreshToken`, `idToken`. Manual `fromMessage`/`fromJson`/`toJson`, throwing `FormatException` on malformed input.
- `oidc_user_info.dart` — `OidcUserInfo`, a `Map<String, Object?>` typedef. OIDC claim sets are provider/scope-dependent, so this module doesn't invent structure the server doesn't guarantee.
- `authorize_result.dart` — `sealed class AuthorizeResult` with `AuthorizeSuccess`/`AuthorizeCancel` leaves. (This two-case union, and the four-case `OidcError` enum on the native side, are the one deliberate exception to "no hierarchies" above — a two-or-four-case closed union is a value type, not the mapper-plus-many-leaf-types pattern this module otherwise avoids.)
- Native failures surface as `PlatformException` and are caught by every method above (via `OidcClient`'s internal `_guard`) and rethrown as `ping_core`'s typed `PingException`, so callers never need to know a platform channel is involved.

## Native implementation shape

Both platforms follow the same layering, so a change on one side has an obvious counterpart on the other:

| Concern | Android | iOS |
|---|---|---|
| Pigeon-generated types | `Messages.g.kt` | `Messages.g.swift` |
| Plugin registration | `PingOidcPlugin.kt` | `PingOidcPlugin.swift` |
| `HostApi` implementation | `OidcHostApiImpl.kt` | `OidcHostApiImpl.swift` |
| Config → native `OidcClientConfig` | `OidcConfigParser.kt` | `OidcConfigParser.swift` |
| Build the client handle | `OidcClientFactory.kt` | `OidcClientFactory.swift` |
| Build the web-client handle | `OidcWebClientFactory.kt` | `OidcWebClientFactory.swift` |
| Native error → wire error | `error/OidcErrorMapper.kt` (+ `OidcErrorCodes.kt`) | `Error/OidcErrorMapper.swift` (+ `OidcErrorCodes.swift`) |

Every native completion path routes through the error mapper — no bare `catch` that swallows or rethrows unmapped. `authorize()` intercepts browser cancellation *before* the mapper runs on both platforms, so a user dismissing the browser resolves `AuthorizeResultMessage(cancel)` rather than throwing.

For the full set of verified Android/iOS behavioral differences this module bridges around (force-refresh going through `User.refresh()` on both platforms, the `userinfo(cache:)` default divergence, the `hasUser()`/no-session divergence, etc.), see [`../../IMPLEMENTATION_PLAN_OIDC.md`](../../IMPLEMENTATION_PLAN_OIDC.md) § Platform asymmetries — kept in one place rather than duplicated here so the two copies can't drift.

## Security constraint

Tokens are native-owned: persisted only in native secure storage (Android `EncryptedDataStoreStorage`, iOS `KeychainStorage`), never by Dart. Concretely:

- `token()`/`refresh()` return `accessToken`/`idToken`/`refreshToken` values to Dart for use and display — this is in scope and matches the React Native bridge's precedent.
- No Dart-side persistence of any kind (`shared_preferences`, `flutter_secure_storage`, files, process-lifetime singletons/statics).
- No Dart-side token construction, expiry arithmetic, or "is my token still valid" logic — ask native (`hasUser()`, `token()`).
- No token ever crosses the bridge as a method **parameter** — every `HostApi` method takes only a handle id and flags. `refresh()` goes through `User.refresh()` on both platforms; the bridge never sends a refresh token from Dart into native.

## Build / dependency wiring

- **Android**: `namespace 'com.pingidentity.flutter.oidc'`, `minSdk 29`, `compileSdk 36`, Java 17; `implementation project(':ping_core')` + `com.pingidentity.sdks:oidc:2.1.0` + `com.pingidentity.sdks:storage:2.1.0` + `com.pingidentity.sdks:orchestrate:2.1.0` + `com.pingidentity.sdks:android:2.1.0` + `kotlinx-coroutines-android` + `kotlinx-serialization-json`.
  ⚠️ **`com.pingidentity.sdks:browser:2.1.0` must be added explicitly** — it's `compileOnly` inside the native SDK's own `foundation/oidc` module ("make it optional for using centralized login"), so it is *not* pulled in transitively. A consumer that wants browser login and forgets this dependency fails at runtime, not at compile time.
- **iOS (SPM)**: platform `.iOS(.v16)`; dependencies = local `ping_core` package + `.package(url: "https://github.com/ForgeRock/ping-ios-sdk", exact: "2.1.0")`; the target links `PingOidc`, `PingBrowser`, `PingStorage`, `PingOrchestrate`, `PingLogger`. A CocoaPods podspec (`ping_oidc.podspec`) is kept as an optional fallback for host apps not yet on SPM, with the same explicit dependency list.
- Native SDK version is pinned to **2.1.0** on both platforms — see [`../README.md`](../README.md).

## Testing

- **Unit tests** — `test/` (Dart, mocks the generated `PingOidcHostApi`), plus native unit tests under `android/src/test/kotlin/` and `ios/ping_oidc/Tests/`.
- **Integration tests** — [`example/`](example/) is a minimal integration-test host, not a sample app; see [its README](example/README.md) for what it does and doesn't cover (the browser-authorize step itself can't be scripted). [`../../flutter-oidc/`](../../flutter-oidc/) is the sample app to run by hand for the full browser login round trip.

## License

This software may be modified and distributed under the terms of the MIT license. See the LICENSE file for details.

© Copyright 2026 Ping Identity Corporation. All rights reserved.
