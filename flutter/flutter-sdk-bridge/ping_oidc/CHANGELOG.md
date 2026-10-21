## Unreleased

#### Updated
- Bumped to native Ping SDK `2.2.0` (Android Maven, iOS SPM)

#### Changed
- Android: an `openId`-only config no longer fails `authorize()` with "lateinit property discoveryEndpoint has not been initialized". Works around a native 2.2.0 `OidcClientConfig.clone()` bug by initializing `discoveryEndpoint` to `""` (never fetched when `openId` is set)
- iOS: an `openId`-only config (no `discoveryEndpoint`) is now accepted instead of rejected with an `argument` error. When `openId` is supplied it is assigned directly and discovery is skipped, even if `discoveryEndpoint` is also set, the same as Android. Previously iOS ran discovery and overlaid `openId` on the result
- iOS: native `OidcError.configurationError` (new in 2.2.0) maps to `PingException.type == "argument"`

## 0.0.1

#### Added
- Added `ping_oidc`, a Pigeon-generated bridge over the native Ping OIDC SDK: `configureOidc`, `createWebClient`, `authorize`, `hasUser`, `token`, `refresh`, `userInfo`, `revoke`, `signOff`, and `dispose` [SDKS-5265]
- Pinned both platforms to native Ping SDK `2.1.0` (Android Maven, iOS SPM)
