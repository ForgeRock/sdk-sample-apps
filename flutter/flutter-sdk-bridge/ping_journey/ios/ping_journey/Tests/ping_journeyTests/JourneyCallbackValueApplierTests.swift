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
@testable import ping_journey

/// Unit tests for `JourneyCallbackValueApplier.apply`: verifies each callback type's submitted
/// value lands on the correct native field, and that lookup/type-mismatch failures are surfaced.
final class JourneyCallbackValueApplierTests: XCTestCase {

    func testAppliesStringValueOntoNameCallbackName() async throws {
        let callback = NameCallback()
        try await apply(callback, type: "NameCallback", value: "John Doe")

        XCTAssertEqual(callback.name, "John Doe")
    }

    func testAppliesStringValueOntoPasswordCallbackPassword() async throws {
        let callback = PasswordCallback()
        try await apply(callback, type: "PasswordCallback", value: "s3cr3t")

        XCTAssertEqual(callback.password, "s3cr3t")
    }

    func testAppliesStringValueOntoValidatedUsernameCallbackUsername() async throws {
        let callback = ValidatedUsernameCallback()
        try await apply(callback, type: "ValidatedUsernameCallback", value: "jdoe")

        XCTAssertEqual(callback.username, "jdoe")
    }

    func testAppliesStringValueOntoValidatedPasswordCallbackPassword() async throws {
        let callback = ValidatedPasswordCallback()
        try await apply(callback, type: "ValidatedPasswordCallback", value: "s3cr3t")

        XCTAssertEqual(callback.password, "s3cr3t")
    }

    func testAppliesStringValueOntoTextInputCallbackText() async throws {
        let callback = TextInputCallback()
        try await apply(callback, type: "TextInputCallback", value: "some text")

        XCTAssertEqual(callback.text, "some text")
    }

    func testAppliesStringValueOntoStringAttributeInputCallbackValue() async throws {
        let callback = StringAttributeInputCallback()
        try await apply(callback, type: "StringAttributeInputCallback", value: "user@example.com")

        XCTAssertEqual(callback.value, "user@example.com")
    }

    func testAppliesNumericValueOntoNumberAttributeInputCallbackValueAsDouble() async throws {
        let callback = NumberAttributeInputCallback()
        try await apply(callback, type: "NumberAttributeInputCallback", value: NSNumber(value: 42))

        XCTAssertEqual(callback.value, 42.0)
    }

    func testAppliesBoolValueOntoBooleanAttributeInputCallbackValue() async throws {
        let callback = BooleanAttributeInputCallback()
        try await apply(callback, type: "BooleanAttributeInputCallback", value: true)

        XCTAssertEqual(callback.value, true)
    }

    func testAppliesNumericValueOntoChoiceCallbackSelectedIndex() async throws {
        let callback = ChoiceCallback()
        try await apply(callback, type: "ChoiceCallback", value: NSNumber(value: 2))

        XCTAssertEqual(callback.selectedIndex, 2)
    }

    func testAppliesBoolValueOntoTermsAndConditionsCallbackAccepted() async throws {
        let callback = TermsAndConditionsCallback()
        try await apply(callback, type: "TermsAndConditionsCallback", value: true)

        XCTAssertEqual(callback.accepted, true)
    }

    func testAppliesMapValueOntoKbaCreateCallbackSubFields() async throws {
        let callback = KbaCreateCallback()
        try await apply(
            callback,
            type: "KbaCreateCallback",
            value: [
                "selectedQuestion": "Pet's name?",
                "selectedAnswer": "Rex",
                "allowUserDefinedQuestions": true,
            ]
        )

        XCTAssertEqual(callback.selectedQuestion, "Pet's name?")
        XCTAssertEqual(callback.selectedAnswer, "Rex")
        XCTAssertEqual(callback.allowUserDefinedQuestions, true)
    }

    func testKbaCreateCallbackThrowsCallbackApplyWhenASubFieldIsMissing() async throws {
        let callback = KbaCreateCallback()

        do {
            try await apply(callback, type: "KbaCreateCallback", value: ["selectedAnswer": "new answer"])
            XCTFail("Expected .callbackApply to be thrown")
        } catch JourneyHostApiError.callbackApply {
            // expected
        } catch {
            XCTFail("Expected .callbackApply, got \(error)")
        }
    }

    func testThrowsForUnsupportedCallbackTypeSuchAsTextOutputCallback() async throws {
        let callback = TextOutputCallback()
        _ = await callback.initialize(with: ["type": "TextOutputCallback"])
        let node = makeContinueNode(actions: [callback])

        XCTAssertThrowsError(
            try JourneyCallbackValueApplier.apply(
                node,
                values: [CallbackValueMessage(type: "TextOutputCallback", index: 0, value: "ignored")]
            )
        ) { error in
            guard case JourneyHostApiError.unsupported = error else {
                return XCTFail("Expected .unsupported, got \(error)")
            }
        }
    }

    func testThrowsCallbackApplyWhenNoCallbackMatchesTypeAndIndex() async throws {
        let callback = NameCallback()
        _ = await callback.initialize(with: ["type": "NameCallback"])
        let node = makeContinueNode(actions: [callback])

        XCTAssertThrowsError(
            try JourneyCallbackValueApplier.apply(
                node,
                values: [CallbackValueMessage(type: "PasswordCallback", index: 0, value: "x")]
            )
        ) { error in
            guard case let JourneyHostApiError.callbackApply(message) = error else {
                return XCTFail("Expected .callbackApply, got \(error)")
            }
            XCTAssertEqual(message, "No active callback found for type PasswordCallback at index 0")
        }
    }

    func testThrowsCallbackApplyWhenValueTypeMismatchesExpectedType() async throws {
        let callback = NameCallback()
        _ = await callback.initialize(with: ["type": "NameCallback"])
        let node = makeContinueNode(actions: [callback])

        XCTAssertThrowsError(
            try JourneyCallbackValueApplier.apply(
                node,
                values: [CallbackValueMessage(type: "NameCallback", index: 0, value: NSNumber(value: 123))]
            )
        ) { error in
            guard case JourneyHostApiError.callbackApply = error else {
                return XCTFail("Expected .callbackApply, got \(error)")
            }
        }
    }

    func testAppliesValuesAddressedByIndexWithinSameTypeGroup() async throws {
        let first = NameCallback()
        _ = await first.initialize(with: ["type": "NameCallback"])
        let second = NameCallback()
        _ = await second.initialize(with: ["type": "NameCallback"])
        let node = makeContinueNode(actions: [first, second])

        try JourneyCallbackValueApplier.apply(
            node,
            values: [CallbackValueMessage(type: "NameCallback", index: 1, value: "second value")]
        )

        XCTAssertEqual(first.name, "")
        XCTAssertEqual(second.name, "second value")
    }

    // --- Helpers -----------------------------------------------------------------------------

    private func makeContinueNode(actions: [any Action]) -> ContinueNode {
        let workflow = Workflow.createWorkflow()
        let context = FlowContext(flowContext: SharedContext())
        return ContinueNode(context: context, workflow: workflow, input: [:], actions: actions)
    }

    private func apply(_ callback: any Callback, type: String, value: Any?) async throws {
        if let abstractCallback = callback as? AbstractCallback {
            _ = await abstractCallback.initialize(with: ["type": type])
        }
        let node = makeContinueNode(actions: [callback])
        try JourneyCallbackValueApplier.apply(
            node,
            values: [CallbackValueMessage(type: type, index: 0, value: value)]
        )
    }
}
