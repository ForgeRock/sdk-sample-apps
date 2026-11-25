/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingJourney
import PingOidc
import PingOrchestrate
import ping_core

/// Implements the generated `PingJourneyHostApi`: `configureJourney`/`start` build the native
/// `Journey` and cache the current node on its `JourneyHandle`; `next()` applies submitted callback
/// values onto that cached node and advances the flow.
final class JourneyHostApiImpl: PingJourneyHostApi, @unchecked Sendable {
    func configureJourney(config: JourneyConfigMessage, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                let journeyId = try await JourneyClientFactory.create(config)
                completion(.success(journeyId))
            } catch {
                completion(.failure(JourneyErrorMapper.from(JourneyErrorCodes.configure, error)))
            }
        }
    }

    func start(
        journeyId: String,
        name: String,
        options: StartOptionsMessage,
        completion: @escaping (Result<NodeMessage, Error>) -> Void
    ) {
        Task {
            guard let handle = await resolveHandle(journeyId) else {
                completion(.failure(JourneyErrorMapper.from(
                    JourneyErrorCodes.start, JourneyHostApiError.journeyNotFound(journeyId)
                )))
                return
            }
            do {
                // On the same serializer as next() and an add-on's withItem, so a restart can't
                // swap the node while either is still using the previous one.
                let node = try await handle.activeNode.startWith {
                    await handle.journey.start(name) { startOptions in
                        startOptions.forceAuth = options.forceAuth
                        startOptions.noSession = options.noSession
                    }
                }
                completion(.success(JourneyNodeMapper.map(node)))
            } catch {
                completion(.failure(JourneyErrorMapper.from(JourneyErrorCodes.start, error)))
            }
        }
    }

    func next(
        journeyId: String,
        values: [CallbackValueMessage?],
        completion: @escaping (Result<NodeMessage, Error>) -> Void
    ) {
        Task {
            do {
                guard let handle = await resolveHandle(journeyId) else {
                    throw JourneyHostApiError.journeyNotFound(journeyId)
                }
                let submitted = values.compactMap { $0 }
                // Same lock an add-on's withItem takes, so a double-submit can't race two callback
                // applications and a collect can't race a submit.
                let message = try await handle.activeNode.withLock {
                    guard let currentNode = handle.activeNode.current else {
                        throw JourneyHostApiError.stateError(
                            "No active ContinueNode found for journeyId=\(journeyId)"
                        )
                    }
                    try JourneyCallbackValueApplier.apply(currentNode, values: submitted)
                    let nextNode = await currentNode.next()
                    handle.activeNode.set(nextNode)
                    return JourneyNodeMapper.map(nextNode)
                }
                completion(.success(message))
            } catch {
                completion(.failure(JourneyErrorMapper.from(JourneyErrorCodes.next, error)))
            }
        }
    }

    func getSession(journeyId: String, completion: @escaping (Result<SessionMessage?, Error>) -> Void) {
        Task {
            guard let handle = await resolveHandle(journeyId) else {
                completion(.failure(JourneyErrorMapper.from(
                    JourneyErrorCodes.getSession, JourneyHostApiError.journeyNotFound(journeyId)
                )))
                return
            }
            guard handle.hasOidc, let user = await handle.journey.journeyUser() else {
                completion(.success(nil))
                return
            }
            let tokenResult = await user.token()
            switch tokenResult {
            case .success(let token):
                var userInfoMap: [String?: Any?]? = nil
                let uiResult = await user.userinfo(cache: false)
                switch uiResult {
                case .success(let userInfo):
                    userInfoMap = userInfo as? [String?: Any?]
                case .failure(let error):
                    NSLog("JourneyHostApiImpl: userinfo() failed for journeyId=%@: %@", journeyId, "\(error)")
                }
                let session = SessionMessage(
                    accessToken: token.accessToken,
                    refreshToken: token.refreshToken,
                    idToken: token.idToken,
                    tokenType: token.tokenType,
                    scope: token.scope,
                    expiresIn: token.expiresIn,
                    userInfo: userInfoMap
                )
                completion(.success(session))
            case .failure(let error):
                completion(.failure(JourneyErrorMapper.from(JourneyErrorCodes.getSession, error)))
            }
        }
    }

    func refreshToken(journeyId: String, completion: @escaping (Result<SessionMessage, Error>) -> Void) {
        Task {
            switch await requireOidcUser(journeyId, operation: "refreshToken", code: JourneyErrorCodes.refreshToken) {
            case .failure(let error):
                completion(.failure(error))
                return
            case .success(let user):
                let refreshResult = await user.refresh()
                switch refreshResult {
                case .success(let token):
                    // userInfo is deliberately nil here — claims are fetched separately
                    // via getUserInfo, so callers keep whatever they already loaded.
                    let session = SessionMessage(
                        accessToken: token.accessToken,
                        refreshToken: token.refreshToken,
                        idToken: token.idToken,
                        tokenType: token.tokenType,
                        scope: token.scope,
                        expiresIn: token.expiresIn
                    )
                    completion(.success(session))
                case .failure(let error):
                    completion(.failure(JourneyErrorMapper.from(
                        JourneyErrorCodes.refreshToken, error
                    )))
                }
            }
        }
    }

    func revokeToken(journeyId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            switch await requireOidcUser(journeyId, operation: "revokeToken", code: JourneyErrorCodes.revokeToken) {
            case .failure(let error):
                completion(.failure(error))
                return
            case .success(let user):
                // Native swallows server-side revocation errors, matching ping_oidc's revoke.
                await user.revoke()
                completion(.success(()))
            }
        }
    }

    func getUserInfo(journeyId: String, cache: Bool, completion: @escaping (Result<[String?: Any?], Error>) -> Void) {
        Task {
            switch await requireOidcUser(journeyId, operation: "getUserInfo", code: JourneyErrorCodes.getUserInfo) {
            case .failure(let error):
                completion(.failure(error))
                return
            case .success(let user):
                // cache is always passed explicitly — the native SDKs' own defaults differ
                // (Android false, iOS true).
                let uiResult = await user.userinfo(cache: cache)
                switch uiResult {
                case .success(let userInfo):
                    completion(.success(userInfo as? [String?: Any?] ?? [:]))
                case .failure(let error):
                    completion(.failure(JourneyErrorMapper.from(
                        JourneyErrorCodes.getUserInfo, error
                    )))
                }
            }
        }
    }

    /// Resolves the OIDC user for the token-command methods, returning a typed
    /// failure when the Journey has no OIDC configuration or no user session —
    /// unlike `getSession`, which is a query and returns nil instead (nil =
    /// "nothing to show"; a command must fail loudly). The caller completes
    /// with the returned error, if any.
    private func requireOidcUser(
        _ journeyId: String,
        operation: String,
        code: String
    ) async -> Result<any User, Error> {
        guard let handle = await resolveHandle(journeyId) else {
            return .failure(JourneyErrorMapper.from(
                code, JourneyHostApiError.journeyNotFound(journeyId)
            ))
        }
        if !handle.hasOidc {
            return .failure(JourneyErrorMapper.from(
                code,
                JourneyHostApiError.stateError(
                    "\(operation) requires OIDC configuration; this Journey has none (journeyId=\(journeyId))"
                )
            ))
        }
        guard let user = await handle.journey.journeyUser() else {
            return .failure(JourneyErrorMapper.from(
                code,
                JourneyHostApiError.stateError(
                    "No user session for journeyId=\(journeyId) — complete the Journey first"
                )
            ))
        }
        return .success(user)
    }

    func signOff(journeyId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            guard let handle = await resolveHandle(journeyId) else {
                completion(.failure(JourneyErrorMapper.from(
                    JourneyErrorCodes.signOff, JourneyHostApiError.journeyNotFound(journeyId)
                )))
                return
            }
            let signOffResult = await handle.journey.signOff()
            if case .failure(let error) = signOffResult {
                completion(.failure(JourneyErrorMapper.from(JourneyErrorCodes.signOff, error)))
                return
            }
            if handle.hasOidc {
                let user = await handle.journey.journeyUser()
                await user?.logout()
            }
            do {
                try await handle.activeNode.clear()
                completion(.success(true))
            } catch {
                completion(.failure(JourneyErrorMapper.from(JourneyErrorCodes.signOff, error)))
            }
        }
    }

    func dispose(journeyId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            // Unregister first, so no new add-on call can resolve the Journey, then close its node;
            // clear() waits for an operation still running on that node.
            let handle = await resolveHandle(journeyId)
            await CoreRuntime.journeyRegistry.remove(journeyId)
            do {
                try await handle?.activeNode.clear()
                completion(.success(()))
            } catch {
                completion(.failure(JourneyErrorMapper.from(JourneyErrorCodes.dispose, error)))
            }
        }
    }

    private func resolveHandle(_ journeyId: String) async -> JourneyHandle? {
        await CoreRuntime.journeyRegistry.resolve(journeyId) as? JourneyHandle
    }
}

enum JourneyHostApiError: Error, CustomStringConvertible {
    case journeyNotFound(String)
    case unsupported(String)
    case stateError(String)
    case callbackApply(String)
    case argument(String)

    /// Plain message text, matching Kotlin's `IllegalStateException.message`/etc. shape rather
    /// than Swift's default enum-case reflection (e.g. `stateError("...")`).
    var description: String {
        switch self {
        case .journeyNotFound(let message),
             .unsupported(let message),
             .stateError(let message),
             .callbackApply(let message),
             .argument(let message):
            return message
        }
    }
}
