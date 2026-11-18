## Unreleased

#### Added
- An add-on callback seam: `AddOnCallback` (the open branch of the sealed `Callback` hierarchy) plus `Callback.registerAddOn(type, factory)`, so an add-on package can contribute a Dart type for a callback its optional native module owns (device profile, device binding, FIDO). Unregistered types keep rendering as the placeholder `TextOutputCallback`. Add-on factories receive the node's `journeyId`, and `AddOnCallback` exposes it with the callback's full server JSON (`raw`) [SDKS-5263]

#### Updated
- Bumped to native Ping SDK `2.2.0` (Android Maven, iOS SPM)

#### Changed
- Android: an OIDC client handle carrying only `openId` no longer fails the token exchange on the native `OidcClientConfig.clone()` `lateinit discoveryEndpoint` bug
- An OIDC client handle with `openId` and no `discoveryEndpoint` now skips discovery on both platforms. With a `discoveryEndpoint` as well, discovery runs and `openId` patches the result on both platforms (Android previously skipped discovery)
- iOS: native `OidcError.configurationError` (new in 2.2.0) maps to `PingException.type == "argument"`

#### Known limitations
- `par: true` with an `openId`-only OIDC client handle does not use PAR (no PAR endpoint in `OidcOpenIdConfig`). Supply a `discoveryEndpoint` to use PAR

## 0.0.1

#### Added
- Added `ping_journey`, a Pigeon-generated bridge over the native Ping Journey SDK: `configureJourney`, `start`, `next`, `getSession`, `signOff`, and `dispose` [SDKS-4613]
- Added Dart sealed types for `JourneyNode` (`ContinueNode`/`SuccessNode`/`ErrorNode`/`FailureNode`) and the v1 callback set (`NameCallback`, `PasswordCallback`, `ValidatedUsernameCallback`, `ValidatedPasswordCallback`, `ChoiceCallback`, `KbaCreateCallback`, `TermsAndConditionsCallback`, `TextInputCallback`, `TextOutputCallback`, `StringAttributeInputCallback`, `NumberAttributeInputCallback`, `BooleanAttributeInputCallback`) [SDKS-4613]
- Pinned both platforms to native Ping SDK `2.0.0` (Android Maven, iOS SPM)
