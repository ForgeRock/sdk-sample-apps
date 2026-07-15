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

    /// Most recent `Node` per journeyId.
    private var nodeMap: [String: Node] = [:]

    /// Most recent `ContinueNode` per journeyId, for future callback re-resolution.
    private var continueNodeMap: [String: ContinueNode] = [:]

    func configureJourney(config: JourneyConfigMessage, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            let journeyId = await JourneyClientFactory.create(config)
            completion(.success(journeyId))
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
            guard let currentNode = activeContinueNode(journeyId) else {
                completion(.failure(JourneyErrorMapper.from(
                    JourneyErrorCodes.next,
                    JourneyHostApiError.stateError(
                        "No active ContinueNode found for journeyId=\(journeyId)"
                    )
                )))
                return
            }
            do {
                try JourneyCallbackValueApplier.apply(currentNode, values: values.compactMap { $0 })
                let nextNode = await currentNode.next()
                setNode(journeyId: journeyId, node: nextNode)
                completion(.success(JourneyNodeMapper.map(nextNode)))
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
                if case .success(let userInfo) = uiResult {
                    userInfoMap = userInfo as? [String?: Any?]
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
            closeAndClearNodeState(journeyId: journeyId)
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
        nodeMap[journeyId] = node
        if let continueNode = node as? ContinueNode {
            continueNodeMap[journeyId] = continueNode
        } else {
            continueNodeMap.removeValue(forKey: journeyId)
        }
    }

    private func clearNodeState(journeyId: String) {
        lock.lock()
        defer { lock.unlock() }
        nodeMap.removeValue(forKey: journeyId)
        continueNodeMap.removeValue(forKey: journeyId)
    }

    /// Closes the cached `ContinueNode` (mirrors Android's `removeJourney()`) before dropping it,
    /// so any `Closeable` actions on the last node get a chance to release resources.
    private func closeAndClearNodeState(journeyId: String) {
        lock.lock()
        defer { lock.unlock() }
        nodeMap.removeValue(forKey: journeyId)
        continueNodeMap.removeValue(forKey: journeyId)?.close()
    }
}

enum JourneyHostApiError: Error {
    case journeyNotFound(String)
    case unsupported(String)
    case stateError(String)
    case callbackApply(String)
}
