/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingDavinci

/// Runs `PollingCollector.poll()` for Dart and hands each status to `emit`, tagged with the poll
/// id Dart chose, after `PollingStatusNormalizer` has put it in Android's order. In the plugin
/// `emit` is `DaVinciPollingEvents.send`, the one `pollingEvents` event channel.
///
/// Each poll is a `Task` consuming the SDK's `AsyncStream`. Cancelling it ends the consumption
/// and nothing more is reported, but **the SDK's own polling keeps running**: `poll()` produces
/// the stream from an unstructured `Task {}` that nothing cancels, so its sleeps and status
/// requests go on until it finishes by itself, at most `pollRetries × pollInterval` later. The
/// SDK offers no way to stop it. Android's `Flow` is cold and stops with its collector.
///
/// `dispatch` runs each delivery on the thread `emit` needs: Flutter's event sinks need the main
/// thread. Tests run it inline.
final class DaVinciPolling: @unchecked Sendable {
    private let emit: @Sendable (PollingEventMessage) -> Void
    private let dispatch: @Sendable (@escaping @Sendable () -> Void) -> Void
    private let lock = NSLock()
    private var polls: [String: Poll] = [:]

    init(
        emit: @escaping @Sendable (PollingEventMessage) -> Void,
        dispatch: @escaping @Sendable (@escaping @Sendable () -> Void) -> Void = { block in DispatchQueue.main.async(execute: block) }
    ) {
        self.emit = emit
        self.dispatch = dispatch
    }

    /// The polls whose task the bridge still holds.
    var activeCount: Int {
        lock.withLock { polls.count }
    }

    /// Starts polling `collector` for `daVinciId`, reporting as `pollId`.
    func start(daVinciId: String, pollId: String, collector: PollingCollector) throws {
        let poll = Poll(daVinciId: daVinciId)
        try lock.withLock {
            guard polls[pollId] == nil else {
                throw DaVinciHostApiError.argument("Poll id \(pollId) is already running")
            }
            polls[pollId] = poll
        }
        poll.task = Task { [weak self] in
            await self?.run(pollId, poll, collector)
            self?.release(pollId, poll)
        }
    }

    /// Cancels `pollId` and waits for its task to finish. Unknown ids are ignored.
    func cancel(_ pollId: String) async {
        let poll = lock.withLock { polls.removeValue(forKey: pollId) }
        await poll?.stop()
    }

    /// Cancels every poll of `daVinciId`: on start-over, flow advance, sign-off and dispose.
    func cancelAll(daVinciId: String) async {
        let matching = lock.withLock {
            let ids = polls.filter { $0.value.daVinciId == daVinciId }.map(\.key)
            return ids.compactMap { polls.removeValue(forKey: $0) }
        }
        for poll in matching {
            await poll.stop()
        }
    }

    private func run(_ pollId: String, _ poll: Poll, _ collector: PollingCollector) async {
        var normalizer = PollingStatusNormalizer(
            challengeMode: collector.pollChallengeStatus && !collector.challenge.isEmpty
        )
        var terminal = false
        for await status in collector.poll() {
            for normalized in normalizer.next(status) {
                if case .continue = normalized {} else { terminal = true }
                send(poll, DaVinciPollingMapper.event(pollId, normalized))
            }
        }
        if !terminal && !Task.isCancelled {
            send(poll, DaVinciPollingMapper.error(pollId, "Polling ended without a final status"))
        }
    }

    /// Drops the event if the poll was cancelled before the main thread delivers it.
    private func send(_ poll: Poll, _ event: PollingEventMessage) {
        let emit = self.emit
        dispatch {
            if poll.isActive { emit(event) }
        }
    }

    private func release(_ pollId: String, _ poll: Poll) {
        lock.withLock {
            if polls[pollId] === poll { polls.removeValue(forKey: pollId) }
        }
    }

    private final class Poll: @unchecked Sendable {
        let daVinciId: String
        private let lock = NSLock()
        private var active = true
        private var storedTask: Task<Void, Never>?

        init(daVinciId: String) {
            self.daVinciId = daVinciId
        }

        var isActive: Bool { lock.withLock { active } }

        var task: Task<Void, Never>? {
            get { lock.withLock { storedTask } }
            set {
                let cancelled = lock.withLock {
                    storedTask = newValue
                    return !active
                }
                if cancelled { newValue?.cancel() }
            }
        }

        func stop() async {
            let task = lock.withLock {
                active = false
                return storedTask
            }
            task?.cancel()
            await task?.value
        }
    }
}

/// Puts iOS's polling statuses in the order Android emits them, so Dart sees one sequence.
///
/// - **Challenge mode:** iOS reports `.continue(n)` *before* attempt `n`'s request, Android
///   reports `Continue(n)` *after* it came back incomplete. So iOS emits one `.continue` too many
///   whenever an attempt completes, expires or fails: `continue(1), continue(2), complete` where
///   Android emits `Continue(1), complete`. Each `.continue` is held until the next status: a
///   following `.continue` or `.timedOut` means its attempt came back incomplete, so it is sent;
///   anything else means its attempt ended the poll, so it is dropped. The timing matches
///   Android's too, since iOS yields the next `.continue` as soon as a request returns.
/// - **Simple mode:** both platforms report each cycle as one `.complete("continue")` or
///   `.timedOut`; iOS adds a `.continue` before its sleep, which is dropped.
///
/// What it can't align: iOS retries a `5xx` status response (it shows up here as an incomplete
/// attempt) and reports any other `4xx` as `.expired`; Android ends with `Error` on any non-`200`
/// unless the body's `serviceName` is `challengeExpired`.
struct PollingStatusNormalizer {
    let challengeMode: Bool
    private var pending: PollingStatus?

    init(challengeMode: Bool) {
        self.challengeMode = challengeMode
    }

    /// The statuses to send now that `status` arrived.
    mutating func next(_ status: PollingStatus) -> [PollingStatus] {
        let held = pending
        pending = nil
        switch status {
        case .continue:
            guard challengeMode else { return [] }
            pending = status
            return held.map { [$0] } ?? []
        case .timedOut:
            return (held.map { [$0] } ?? []) + [status]
        case .expired, .error, .complete:
            return [status]
        }
    }
}

/// Maps a native `PollingStatus` to its wire `PollingEventMessage`. Mirrors the Android mapper.
enum DaVinciPollingMapper {
    static func event(_ pollId: String, _ status: PollingStatus) -> PollingEventMessage {
        switch status {
        case .continue(let retryCount, let maxRetries):
            return PollingEventMessage(
                pollId: pollId, kind: .continuing, retryCount: Int64(retryCount), maxRetries: Int64(maxRetries)
            )
        case .timedOut:
            return PollingEventMessage(pollId: pollId, kind: .timedOut)
        case .expired:
            return PollingEventMessage(pollId: pollId, kind: .expired)
        case .error(let error):
            return self.error(pollId, (error as? LocalizedError)?.errorDescription ?? "\(error)")
        case .complete(let status):
            return PollingEventMessage(pollId: pollId, kind: .complete, status: status)
        }
    }

    static func error(_ pollId: String, _ message: String) -> PollingEventMessage {
        PollingEventMessage(pollId: pollId, kind: .error, errorMessage: message)
    }
}

/// The `pollingEvents` event channel's handler: holds Dart's sink while Dart listens. Events sent
/// while nobody listens are dropped; Dart listens before it starts a poll.
final class DaVinciPollingEvents: PollingEventsStreamHandler, @unchecked Sendable {
    private var sink: PigeonEventSink<PollingEventMessage>?

    override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<PollingEventMessage>) {
        self.sink = sink
    }

    override func onCancel(withArguments arguments: Any?) {
        sink = nil
    }

    /// Call on the main thread, where Flutter also calls `onListen`/`onCancel`.
    func send(_ event: PollingEventMessage) {
        sink?.success(event)
    }
}
