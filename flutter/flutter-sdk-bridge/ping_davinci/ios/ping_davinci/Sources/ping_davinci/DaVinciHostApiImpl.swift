/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingDavinci
import PingDavinciPlugin
import PingOidc
import PingOrchestrate
import ping_core

/// Implements the generated `PingDaVinciHostApi`. `configureDaVinci` builds the native workflow
/// and registers it in `CoreRuntime.davinciRegistry`; `start`/`next` drive it and cache the current
/// `ContinueNode` per handle so `next()` and `validate()` can re-resolve collectors by
/// `{type, index}`. After a recoverable `ErrorNode` the cached node is the one it can be retried
/// from. A `SuccessNode`'s session is cached too, for `getSession`; tokens and userinfo come from
/// the native user, which owns and stores them. Polls run in `polling`, which streams their
/// statuses to Dart; any call that moves a handle's flow on cancels that handle's polls first.
final class DaVinciHostApiImpl: PingDaVinciHostApi, @unchecked Sendable {
    private let lock = NSLock()

    /// The `pollingEvents` stream handler, registered by `PingDaVinciPlugin`.
    let pollingEvents: DaVinciPollingEvents

    private let polling: DaVinciPolling

    init() {
        let events = DaVinciPollingEvents()
        pollingEvents = events
        polling = DaVinciPolling { event in events.send(event) }
    }

    /// Most recent `ContinueNode` per daVinciId: the current form, or an ErrorNode's retry node.
    private var continueNodeMap: [String: ActiveNode] = [:]

    /// The session of the `SuccessNode` each daVinciId reached, until it starts over or signs off.
    private var successSessionMap: [String: Session] = [:]

    /// Serializes every call that reads or moves a handle's flow (`start`, `next`, `validate`,
    /// `startPolling`, `signOff`, `dispose`) per daVinciId, so none can apply values while another
    /// is reading or submitting the same collectors, and nothing cached or started can outlive
    /// `dispose`.
    private let flowSerializer = KeyedSerialExecutor()

    /// Stops reporting every poll. Invoked from `PingDaVinciPlugin.detachFromEngine`: the SDK's own
    /// polling tasks run on regardless (see `DaVinciPolling`).
    func shutdown() async {
        await polling.cancelAll()
    }

    func configureDaVinci(config: DaVinciConfigMessage, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await DaVinciFactory.create(config)))
            } catch {
                completion(.failure(DaVinciErrorMapper.from(DaVinciErrorCodes.configure, error)))
            }
        }
    }

    func start(daVinciId: String, completion: @escaping (Result<NodeMessage, Error>) -> Void) {
        Task {
            do {
                let message = try await flowSerializer.run(key: daVinciId) { [self] in
                    guard let handle = await self.resolveHandle(daVinciId) else { throw self.notFound(daVinciId) }
                    await self.polling.cancelAll(daVinciId: daVinciId)
                    let node = await handle.daVinci.start()
                    self.setNode(daVinciId: daVinciId, node: node)
                    return await DaVinciNodeMapper.map(node, daVinci: handle.daVinci)
                }
                completion(.success(message))
            } catch {
                completion(.failure(DaVinciErrorMapper.from(DaVinciErrorCodes.start, error)))
            }
        }
    }

    func next(
        daVinciId: String,
        values: [CollectorValueMessage?],
        completion: @escaping (Result<NodeMessage, Error>) -> Void
    ) {
        Task {
            do {
                let message = try await flowSerializer.run(key: daVinciId) { [self] in
                    guard let currentNode = self.activeContinueNode(daVinciId) else {
                        throw DaVinciHostApiError.stateError(
                            "No active ContinueNode found for daVinciId=\(daVinciId)"
                        )
                    }
                    guard let handle = await self.resolveHandle(daVinciId) else {
                        throw self.notFound(daVinciId)
                    }
                    try DaVinciCollectorValueApplier.apply(currentNode.collectors, values: values.compactMap { $0 })
                    // A finished poll has already set its collector's value; a running one is
                    // stopped so the bridge reports nothing more from it. The SDK's own polling
                    // task can't be stopped (see `DaVinciPolling`).
                    await self.polling.cancelAll(daVinciId: daVinciId)
                    // The SDK closes the submitted node itself (wiping Closeable collectors'
                    // values), so the bridge never calls close() here and never reads a collector
                    // of currentNode after this line.
                    let nextNode = await currentNode.next()
                    self.setNode(daVinciId: daVinciId, node: nextNode)
                    return await DaVinciNodeMapper.map(nextNode, daVinci: handle.daVinci)
                }
                completion(.success(message))
            } catch {
                completion(.failure(DaVinciErrorMapper.from(DaVinciErrorCodes.next, error)))
            }
        }
    }

    /// Applies `values` to the cached node's collectors, as `next()` would, then runs the SDK's
    /// `validate()` on each, with no network call. `next()` never validates: the two are
    /// independent, as in both native SDKs, and the values applied here stay applied.
    func validate(
        daVinciId: String,
        values: [CollectorValueMessage?],
        completion: @escaping (Result<[ValidationErrorMessage?], Error>) -> Void
    ) {
        Task {
            do {
                let errors = try await flowSerializer.run(key: daVinciId) { [self] in
                    guard let currentNode = self.activeContinueNode(daVinciId) else {
                        throw DaVinciHostApiError.stateError(
                            "No active ContinueNode found for daVinciId=\(daVinciId)"
                        )
                    }
                    try DaVinciCollectorValueApplier.apply(currentNode.collectors, values: values.compactMap { $0 })
                    return DaVinciValidationMapper.validate(currentNode.collectors)
                }
                completion(.success(errors))
            } catch {
                completion(.failure(DaVinciErrorMapper.from(DaVinciErrorCodes.validate, error)))
            }
        }
    }

    /// A query: nil until this handle reaches a `SuccessNode`.
    func getSession(daVinciId: String, completion: @escaping (Result<SessionMessage?, Error>) -> Void) {
        Task {
            guard await resolveHandle(daVinciId) != nil else {
                completion(.failure(DaVinciErrorMapper.from(DaVinciErrorCodes.getSession, notFound(daVinciId))))
                return
            }
            do {
                completion(.success(try successSession(daVinciId).map(DaVinciSessionMapper.session)))
            } catch {
                completion(.failure(DaVinciErrorMapper.from(DaVinciErrorCodes.getSession, error)))
            }
        }
    }

    /// iOS defers the code exchange to the first `token()` after the `SuccessNode`; later calls
    /// read the stored token, refreshing it if it has expired.
    func getToken(daVinciId: String, completion: @escaping (Result<TokenMessage, Error>) -> Void) {
        Task {
            do {
                let user = try await requireUser(daVinciId)
                switch await user.token() {
                case .success(let token):
                    completion(.success(DaVinciSessionMapper.token(token)))
                case .failure(let error):
                    completion(.failure(DaVinciErrorMapper.from(DaVinciErrorCodes.getToken, error)))
                }
            } catch {
                completion(.failure(DaVinciErrorMapper.from(DaVinciErrorCodes.getToken, error)))
            }
        }
    }

    func getUserInfo(
        daVinciId: String,
        cache: Bool,
        completion: @escaping (Result<[String?: Any?], Error>) -> Void
    ) {
        Task {
            do {
                let user = try await requireUser(daVinciId)
                switch await user.userinfo(cache: cache) {
                case .success(let userInfo):
                    completion(.success(DaVinciSessionMapper.userInfo(userInfo)))
                case .failure(let error):
                    completion(.failure(DaVinciErrorMapper.from(DaVinciErrorCodes.getUserInfo, error)))
                }
            } catch {
                completion(.failure(DaVinciErrorMapper.from(DaVinciErrorCodes.getUserInfo, error)))
            }
        }
    }

    /// `Workflow.signOff()` ends the OIDC session (revoking the stored tokens) and deletes the
    /// persisted session cookies. Its failure is reported as `false`, not thrown; only a missing
    /// handle throws.
    ///
    /// The SDK's `signOff()` leaves the cached `UserDelegate` in `sharedContext`, and
    /// `daVinciUser()` returns that cache before it checks cookies, so a later `token()` would
    /// still find a user, and would even redeem a code that was never exchanged. The bridge drops
    /// the cache first, exactly as the SDK's own `UserDelegate.logout()` does, but keeps the
    /// `signOff()` result that `logout()` discards.
    func signOff(daVinciId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            do {
                let signedOff = try await flowSerializer.run(key: daVinciId) { [self] in
                    guard let handle = await self.resolveHandle(daVinciId) else { throw self.notFound(daVinciId) }
                    await self.polling.cancelAll(daVinciId: daVinciId)
                    _ = handle.daVinci.sharedContext.removeValue(forKey: SharedContext.Keys.userKey)
                    let signedOff: Bool
                    switch await handle.daVinci.signOff() {
                    case .success:
                        signedOff = true
                    case .failure(let error):
                        NSLog("PingDaVinci: signOff failed for daVinciId=%@: %@", daVinciId, "\(error)")
                        signedOff = false
                    }
                    self.clearNodeState(daVinciId: daVinciId)
                    return signedOff
                }
                completion(.success(signedOff))
            } catch {
                completion(.failure(DaVinciErrorMapper.from(DaVinciErrorCodes.signOff, error)))
            }
        }
    }

    /// Waits for the call ahead of it in the handle's serializer, then removes the handle before
    /// anything else, so a call queued behind it fails as not found instead of caching a node or
    /// starting a poll. The serializer drops the key itself once its queue drains. Disposing an
    /// unknown id is a no-op.
    func dispose(daVinciId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await flowSerializer.run(key: daVinciId) { [self] in
                    await CoreRuntime.davinciRegistry.remove(daVinciId)
                    await self.polling.cancelAll(daVinciId: daVinciId)
                    self.clearNodeState(daVinciId: daVinciId)
                }
                completion(.success(()))
            } catch {
                completion(.failure(DaVinciErrorMapper.from(DaVinciErrorCodes.dispose, error)))
            }
        }
    }

    func retainedState(completion: @escaping (Result<RetainedStateMessage, Error>) -> Void) {
        Task {
            let registeredHandles = await CoreRuntime.davinciRegistry.count()
            let flowLocks = await flowSerializer.count
            let (cachedNodes, cachedSessions) = lock.withLock { (continueNodeMap.count, successSessionMap.count) }
            completion(.success(RetainedStateMessage(
                registeredHandles: Int64(registeredHandles),
                cachedNodes: Int64(cachedNodes),
                cachedSessions: Int64(cachedSessions),
                flowLocks: Int64(flowLocks),
                activePolls: Int64(polling.activeCount)
            )))
        }
    }

    func registeredCollectorTypes(daVinciId: String, completion: @escaping (Result<[String], Error>) -> Void) {
        Task {
            guard let handle = await resolveHandle(daVinciId) else {
                completion(.failure(DaVinciErrorMapper.from(
                    DaVinciErrorCodes.registeredCollectorTypes, notFound(daVinciId)
                )))
                return
            }
            completion(.success(await CoreCollectorRegistration.resolvableTypes(daVinci: handle.daVinci)))
        }
    }

    /// Resolves the `POLLING` collector by `{collectorType, index}` on the cached node, through the
    /// same serializer as `next()`, so a poll can't start on a node that is being submitted.
    func startPolling(
        daVinciId: String,
        pollId: String,
        collectorType: String,
        index: Int64,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        Task {
            do {
                try await flowSerializer.run(key: daVinciId) { [self] in
                    guard await self.resolveHandle(daVinciId) != nil else { throw self.notFound(daVinciId) }
                    guard let currentNode = self.activeContinueNode(daVinciId) else {
                        throw DaVinciHostApiError.stateError(
                            "No active ContinueNode found for daVinciId=\(daVinciId)"
                        )
                    }
                    let collectors = currentNode.collectors
                    guard collectors.indices.contains(Int(index)) else {
                        throw DaVinciHostApiError.argument(
                            "No collector at index=\(index) (the node has \(collectors.count))"
                        )
                    }
                    let collector = collectors[Int(index)]
                    let actual = DaVinciCollectorMapper.collectorType(collector)
                    guard actual == collectorType else {
                        throw DaVinciHostApiError.argument("Collector at index=\(index) is \(actual), not \(collectorType)")
                    }
                    guard let pollingCollector = collector as? PollingCollector else {
                        throw DaVinciHostApiError.argument("\(collectorType) at index=\(index) is not a polling collector")
                    }
                    try self.polling.start(daVinciId: daVinciId, pollId: pollId, collector: pollingCollector)
                }
                completion(.success(()))
            } catch {
                completion(.failure(DaVinciErrorMapper.from(DaVinciErrorCodes.startPolling, error)))
            }
        }
    }

    func cancelPolling(pollId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            await polling.cancel(pollId)
            completion(.success(()))
        }
    }

    func activePollCount(completion: @escaping (Result<Int64, Error>) -> Void) {
        completion(.success(Int64(polling.activeCount)))
    }

    private func resolveHandle(_ daVinciId: String) async -> DaVinciHandle? {
        await CoreRuntime.davinciRegistry.resolve(daVinciId) as? DaVinciHandle
    }

    private func notFound(_ daVinciId: String) -> DaVinciHostApiError {
        .daVinciNotFound("DaVinci instance not found for id=\(daVinciId)")
    }

    private func activeContinueNode(_ daVinciId: String) -> ContinueNode? {
        lock.lock()
        defer { lock.unlock() }
        return continueNodeMap[daVinciId]?.node
    }

    private func successSession(_ daVinciId: String) -> Session? {
        lock.lock()
        defer { lock.unlock() }
        return successSessionMap[daVinciId]
    }

    /// The signed-in user, or a typed `state` error. Uses `daVinciUser()`, not the deprecated
    /// `user()`. It returns the user cached at `SuccessNode` time without checking cookies (Android
    /// requires the persisted session cookie on every call); the bridge drops that cache on
    /// sign-off, so the two agree on every path the bridge drives.
    private func requireUser(_ daVinciId: String) async throws -> any User {
        guard let handle = await resolveHandle(daVinciId) else { throw notFound(daVinciId) }
        guard let user = await handle.daVinci.daVinciUser() else {
            throw DaVinciHostApiError.stateError(
                "No signed-in DaVinci user for daVinciId=\(daVinciId): complete the flow first"
            )
        }
        return user
    }

    /// A recoverable `ErrorNode` keeps its retry node (`continueNode`, normally the node just
    /// submitted) as the active one, so the app can correct a value and submit again. Nothing is
    /// closed here: the SDK closes every node it submits.
    private func setNode(daVinciId: String, node: Node) {
        lock.lock()
        defer { lock.unlock() }
        if let continueNode = node as? ContinueNode {
            continueNodeMap[daVinciId] = ActiveNode(node: continueNode, submitted: false)
        } else if let retryNode = (node as? ErrorNode)?.continueNode {
            continueNodeMap[daVinciId] = ActiveNode(node: retryNode, submitted: true)
        } else {
            continueNodeMap.removeValue(forKey: daVinciId)
        }
        successSessionMap[daVinciId] = (node as? SuccessNode)?.session
    }

    /// Drops the cached nodes. Only a never-submitted node is closed (so its Closeable collectors
    /// drop their values): the SDK already closed an ErrorNode's retry node when it was submitted.
    private func clearNodeState(daVinciId: String) {
        lock.lock()
        successSessionMap.removeValue(forKey: daVinciId)
        let active = continueNodeMap.removeValue(forKey: daVinciId)
        lock.unlock()
        if let active, !active.submitted {
            active.node.close()
        }
    }
}

/// A cached `ContinueNode`, and whether the SDK has already submitted (and closed) it.
private struct ActiveNode {
    let node: ContinueNode
    let submitted: Bool
}
