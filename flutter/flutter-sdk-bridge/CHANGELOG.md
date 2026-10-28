## Unreleased

#### Added
- Added `ping_davinci`, a Pigeon-generated bridge over the native Ping DaVinci SDK `2.2.0`: `configureDaVinci`, `start`, `next`, `validate`, `getSession`, `getToken`, `getUserInfo`, `signOff`, `dispose`, and streamed polling, with a sealed `Collector` hierarchy covering all 17 core collector keys, structured validation errors, and per-field server errors on a recoverable `ErrorNode` [SDKS-5267]
- `ping_core`: `Registry` reports its size (`size` on Android, `count()` on iOS), a diagnostic for leak checks

#### Updated
- Bumped `ping_journey` and `ping_oidc` to native Ping SDK `2.2.0` on both platforms

#### Changed
- `ping_oidc` / `ping_journey`: explicit `openId` now behaves the same on both platforms. An `openId`-only config (no `discoveryEndpoint`) is accepted on iOS too and skips discovery. With a `discoveryEndpoint` as well, `openId` patches the discovered document, so endpoints it doesn't carry (such as PAR) still come from discovery. Android previously skipped discovery in that case, and iOS rejected openId-only configs
- `ping_oidc` / `ping_journey` (Android): work around a native 2.2.0 bug where an `openId`-only config threw on authorize (`lateinit discoveryEndpoint` read by `OidcClientConfig.clone()`)
- `ping_oidc/example`: new hermetic `oidc_openid_only_authorize_test.dart` drives a real browser authorize against an auto-redirecting mock and asserts no discovery request
- `flutter-oidc` (Android): removed the `CustomTabActivity` manifest re-declaration; the `appRedirectUriScheme` placeholder alone now sets the redirect scheme (native `browser` 2.2.0, SDKS-5296)

#### Known limitations
- `ping_oidc` / `ping_journey`: `par: true` with an `openId`-only config does not use PAR, because `OidcOpenIdConfig` has no PAR endpoint. iOS falls back to a standard authorize request, and Android fails. Supply a `discoveryEndpoint` to use PAR

## 0.0.2

#### Added
- Completed `ping_oidc`'s post-authorize surface: browser authorize, `token`/`refresh`/`userInfo`/`revoke`/`signOff`, and a public Dart facade over the native Ping OIDC SDK for standalone, browser-based centralized login [SDKS-5265]
- Added `ping_core`'s OIDC seam — so a module can consume a `ping_oidc`-configured client with no compile-time dependency on `ping_oidc`
- Added `flutter-oidc`, a sample app demonstrating the full standalone OIDC flow browser authorize, token/userinfo display, refresh, revoke, sign off [SDKS-5266]
- Added `ping_journey`'s optional `JourneyConfigMessage.oidcClientId`, letting a Journey delegate its OIDC configuration to a client shared via `ping_core`'s registry instead of repeating the same fields inline
- Added `ping_journey`'s optional `JourneyConfigMessage.logLevel`, defaulting to no SDK HTTP/diagnostic logging (opt into `standard` for development-time diagnostics)

## 0.0.1

#### Added
- Added `ping_core`, a federated native plugin carrying the shared `CoreRuntime` handle registry, `PingException`, and JSON codec helpers used by every bridge module [SDKS-4613]
- Added `ping_journey`, a Pigeon-generated bridge over the native Ping Journey SDK: `configureJourney`, `start`, `next`, `getSession`, `signOff`, and `dispose` [SDKS-4613]
- Added Dart sealed types for `JourneyNode` (`ContinueNode`/`SuccessNode`/`ErrorNode`/`FailureNode`) and the v1 callback set (`NameCallback`, `PasswordCallback`, `ValidatedUsernameCallback`, `ValidatedPasswordCallback`, `ChoiceCallback`, `KbaCreateCallback`, `TermsAndConditionsCallback`, `TextInputCallback`, `TextOutputCallback`, `StringAttributeInputCallback`, `NumberAttributeInputCallback`, `BooleanAttributeInputCallback`) [SDKS-4613]
- Pinned both platforms to native Ping SDK `2.0.0` (Android Maven, iOS SPM)
