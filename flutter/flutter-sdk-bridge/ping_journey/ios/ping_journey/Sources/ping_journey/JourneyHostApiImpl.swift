/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingJourney
import PingOrchestrate
import ping_core

/// Implements the generated `PingJourneyHostApi`: `configureJourney`/`start` build the native
/// `Journey` and cache the current node per `journeyId`; `next()` applies submitted callback
/// values onto the cached `ContinueNode` and advances the flow.
final class JourneyHostApiImpl: PingJourneyHostApi, @unchecked Sendable {
    private let lock = NSLock()

    /// Most recent `ContinueNode` per journeyId, for future callback re-resolution.
    private var continueNodeMap: [String: ContinueNode] = [:]

    /// Serializes `next()` per journeyId so a double-submit can't race two callback applications.
    private let nextSerializer = KeyedSerialExecutor()

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
            guard let journey = await resolveJourney(journeyId) else {
                completion(.failure(JourneyErrorMapper.from(
                    JourneyErrorCodes.start, JourneyHostApiError.journeyNotFound(journeyId)
                )))
                return
            }
            let node = await journey.start(name) { startOptions in
                startOptions.forceAuth = options.forceAuth
                startOptions.noSession = options.noSession
            }
            setNode(journeyId: journeyId, node: node)
            completion(.success(JourneyNodeMapper.map(node)))
        }
    }

    func next(
        journeyId: String,
        values: [CallbackValueMessage?],
        completion: @escaping (Result<NodeMessage, Error>) -> Void
    ) {
        Task {
            do {
                let message = try await nextSerializer.run(key: journeyId) { [self] in
                    guard let currentNode = self.activeContinueNode(journeyId) else {
                        throw JourneyHostApiError.stateError(
                            "No active ContinueNode found for journeyId=\(journeyId)"
                        )
                    }
                    try JourneyCallbackValueApplier.apply(currentNode, values: values.compactMap { $0 })
                    let nextNode = await currentNode.next()
                    self.setNode(journeyId: journeyId, node: nextNode)
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
                    expiresIn: token.expiresIn,
                    userInfo: userInfoMap
                )
                completion(.success(session))
            case .failure(let error):
                completion(.failure(JourneyErrorMapper.from(JourneyErrorCodes.getSession, error)))
            }
        }
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
            clearNodeState(journeyId: journeyId)
            completion(.success(true))
        }
    }

    func dispose(journeyId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            clearNodeState(journeyId: journeyId)
            await nextSerializer.remove(key: journeyId)
            await CoreRuntime.journeyRegistry.remove(journeyId)
            completion(.success(()))
        }
    }

    private func resolveJourney(_ journeyId: String) async -> Journey? {
        await resolveHandle(journeyId)?.journey
    }

    private func resolveHandle(_ journeyId: String) async -> JourneyHandle? {
        await CoreRuntime.journeyRegistry.resolve(journeyId) as? JourneyHandle
    }

    private func activeContinueNode(_ journeyId: String) -> ContinueNode? {
        lock.lock()
        defer { lock.unlock() }
        return continueNodeMap[journeyId]
    }

    private func setNode(journeyId: String, node: Node) {
        lock.lock()
        defer { lock.unlock() }
        if let continueNode = node as? ContinueNode {
            continueNodeMap[journeyId] = continueNode
        } else {
            continueNodeMap.removeValue(forKey: journeyId)
        }
    }

    /// Closes the cached `ContinueNode` (mirrors Android's `removeJourney()`) before dropping it,
    /// so any `Closeable` actions on the last node get a chance to release resources.
    private func clearNodeState(journeyId: String) {
        lock.lock()
        defer { lock.unlock() }
        continueNodeMap.removeValue(forKey: journeyId)?.close()
    }
}

enum JourneyHostApiError: Error, CustomStringConvertible {
    case journeyNotFound(String)
    case unsupported(String)
    case stateError(String)
    case callbackApply(String)

    /// Plain message text, matching Kotlin's `IllegalStateException.message`/etc. shape rather
    /// than Swift's default enum-case reflection (e.g. `stateError("...")`).
    var description: String {
        switch self {
        case .journeyNotFound(let message),
             .unsupported(let message),
             .stateError(let message),
             .callbackApply(let message):
            return message
        }
    }
}
