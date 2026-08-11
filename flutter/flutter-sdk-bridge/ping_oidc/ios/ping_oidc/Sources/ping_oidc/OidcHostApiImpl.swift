/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingBrowser
import PingOidc
import ping_core

/// Implements the generated `PingOidcHostApi`. `configureOidc`/`dispose` (Phase 2),
/// `createWebClient`/`authorize`/`hasUser` (Phase 3), and `token`/`refresh`/`userInfo`/`revoke`/
/// `signOff` (Phase 4) all have real bodies now.
final class OidcHostApiImpl: PingOidcHostApi, @unchecked Sendable {
    func configureOidc(config: OidcConfigMessage, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                let handleId = try await OidcClientFactory.create(config)
                completion(.success(handleId))
            } catch {
                completion(.failure(OidcErrorMapper.from(OidcErrorCodes.configure, error)))
            }
        }
    }

    func createWebClient(
        clientId: String,
        options: BrowserOptionsMessage?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        Task {
            do {
                let handleId = try await OidcWebClientFactory.create(clientHandleId: clientId, options: options)
                completion(.success(handleId))
            } catch {
                completion(.failure(OidcErrorMapper.from(OidcErrorCodes.createWebClient, error)))
            }
        }
    }

    func authorize(webClientId: String, completion: @escaping (Result<AuthorizeResultMessage, Error>) -> Void) {
        Task {
            guard let handle = await resolveWebClientHandle(webClientId) else {
                completion(.failure(OidcErrorMapper.from(
                    OidcErrorCodes.authorize, OidcHostApiError.stateError(
                        "OIDC web client instance not found for id=\(webClientId)"
                    )
                )))
                return
            }
            do {
                let result = try await handle.webClient.authorize()
                switch result {
                case .success:
                    completion(.success(AuthorizeResultMessage(type: .success)))
                case .failure(let error):
                    completion(mapAuthorizeFailure(error))
                }
            } catch {
                completion(.failure(OidcErrorMapper.from(OidcErrorCodes.authorize, error)))
            }
        }
    }

    /// A cancelled `ASWebAuthenticationSession` must resolve `AuthorizeResultMessage.type` as
    /// `.cancel`, not surface as a thrown/mapped error.
    ///
    /// TODO(SDKS-5295): ping-ios-sdk's `OidcWebClient.authorize()` collapses every
    /// `FailureNode.cause` into `OidcError.unknown(message:)`, discarding
    /// `BrowserError.externalUserAgentCancelled`'s type entirely (confirmed via source trace —
    /// `Web.swift`'s bare `catch` rewraps it as a string before it ever reaches here). This
    /// substring match on the resulting message is the only signal available today. It is
    /// fragile — it silently stops working if the SDK ever rewords the message — and should be
    /// removed once the native SDK preserves a distinguishable cancellation signal, tracked in
    /// SDKS-5295 to align it with Android's typed `BrowserCanceledException`.
    private func mapAuthorizeFailure(_ error: OidcError) -> Result<AuthorizeResultMessage, Error> {
        if plainErrorMessage(for: error).contains("cancelled by the user") {
            return .success(AuthorizeResultMessage(type: .cancel))
        }
        return .failure(OidcErrorMapper.from(OidcErrorCodes.authorize, error))
    }

    func hasUser(webClientId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            guard let handle = await resolveWebClientHandle(webClientId) else {
                completion(.failure(OidcErrorMapper.from(
                    OidcErrorCodes.hasUser, OidcHostApiError.stateError(
                        "OIDC web client instance not found for id=\(webClientId)"
                    )
                )))
                return
            }
            let user = await handle.webClient.user()
            completion(.success(user != nil))
        }
    }

    func token(webClientId: String, completion: @escaping (Result<TokenMessage, Error>) -> Void) {
        Task {
            guard let user = await resolveUser(webClientId) else {
                completion(.failure(OidcErrorMapper.from(
                    OidcErrorCodes.token, OidcHostApiError.stateError(
                        "No OIDC user session for id=\(webClientId)"
                    )
                )))
                return
            }
            switch await user.token() {
            case .success(let token):
                completion(.success(token.toMessage()))
            case .failure(let error):
                completion(.failure(OidcErrorMapper.from(OidcErrorCodes.token, error)))
            }
        }
    }

    // Go through `User.refresh()` on both platforms — iOS has no `OidcClient.refresh()`
    // equivalent, so this is also the only option, not just the preferred one.
    func refresh(webClientId: String, completion: @escaping (Result<TokenMessage, Error>) -> Void) {
        Task {
            guard let user = await resolveUser(webClientId) else {
                completion(.failure(OidcErrorMapper.from(
                    OidcErrorCodes.refresh, OidcHostApiError.stateError(
                        "No OIDC user session for id=\(webClientId)"
                    )
                )))
                return
            }
            switch await user.refresh() {
            case .success(let token):
                completion(.success(token.toMessage()))
            case .failure(let error):
                completion(.failure(OidcErrorMapper.from(OidcErrorCodes.refresh, error)))
            }
        }
    }

    func userInfo(
        webClientId: String,
        cache: Bool,
        completion: @escaping (Result<[String?: Any?], Error>) -> Void
    ) {
        Task {
            guard let user = await resolveUser(webClientId) else {
                completion(.failure(OidcErrorMapper.from(
                    OidcErrorCodes.userInfo, OidcHostApiError.stateError(
                        "No OIDC user session for id=\(webClientId)"
                    )
                )))
                return
            }
            // `cache` is always passed through explicitly — Android's own default is `false`,
            // iOS's is `true`; never rely on either platform default.
            switch await user.userinfo(cache: cache) {
            case .success(let info):
                let bridged: [String?: Any?] = info.reduce(into: [:]) { result, entry in
                    result[entry.key] = entry.value
                }
                completion(.success(bridged))
            case .failure(let error):
                completion(.failure(OidcErrorMapper.from(OidcErrorCodes.userInfo, error)))
            }
        }
    }

    func revoke(webClientId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            guard let user = await resolveUser(webClientId) else {
                completion(.failure(OidcErrorMapper.from(
                    OidcErrorCodes.revoke, OidcHostApiError.stateError(
                        "No OIDC user session for id=\(webClientId)"
                    )
                )))
                return
            }
            await user.revoke()
            completion(.success(()))
        }
    }

    // Known SDK gap (see IMPLEMENTATION_PLAN_OIDC.md Phase 4): the only reachable sign-off path
    // from a web-client id is `User.logout()`, which returns `Void` and discards the underlying
    // `signOff()` result — the boolean-returning `OidcClient.endSession()` is not reachable here.
    // `true` below means "logout completed without a bridge-level exception," not "a session
    // existed and was terminated."
    func signOff(webClientId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            guard let user = await resolveUser(webClientId) else {
                completion(.failure(OidcErrorMapper.from(
                    OidcErrorCodes.signOff, OidcHostApiError.stateError(
                        "No OIDC user session for id=\(webClientId)"
                    )
                )))
                return
            }
            await user.logout()
            completion(.success(true))
        }
    }

    func dispose(handleId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            // A dispose call may target either a client handle or a web-client handle; removal
            // is a no-op on an unknown id in both registries (SimpleRegistry.remove), so trying
            // both unconditionally is safe and avoids tracking which registry a given id came
            // from.
            await CoreRuntime.oidcClientRegistry.remove(handleId)
            await CoreRuntime.oidcWebClientRegistry.remove(handleId)
            completion(.success(()))
        }
    }

    private func resolveWebClientHandle(_ webClientId: String) async -> OidcWebClientHandle? {
        await CoreRuntime.oidcWebClientRegistry.resolve(webClientId) as? OidcWebClientHandle
    }

    /// Resolves `webClientId` to a live `User`, or `nil` if no session exists yet.
    private func resolveUser(_ webClientId: String) async -> User? {
        guard let handle = await resolveWebClientHandle(webClientId) else { return nil }
        return await handle.webClient.user()
    }
}

/// Maps a native `Token` onto the bridge's `TokenMessage` — fields match 1:1; `expiresAt`
/// (native's own expiry stamp) has no `TokenMessage` counterpart and is dropped.
private extension Token {
    func toMessage() -> TokenMessage {
        TokenMessage(
            accessToken: accessToken,
            tokenType: tokenType,
            scope: scope,
            expiresIn: expiresIn,
            refreshToken: refreshToken,
            idToken: idToken
        )
    }
}
