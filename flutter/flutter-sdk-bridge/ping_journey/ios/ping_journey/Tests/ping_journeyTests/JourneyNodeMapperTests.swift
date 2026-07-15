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

/// Unit tests for `JourneyNodeMapper`: one test per `Node` subtype, plus per-callback-type field
/// mapping for a representative set of the v1 callback set.
final class JourneyNodeMapperTests: XCTestCase {

    // --- Node subtype mapping ---------------------------------------------------------------

    func testMapSuccessNodeReturnsSuccessNodeType() {
        let node = SuccessNode(session: EmptySession())

        let result = JourneyNodeMapper.map(node)

        XCTAssertEqual(result.type, .successNode)
    }

    func testMapErrorNodeReturnsErrorNodeTypeWithMessage() {
        let flowContext = FlowContext(flowContext: SharedContext())
        let node = ErrorNode(status: 400, message: "Something went wrong", context: flowContext)

        let result = JourneyNodeMapper.map(node)

        XCTAssertEqual(result.type, .errorNode)
        XCTAssertEqual(result.message, "Something went wrong")
        XCTAssertEqual(result.status, 400)
    }

    func testMapFailureNodeReturnsFailureNodeTypeWithCauseDescription() {
        struct SampleError: Error, CustomStringConvertible {
            var description: String { "bad state" }
        }
        let node = FailureNode(cause: SampleError())

        let result = JourneyNodeMapper.map(node)

        XCTAssertEqual(result.type, .failureNode)
        XCTAssertEqual(result.cause, "bad state")
    }

    func testMapUnknownNodeTypeFallsBackToFailureNodeWithDescriptiveCause() {
        // `Node` is a plain (non-sealed) protocol on iOS, unlike Android's sealed interface, so a
        // custom conforming type can reach the mapper's otherwise-unreachable `default` branch.
        struct CustomNode: Node {}
        let node = CustomNode()

        let result = JourneyNodeMapper.map(node)

        XCTAssertEqual(result.type, .failureNode)
        XCTAssertTrue(result.cause?.contains("Unknown node type") == true)
    }

    func testMapContinueNodeExposesHeaderDescriptionStageAndCallbacks() {
        let nameCallback = NameCallback()
        let node = makeContinueNode(
            input: [
                "header": "Welcome",
                "description": "Please sign in",
                "stage": "Login",
            ],
            actions: [nameCallback]
        )

        let result = JourneyNodeMapper.map(node)

        XCTAssertEqual(result.type, .continueNode)
        XCTAssertEqual(result.header, "Welcome")
        XCTAssertEqual(result.pageDescription, "Please sign in")
        XCTAssertEqual(result.stage, "Login")
        XCTAssertEqual(result.callbacks?.count, 1)
    }

    func testMapContinueNodeWithNoPageMetadataDefaultsToEmptyStrings() {
        let node = makeContinueNode(input: [:], actions: [])

        let result = JourneyNodeMapper.map(node)

        XCTAssertEqual(result.header, "")
        XCTAssertEqual(result.pageDescription, "")
        XCTAssertEqual(result.stage, "")
        XCTAssertEqual(result.callbacks?.count, 0)
    }

    // --- Callback field mapping (mapCallback, exercised via map(ContinueNode)) --------------

    func testMapCallbackMapsNameCallbackPromptAndValue() async {
        let callback = NameCallback()
        _ = await callback.initialize(with: outputOnly([("prompt", "Enter your name")]))
        callback.name = "John Doe"

        let message = await mapSingleCallback(callback)

        XCTAssertEqual(message.type, "NameCallback")
        XCTAssertEqual(message.index, 0)
        XCTAssertEqual(message.prompt, "Enter your name")
        XCTAssertEqual(message.value as? String, "John Doe")
    }

    func testMapCallbackMapsPasswordCallbackPromptButNeverLeaksPasswordValue() async {
        let callback = PasswordCallback()
        _ = await callback.initialize(with: outputOnly([("prompt", "Enter your password")]))
        callback.password = "super-secret"

        let message = await mapSingleCallback(callback)

        XCTAssertEqual(message.type, "PasswordCallback")
        XCTAssertEqual(message.prompt, "Enter your password")
        XCTAssertEqual(message.value as? String, "")
    }

    func testMapCallbackMapsValidatedUsernameCallbackUsernameAsValue() async {
        let callback = ValidatedUsernameCallback()
        callback.username = "jdoe"

        let message = await mapSingleCallback(callback)

        XCTAssertEqual(message.type, "ValidatedUsernameCallback")
        XCTAssertEqual(message.value as? String, "jdoe")
    }

    func testMapCallbackMapsTextOutputCallbackMessageAndMessageType() async {
        let callback = TextOutputCallback()
        _ = await callback.initialize(
            with: [
                "output": [
                    ["name": "messageType", "value": "0"],
                    ["name": "message", "value": "Hello!"],
                ]
            ]
        )

        let message = await mapSingleCallback(callback)

        XCTAssertEqual(message.type, "TextOutputCallback")
        XCTAssertEqual(message.message, "Hello!")
        XCTAssertEqual(message.messageType, "information")
    }

    func testMapCallbackMapsChoiceCallbackPromptChoicesDefaultChoiceAndSelectedIndex() async {
        let callback = ChoiceCallback()
        _ = await callback.initialize(
            with: [
                "output": [
                    ["name": "prompt", "value": "Pick one"],
                    ["name": "defaultChoice", "value": 1],
                    ["name": "choices", "value": ["A", "B"]],
                ]
            ]
        )
        callback.selectedIndex = 1

        let message = await mapSingleCallback(callback)

        XCTAssertEqual(message.type, "ChoiceCallback")
        XCTAssertEqual(message.prompt, "Pick one")
        XCTAssertEqual(message.choices as? [String], ["A", "B"])
        XCTAssertEqual(message.defaultChoice, 1)
        XCTAssertEqual(message.selectedIndex, 1)
    }

    func testMapCallbackMapsKbaCreateCallbackQuestionAndAnswerFields() async {
        let callback = KbaCreateCallback()
        _ = await callback.initialize(
            with: [
                "output": [
                    ["name": "prompt", "value": "Security question"],
                    ["name": "predefinedQuestions", "value": ["Pet's name?", "First school?"]],
                    ["name": "allowUserDefinedQuestions", "value": true],
                ]
            ]
        )
        callback.selectedQuestion = "Pet's name?"
        callback.selectedAnswer = "Rex"

        let message = await mapSingleCallback(callback)

        XCTAssertEqual(message.type, "KbaCreateCallback")
        XCTAssertEqual(message.prompt, "Security question")
        XCTAssertEqual(message.predefinedQuestions as? [String], ["Pet's name?", "First school?"])
        XCTAssertEqual(message.selectedQuestion, "Pet's name?")
        XCTAssertEqual(message.selectedAnswer, "Rex")
        XCTAssertEqual(message.allowUserDefinedQuestions, true)
    }

    func testMapCallbackMapsStringAttributeInputCallbackNameRequiredAndValue() async {
        let callback = StringAttributeInputCallback()
        _ = await callback.initialize(
            with: [
                "output": [
                    ["name": "name", "value": "mail"],
                    ["name": "prompt", "value": "Email address"],
                    ["name": "required", "value": true],
                ]
            ]
        )
        callback.value = "user@example.com"

        let message = await mapSingleCallback(callback)

        XCTAssertEqual(message.type, "StringAttributeInputCallback")
        XCTAssertEqual(message.name, "mail")
        XCTAssertEqual(message.prompt, "Email address")
        XCTAssertEqual(message.required, true)
        XCTAssertEqual(message.value as? String, "user@example.com")
    }

    func testMapCallbacksAssignsPerTypeIndicesIndependently() {
        let name1 = NameCallback()
        let name2 = NameCallback()
        let password = PasswordCallback()
        let node = makeContinueNode(input: [:], actions: [name1, password, name2])

        let result = JourneyNodeMapper.map(node)
        let callbacks = result.callbacks!

        XCTAssertEqual(callbacks.count, 3)
        XCTAssertEqual(callbacks[0]!.type, "NameCallback")
        XCTAssertEqual(callbacks[0]!.index, 0)
        XCTAssertEqual(callbacks[1]!.type, "PasswordCallback")
        XCTAssertEqual(callbacks[1]!.index, 0)
        XCTAssertEqual(callbacks[2]!.type, "NameCallback")
        XCTAssertEqual(callbacks[2]!.index, 1)
    }

    // --- Helpers -----------------------------------------------------------------------------

    private func makeContinueNode(input: [String: Any], actions: [any Action]) -> ContinueNode {
        let workflow = Workflow.createWorkflow()
        let context = FlowContext(flowContext: SharedContext())
        return ContinueNode(context: context, workflow: workflow, input: input, actions: actions)
    }

    private func mapSingleCallback(_ callback: any Callback) async -> CallbackMessage {
        let node = makeContinueNode(input: [:], actions: [callback])
        return JourneyNodeMapper.map(node).callbacks!.first!!
    }

    private func outputOnly(_ entries: [(String, String)]) -> [String: Any] {
        [
            "output": entries.map { ["name": $0.0, "value": $0.1] }
        ]
    }
}
