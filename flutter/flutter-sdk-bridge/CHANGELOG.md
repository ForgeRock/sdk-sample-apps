## 0.0.2

#### Added
- Added `ping_oidc`, a Pigeon-generated bridge over the native Ping OIDC SDK for standalone,  browser-based centralized login [SDKS-5265]
- Added `ping_core`'s OIDC seam — so a module can consume a `ping_oidc`-configured client with no compile-time dependency on `ping_oidc`
- Added `flutter-oidc`, a sample app demonstrating the full standalone OIDC flow browser authorize, token/userinfo display, refresh, revoke, sign off [SDKS-5266]
- Added `ping_journey`'s optional `JourneyConfigMessage.oidcClientId`, letting a Journey delegate its OIDC configuration to a client shared via `ping_core`'s registry instead of repeating the same fields inline

#### Changed
- Bumped both platforms' native Ping SDK pin `2.0.0` → `2.1.0` (Android Maven, iOS SPM)

## 0.0.1

#### Added
- Added `ping_core`, a federated native plugin carrying the shared `CoreRuntime` handle registry, `PingException`, and JSON codec helpers used by every bridge module [SDKS-4613]
- Added `ping_journey`, a Pigeon-generated bridge over the native Ping Journey SDK: `configureJourney`, `start`, `next`, `getSession`, `signOff`, and `dispose` [SDKS-4613]
- Added Dart sealed types for `JourneyNode` (`ContinueNode`/`SuccessNode`/`ErrorNode`/`FailureNode`) and the v1 callback set (`NameCallback`, `PasswordCallback`, `ValidatedUsernameCallback`, `ValidatedPasswordCallback`, `ChoiceCallback`, `KbaCreateCallback`, `TermsAndConditionsCallback`, `TextInputCallback`, `TextOutputCallback`, `StringAttributeInputCallback`, `NumberAttributeInputCallback`, `BooleanAttributeInputCallback`) [SDKS-4613]
- Pinned both platforms to native Ping SDK `2.0.0` (Android Maven, iOS SPM)
