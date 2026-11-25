/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import XCTest
import PingJourney
import PingJourneyPlugin
import PingOrchestrate
import ping_core
@testable import ping_journey

/// Unit tests for `ActiveNodeState`: callback lookup by `{type, index}`, node replacement and
/// clearing, that `withItem`, `withLock`, `clear` and `startWith` all exclude each other, and that
/// entering the lock again from inside it throws instead of deadlocking.
final class ActiveNodeStateTests: XCTestCase {

    func testWithItemReturnsTheCallbackAtTheRequestedTypeAndIndex() async throws {
        let firstName = await makeCallback(NameCallback(), type: "NameCallback")
        let password = await makeCallback(PasswordCallback(), type: "PasswordCallback")
        let secondName = await makeCallback(NameCallback(), type: "NameCallback")
        let state = ActiveNodeState()
        state.set(makeContinueNode(actions: [firstName, password, secondName]))

        let first = try await state.withItem(type: "NameCallback", index: 0) { $0 as AnyObject }
        let second = try await state.withItem(type: "NameCallback", index: 1) { $0 as AnyObject }
        let pw = try await state.withItem(type: "PasswordCallback", index: 0) { $0 as AnyObject }

        XCTAssertTrue(first === firstName)
        XCTAssertTrue(second === secondName)
        XCTAssertTrue(pw === password)
    }

    func testWithItemReturnsTheBlocksResult() async throws {
        let state = ActiveNodeState()
        state.set(makeContinueNode(actions: [await makeCallback(NameCallback(), type: "NameCallback")]))

        let result = try await state.withItem(type: "NameCallback", index: 0) { _ in "done" }

        XCTAssertEqual(result, "done")
    }

    func testWithItemThrowsNoActiveNodeWhenThereIsNoNode() async {
        let state = ActiveNodeState()

        do {
            _ = try await state.withItem(type: "NameCallback", index: 0) { _ in 0 }
            XCTFail("expected ActiveNodeError.noActiveNode")
        } catch ActiveNodeError.noActiveNode {
            // expected
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testWithItemThrowsItemNotFoundForAnUnknownTypeOrOutOfRangeIndex() async throws {
        let state = ActiveNodeState()
        state.set(makeContinueNode(actions: [await makeCallback(NameCallback(), type: "NameCallback")]))

        for (type, index) in [("PasswordCallback", 0), ("NameCallback", 1), ("NameCallback", -1)] {
            do {
                _ = try await state.withItem(type: type, index: index) { _ in 0 }
                XCTFail("expected ActiveNodeError.itemNotFound for \(type) at \(index)")
            } catch ActiveNodeError.itemNotFound(let errorType, let errorIndex) {
                XCTAssertEqual(errorType, type)
                XCTAssertEqual(errorIndex, index)
            } catch {
                XCTFail("unexpected error: \(error)")
            }
        }
    }

    func testSetReplacesTheNodeSoLookupsSeeTheNewOne() async throws {
        let oldCallback = await makeCallback(NameCallback(), type: "NameCallback")
        let newCallback = await makeCallback(NameCallback(), type: "NameCallback")
        let state = ActiveNodeState()

        state.set(makeContinueNode(actions: [oldCallback]))
        state.set(makeContinueNode(actions: [newCallback]))

        let found = try await state.withItem(type: "NameCallback", index: 0) { $0 as AnyObject }
        XCTAssertTrue(found === newCallback)
    }

    func testSetWithATerminalNodeLeavesNothingCached() async {
        let state = ActiveNodeState()
        state.set(makeContinueNode(actions: [await makeCallback(NameCallback(), type: "NameCallback")]))

        state.set(SuccessNode(session: EmptySession()))

        XCTAssertNil(state.current)
    }

    func testClearDropsTheNode() async throws {
        let state = ActiveNodeState()
        state.set(makeContinueNode(actions: [await makeCallback(NameCallback(), type: "NameCallback")]))

        try await state.clear()

        XCTAssertNil(state.current)
        do {
            _ = try await state.withItem(type: "NameCallback", index: 0) { _ in 0 }
            XCTFail("expected ActiveNodeError.noActiveNode")
        } catch ActiveNodeError.noActiveNode {
            // expected
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testClearWaitsForAnInFlightWithItemBeforeDroppingTheNode() async throws {
        let state = ActiveNodeState()
        state.set(makeContinueNode(actions: [await makeCallback(NameCallback(), type: "NameCallback")]))
        let recorder = Recorder()
        let entered = Gate()
        let release = Gate()

        let holder = Task {
            try await state.withItem(type: "NameCallback", index: 0) { _ in
                await recorder.add("item-start")
                await entered.open()
                await release.wait()
                await recorder.add("item-end")
            }
        }
        await entered.wait()
        let waiter = Task {
            try await state.clear()
            await recorder.add("cleared")
        }

        try await Task.sleep(nanoseconds: 50_000_000)
        let whileHeld = await recorder.events
        XCTAssertEqual(whileHeld, ["item-start"])
        XCTAssertNotNil(state.current)

        await release.open()
        try await holder.value
        try await waiter.value
        let afterwards = await recorder.events
        XCTAssertEqual(afterwards, ["item-start", "item-end", "cleared"])
        XCTAssertNil(state.current)
    }

    func testStartWithCachesTheNodeItReturns() async throws {
        let state = ActiveNodeState()
        let started = makeContinueNode(actions: [await makeCallback(NameCallback(), type: "NameCallback")])

        let result = try await state.startWith { started }

        XCTAssertTrue((result as AnyObject) === started)
        XCTAssertTrue(state.current === started)
    }

    func testStartWithWaitsForAnInFlightWithItemBeforeReplacingTheNode() async throws {
        let oldCallback = await makeCallback(NameCallback(), type: "NameCallback")
        let newNode = makeContinueNode(actions: [await makeCallback(NameCallback(), type: "NameCallback")])
        let state = ActiveNodeState()
        state.set(makeContinueNode(actions: [oldCallback]))
        let recorder = Recorder()
        let entered = Gate()
        let release = Gate()

        let holder = Task {
            try await state.withItem(type: "NameCallback", index: 0) { item in
                await recorder.add("item-start")
                await entered.open()
                await release.wait()
                // Still the old callback: the restart hasn't replaced the node under us.
                XCTAssertTrue((item as AnyObject) === oldCallback)
                await recorder.add("item-end")
            }
        }
        await entered.wait()
        let waiter = Task {
            try await state.startWith {
                await recorder.add("start")
                return newNode
            }
        }

        try await Task.sleep(nanoseconds: 50_000_000)
        let whileHeld = await recorder.events
        XCTAssertEqual(whileHeld, ["item-start"])

        await release.open()
        try await holder.value
        _ = try await waiter.value
        let afterwards = await recorder.events
        XCTAssertEqual(afterwards, ["item-start", "item-end", "start"])
        XCTAssertTrue(state.current === newNode)
    }

    func testWithItemExcludesAConcurrentWithLockUntilTheBlockFinishes() async throws {
        let state = ActiveNodeState()
        state.set(makeContinueNode(actions: [await makeCallback(NameCallback(), type: "NameCallback")]))
        let recorder = Recorder()
        let entered = Gate()
        let release = Gate()

        let holder = Task {
            try await state.withItem(type: "NameCallback", index: 0) { _ in
                await recorder.add("item-start")
                await entered.open()
                await release.wait()
                await recorder.add("item-end")
            }
        }
        await entered.wait()
        let waiter = Task {
            try await state.withLock { await recorder.add("lock") }
        }

        try await Task.sleep(nanoseconds: 50_000_000)
        let whileHeld = await recorder.events
        XCTAssertEqual(whileHeld, ["item-start"])

        await release.open()
        try await holder.value
        try await waiter.value
        let afterwards = await recorder.events
        XCTAssertEqual(afterwards, ["item-start", "item-end", "lock"])
    }

    // --- Reentrancy --------------------------------------------------------------------------

    func testWithItemInsideWithItemThrowsInsteadOfDeadlocking() async throws {
        try await assertReentryRejected { state in
            _ = try await state.withItem(type: "NameCallback", index: 0) { _ in 0 }
        }
    }

    func testWithLockInsideWithItemThrowsInsteadOfDeadlocking() async throws {
        try await assertReentryRejected { state in
            try await state.withLock { 0 }
        }
    }

    func testClearInsideWithItemThrowsInsteadOfDeadlocking() async throws {
        try await assertReentryRejected { state in
            try await state.clear()
        }
    }

    func testStartWithInsideWithItemThrowsInsteadOfDeadlocking() async throws {
        let spare = makeContinueNode(actions: [])
        try await assertReentryRejected { state in
            _ = try await state.startWith { spare }
        }
    }

    func testWithItemInsideWithLockThrowsInsteadOfDeadlocking() async throws {
        let state = ActiveNodeState()
        state.set(makeContinueNode(actions: [await makeCallback(NameCallback(), type: "NameCallback")]))

        do {
            _ = try await state.withLock {
                try await state.withItem(type: "NameCallback", index: 0) { _ in 0 }
            }
            XCTFail("expected ActiveNodeError.reentrantLock")
        } catch ActiveNodeError.reentrantLock {
            // expected
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testHoldingOneStatesLockDoesNotBlockUsingAnothers() async throws {
        let first = ActiveNodeState()
        first.set(makeContinueNode(actions: [await makeCallback(NameCallback(), type: "NameCallback")]))
        let second = ActiveNodeState()
        second.set(makeContinueNode(actions: [await makeCallback(PasswordCallback(), type: "PasswordCallback")]))

        let result = try await first.withItem(type: "NameCallback", index: 0) { _ in
            try await second.withItem(type: "PasswordCallback", index: 0) { _ in "both" }
        }

        XCTAssertEqual(result, "both")
    }

    func testReEnteringTheFirstStateIsStillCaughtWhileHoldingTwo() async throws {
        let first = ActiveNodeState()
        first.set(makeContinueNode(actions: [await makeCallback(NameCallback(), type: "NameCallback")]))
        let second = ActiveNodeState()
        second.set(makeContinueNode(actions: [await makeCallback(PasswordCallback(), type: "PasswordCallback")]))

        do {
            _ = try await first.withItem(type: "NameCallback", index: 0) { _ in
                try await second.withItem(type: "PasswordCallback", index: 0) { _ in
                    try await first.withItem(type: "NameCallback", index: 0) { _ in 0 }
                }
            }
            XCTFail("expected ActiveNodeError.reentrantLock")
        } catch ActiveNodeError.reentrantLock {
            // expected
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    /// Runs `reenter` from inside a `withItem` body on a fresh state and asserts it is rejected
    /// with `reentrantLock`, then that the lock still works afterwards.
    private func assertReentryRejected(
        _ reenter: @escaping @Sendable (ActiveNodeState) async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let state = ActiveNodeState()
        state.set(makeContinueNode(actions: [await makeCallback(NameCallback(), type: "NameCallback")]))

        do {
            try await state.withItem(type: "NameCallback", index: 0) { _ in try await reenter(state) }
            XCTFail("expected ActiveNodeError.reentrantLock", file: file, line: line)
        } catch ActiveNodeError.reentrantLock {
            // expected
        } catch {
            XCTFail("unexpected error: \(error)", file: file, line: line)
        }

        // The rejected call must not have wedged the lock.
        let ok = try await state.withItem(type: "NameCallback", index: 0) { _ in "ok" }
        XCTAssertEqual(ok, "ok", file: file, line: line)
    }

    // --- Helpers -----------------------------------------------------------------------------

    private func makeContinueNode(actions: [any Action]) -> ContinueNode {
        let workflow = Workflow.createWorkflow()
        let context = FlowContext(flowContext: SharedContext())
        return ContinueNode(context: context, workflow: workflow, input: [:], actions: actions)
    }

    private func makeCallback<T: AbstractCallback>(_ callback: T, type: String) async -> T {
        _ = await callback.initialize(with: ["type": type])
        return callback
    }
}

private actor Recorder {
    private(set) var events: [String] = []

    func add(_ event: String) {
        events.append(event)
    }
}

private actor Gate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }
}
