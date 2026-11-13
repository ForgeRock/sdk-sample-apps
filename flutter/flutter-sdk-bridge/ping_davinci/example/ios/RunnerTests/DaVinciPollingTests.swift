/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import XCTest
import PingDavinci
@testable import ping_davinci

/// `PollingStatusNormalizer` turns iOS's status sequences into the ones Android's `Flow` emits
/// for the same server responses (each expected sequence is what ping-android-sdk 2.2.0's
/// `PollingCollector.pollStatus()` yields; its `PollingCollectorE2ETests` pins the timeout one).
/// Then the runner, on real simple-mode collectors; Android's `DaVinciPollingTest` mirrors it.
final class DaVinciPollingTests: XCTestCase {
    private func normalized(_ statuses: [PollingStatus], challengeMode: Bool) -> [PollingEventMessage] {
        var normalizer = PollingStatusNormalizer(challengeMode: challengeMode)
        return statuses.flatMap { normalizer.next($0) }.map { DaVinciPollingMapper.event("p", $0) }
    }

    private func events(_ statuses: [PollingStatus]) -> [PollingEventMessage] {
        statuses.map { DaVinciPollingMapper.event("p", $0) }
    }

    func testChallengeModeMatchesAndroidForEveryEnding() {
        let cases: [(ios: [PollingStatus], android: [PollingStatus], name: String)] = [
            (
                [.continue(retryCount: 1, maxRetries: 3), .continue(retryCount: 2, maxRetries: 3),
                 .continue(retryCount: 3, maxRetries: 3), .timedOut],
                [.continue(retryCount: 1, maxRetries: 3), .continue(retryCount: 2, maxRetries: 3),
                 .continue(retryCount: 3, maxRetries: 3), .timedOut],
                "times out"
            ),
            (
                [.continue(retryCount: 1, maxRetries: 3), .continue(retryCount: 2, maxRetries: 3),
                 .continue(retryCount: 3, maxRetries: 3), .complete(status: "approved")],
                [.continue(retryCount: 1, maxRetries: 3), .continue(retryCount: 2, maxRetries: 3),
                 .complete(status: "approved")],
                "completes on the third attempt"
            ),
            (
                [.continue(retryCount: 1, maxRetries: 3), .complete(status: "approved")],
                [.complete(status: "approved")],
                "completes on the first attempt"
            ),
            (
                [.continue(retryCount: 1, maxRetries: 3), .continue(retryCount: 2, maxRetries: 3), .expired],
                [.continue(retryCount: 1, maxRetries: 3), .expired],
                "expires on the second attempt"
            ),
            (
                [.continue(retryCount: 1, maxRetries: 3), .error(PollingError.invalidResponse)],
                [.error(PollingError.invalidResponse)],
                "fails on the first attempt"
            ),
            ([.timedOut], [.timedOut], "allows no retries"),
            ([.error(PollingError.missingConfiguration)], [.error(PollingError.missingConfiguration)], "has no configuration"),
        ]
        for (ios, android, name) in cases {
            XCTAssertEqual(normalized(ios, challengeMode: true), events(android), name)
        }
    }

    func testSimpleModeIsOneTerminalStatusPerCycle() {
        XCTAssertEqual(
            normalized([.continue(retryCount: 1, maxRetries: 3), .complete(status: "continue")], challengeMode: false),
            events([.complete(status: "continue")])
        )
        XCTAssertEqual(
            normalized([.continue(retryCount: 3, maxRetries: 3), .timedOut], challengeMode: false),
            events([.timedOut])
        )
    }

    func testMapsEveryStatus() {
        XCTAssertEqual(
            DaVinciPollingMapper.event("p", .continue(retryCount: 2, maxRetries: 3)),
            PollingEventMessage(pollId: "p", kind: .continuing, retryCount: 2, maxRetries: 3)
        )
        XCTAssertEqual(DaVinciPollingMapper.event("p", .timedOut), PollingEventMessage(pollId: "p", kind: .timedOut))
        XCTAssertEqual(DaVinciPollingMapper.event("p", .expired), PollingEventMessage(pollId: "p", kind: .expired))
        XCTAssertEqual(
            DaVinciPollingMapper.event("p", .error(PollingError.invalidResponse)),
            PollingEventMessage(pollId: "p", kind: .error, errorMessage: "The polling response body could not be parsed.")
        )
        XCTAssertEqual(
            DaVinciPollingMapper.event("p", .complete(status: "approved")),
            PollingEventMessage(pollId: "p", kind: .complete, status: "approved")
        )
    }

    // MARK: - Runner

    private let received = Received()

    private func polling() -> DaVinciPolling {
        let received = self.received
        return DaVinciPolling(emit: { received.append($0) }, dispatch: { $0() })
    }

    private func simple(interval: Int, retries: Int) -> PollingCollector {
        PollingCollector(with: [
            "type": "POLLING", "key": "polling-field", "pollInterval": "\(interval)", "pollRetries": "\(retries)",
        ])
    }

    private func awaitIdle(_ polling: DaVinciPolling) async throws {
        let deadline = Date().addingTimeInterval(5)
        while polling.activeCount > 0 {
            guard Date() < deadline else { return XCTFail("poll still running") }
            try await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    func testASimplePollingCycleIsOneTerminalEventAndSetsTheCollectorsValue() async throws {
        let polling = polling()
        let collector = simple(interval: 10, retries: 3)

        try polling.start(daVinciId: "handle", pollId: "poll-1", collector: collector)
        try await awaitIdle(polling)

        XCTAssertEqual(received.events, [PollingEventMessage(pollId: "poll-1", kind: .complete, status: "continue")])
        XCTAssertEqual(collector.value, "continue")
        XCTAssertEqual(collector.retriesAllowed, 2)
    }

    func testTheLastSimplePollingRetryTimesOut() async throws {
        let polling = polling()
        let collector = simple(interval: 10, retries: 1)

        try polling.start(daVinciId: "handle", pollId: "poll-1", collector: collector)
        try await awaitIdle(polling)

        XCTAssertEqual(received.events.map(\.kind), [.timedOut])
        XCTAssertEqual(collector.value, "timedOut")
    }

    func testACancelledPollReportsNothingMoreAndIsReleased() async throws {
        let polling = polling()

        try polling.start(daVinciId: "handle", pollId: "poll-1", collector: simple(interval: 60_000, retries: 3))
        XCTAssertEqual(polling.activeCount, 1)
        await polling.cancel("poll-1")

        XCTAssertEqual(polling.activeCount, 0)
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(received.events, [])
        await polling.cancel("poll-1") // Unknown ids are ignored.
    }

    func testCancelAllStopsOnlyThatHandlesPolls() async throws {
        let polling = polling()
        try polling.start(daVinciId: "a", pollId: "poll-a", collector: simple(interval: 60_000, retries: 3))
        try polling.start(daVinciId: "b", pollId: "poll-b", collector: simple(interval: 60_000, retries: 3))

        await polling.cancelAll(daVinciId: "a")

        XCTAssertEqual(polling.activeCount, 1)
        await polling.cancelAll(daVinciId: "b")
        XCTAssertEqual(polling.activeCount, 0)
    }

    func testAPollIdCantRunTwiceAtOnce() async throws {
        let polling = polling()
        try polling.start(daVinciId: "handle", pollId: "poll-1", collector: simple(interval: 60_000, retries: 3))

        XCTAssertThrowsError(
            try polling.start(daVinciId: "handle", pollId: "poll-1", collector: simple(interval: 60_000, retries: 3))
        )
        await polling.cancelAll(daVinciId: "handle")
    }
}

private final class Received: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [PollingEventMessage] = []

    var events: [PollingEventMessage] { lock.withLock { stored } }

    func append(_ event: PollingEventMessage) {
        lock.withLock { stored.append(event) }
    }
}
