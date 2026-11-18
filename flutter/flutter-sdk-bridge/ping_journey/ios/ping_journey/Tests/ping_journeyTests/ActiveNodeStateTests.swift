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
/// clearing, and that `withItem` and `withLock` exclude each other.
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

    func testClearDropsTheNode() async {
        let state = ActiveNodeState()
        state.set(makeContinueNode(actions: [await makeCallback(NameCallback(), type: "NameCallback")]))

        state.clear()

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
