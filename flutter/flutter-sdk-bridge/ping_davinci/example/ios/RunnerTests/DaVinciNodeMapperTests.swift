/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import XCTest
import PingDavinci
import PingDavinciPlugin
import PingOrchestrate
@testable import ping_davinci

/// A realistic form: the collector order is what `{type, index}` addresses.
private func form() -> [any Collector] {
    [
        LabelCollector(with: ["type": "LABEL", "key": "intro", "content": "Welcome"]),
        TextCollector(with: ["type": "TEXT", "key": "username", "label": "Username", "required": true]),
        PasswordCollector(with: ["type": "PASSWORD", "key": "password", "label": "Password"]),
        BooleanCollector(with: ["type": "SINGLE_CHECKBOX", "inputType": "BOOLEAN", "key": "accept"]),
        MultiSelectCollector(with: [
            "type": "CHECKBOX", "inputType": "MULTI_SELECT", "key": "colors",
            "options": [["label": "Red", "value": "red"], ["label": "Blue", "value": "blue"]],
        ]),
        PhoneNumberCollector(with: ["type": "PHONE_NUMBER", "key": "phone"]),
        DeviceRegistrationCollector(with: [
            "type": "DEVICE_REGISTRATION", "key": "device",
            "options": [
                ["type": "EMAIL", "title": "Email", "iconSrc": "https://example.com/email.png"],
                ["type": "SMS", "title": "Text", "iconSrc": "https://example.com/sms.png"],
            ],
        ]),
        FlowCollector(with: ["type": "FLOW_BUTTON", "inputType": "ACTION", "key": "REGISTER", "label": "Register"]),
    ]
}

private func submit(_ type: String, _ index: Int64, _ value: Any?) -> CollectorValueMessage {
    CollectorValueMessage(type: type, index: index, value: value)
}

final class DaVinciCollectorValueApplierTests: XCTestCase {
    func testAppliesAValueOfTheRightTypeToEveryValueBearingCollector() throws {
        let collectors = form()

        try DaVinciCollectorValueApplier.apply(collectors, values: [
            submit("TEXT", 1, "alice"),
            submit("PASSWORD", 2, "s3cret"),
            submit("SINGLE_CHECKBOX", 3, NSNumber(value: true)),
            submit("CHECKBOX", 4, ["red", "blue"]),
            submit("PHONE_NUMBER", 5, ["countryCode": "+1", "phoneNumber": "5551234"]),
            submit("DEVICE_REGISTRATION", 6, ["type": "SMS"]),
            submit("FLOW_BUTTON", 7, "REGISTER"),
        ])

        XCTAssertEqual((collectors[1] as? TextCollector)?.value, "alice")
        XCTAssertEqual((collectors[2] as? PasswordCollector)?.value, "s3cret")
        XCTAssertEqual((collectors[3] as? BooleanCollector)?.value, true)
        XCTAssertEqual((collectors[4] as? MultiSelectCollector)?.value, ["red", "blue"])
        XCTAssertEqual((collectors[5] as? PhoneNumberCollector)?.countryCode, "+1")
        XCTAssertEqual((collectors[5] as? PhoneNumberCollector)?.phoneNumber, "5551234")
        XCTAssertEqual((collectors[6] as? DeviceRegistrationCollector)?.value?.type, "SMS")
        XCTAssertEqual((collectors[7] as? FlowCollector)?.value, "REGISTER")
    }

    func testRejectsAWrongTypedValue() {
        let cases: [CollectorValueMessage] = [
            submit("TEXT", 1, NSNumber(value: 42)),
            // An int is not a bool, although Swift's `as? Bool` would accept it.
            submit("SINGLE_CHECKBOX", 3, NSNumber(value: 1)),
            submit("SINGLE_CHECKBOX", 3, "true"),
            submit("CHECKBOX", 4, "red"),
            submit("CHECKBOX", 4, ["red", NSNumber(value: 1)]),
            submit("PHONE_NUMBER", 5, "5551234"),
            submit("PHONE_NUMBER", 5, ["extension": "12"]),
            submit("DEVICE_REGISTRATION", 6, ["type": "VOICE"]),
            submit("TEXT", 1, nil),
        ]
        for message in cases {
            XCTAssertThrowsError(try DaVinciCollectorValueApplier.apply(form(), values: [message]), "\(message)") { error in
                guard case DaVinciHostApiError.argument = error else {
                    return XCTFail("expected an argument error for \(message), got \(error)")
                }
            }
        }
    }

    func testRejectsAMisAddressedMessage() {
        XCTAssertThrowsError(try DaVinciCollectorValueApplier.apply(form(), values: [submit("PASSWORD", 1, "x")])) { error in
            XCTAssertEqual(String(describing: error), "Collector at index=1 is TEXT, not PASSWORD")
        }
        XCTAssertThrowsError(try DaVinciCollectorValueApplier.apply(form(), values: [submit("TEXT", 99, "x")]))
        XCTAssertThrowsError(try DaVinciCollectorValueApplier.apply(form(), values: [submit("LABEL", 0, "x")]))
    }

    func testABadValueAnywhereLeavesEveryCollectorUntouched() {
        let collectors = form()

        XCTAssertThrowsError(try DaVinciCollectorValueApplier.apply(collectors, values: [
            submit("TEXT", 1, "alice"),
            submit("SINGLE_CHECKBOX", 3, "yes"),
        ]))

        XCTAssertEqual((collectors[1] as? TextCollector)?.value, "")
    }
}

final class DaVinciMapperTests: XCTestCase {
    private let context = FlowContext(flowContext: SharedContext())

    func testMapsCollectorSharedFieldsPositionsAndValues() {
        let collectors = form()
        (collectors[1] as? TextCollector)?.value = "alice"
        (collectors[2] as? PasswordCollector)?.value = "s3cret"

        let messages = DaVinciCollectorMapper.map(collectors)

        XCTAssertEqual(messages.map(\.index), Array(0..<8))
        // Server types, not the inputType the factory resolved by.
        XCTAssertEqual(messages.map(\.type), [
            "LABEL", "TEXT", "PASSWORD", "SINGLE_CHECKBOX", "CHECKBOX", "PHONE_NUMBER", "DEVICE_REGISTRATION", "FLOW_BUTTON",
        ])
        XCTAssertEqual(messages[0].key, "intro")
        XCTAssertEqual(messages[0].id, "intro")
        XCTAssertEqual(messages[1].id, "username")
        XCTAssertEqual(messages[1].label, "Username")
        XCTAssertEqual(messages[1].required, true)
        XCTAssertEqual(messages[1].value as? String, "alice")
        XCTAssertNil(messages[2].value, "passwords never cross the bridge")
        XCTAssertEqual(messages[3].value as? Bool, false)
        XCTAssertEqual(messages[4].value as? [String], [])
    }

    func testMapsAContinueNodeWithItsCollectors() {
        let node = ContinueNode(context: context, workflow: DaVinci.createDaVinci(), input: [:], actions: form())

        let message = DaVinciNodeMapper.map(node)

        XCTAssertEqual(message.type, .continueNode)
        XCTAssertEqual(message.collectors?.count, 8)
        // Not a DaVinci Connector, so the page extensions fall back to "".
        XCTAssertEqual(message.name, "")
    }

    func testMapsSuccessErrorAndFailureNodes() {
        XCTAssertEqual(DaVinciNodeMapper.map(SuccessNode(session: EmptySession())).type, .successNode)

        let error = DaVinciNodeMapper.map(
            ErrorNode(status: 400, input: ["code": "invalidValue"], message: "Invalid value", context: context)
        )
        XCTAssertEqual(error.type, .errorNode)
        XCTAssertEqual(error.message, "Invalid value")
        XCTAssertEqual(error.status, 400)
        XCTAssertEqual(error.input?["code"] as? String, "invalidValue")
        // No `details`, and no ContinueNode in the flow context: nothing to retry from.
        XCTAssertNil(error.errorDetails)
        XCTAssertNil(error.collectors)

        let failure = DaVinciNodeMapper.map(FailureNode(cause: DaVinciHostApiError.stateError("Rewind failed.")))
        XCTAssertEqual(failure.type, .failureNode)
        XCTAssertEqual(failure.cause, "Rewind failed.")

        XCTAssertEqual(DaVinciNodeMapper.map(EmptyNode()).type, .failureNode)
    }

    /// The ErrorNode of a captured response, its context holding `retry` as the SDK's flow
    /// context would.
    private func errorNode(_ name: String, retry: ContinueNode? = nil) throws -> ErrorNode {
        let flowContext = FlowContext(flowContext: SharedContext())
        if let retry { flowContext.flowContext.set(key: SharedContext.Keys.continueNode, value: retry) }
        let input = try fixture(name)
        return ErrorNode(status: 400, input: input, message: input["message"] as? String ?? "", context: flowContext)
    }

    func testDecodesARegistrationsPasswordPolicyDetailsInnerErrorIncluded() throws {
        let details = DaVinciNodeMapper.errorDetails(try errorNode("ssoRegisterWeakPassword").details)

        let detail = try XCTUnwrap(details.first as? [String?: Any?])
        XCTAssertEqual(details.count, 1)
        XCTAssertEqual(detail["statusCode"] as? Int64, 400)
        let raw = try XCTUnwrap(detail["rawResponse"] as? [String?: Any?])
        XCTAssertEqual(raw["code"] as? String, "INVALID_DATA")
        let errors = try XCTUnwrap(raw["details"] as? [Any?])
        let error = try XCTUnwrap(errors.first as? [String?: Any?])
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(error["code"] as? String, "INVALID_VALUE")
        XCTAssertEqual(error["target"] as? String, "password")
        XCTAssertEqual(error["message"] as? String, "User password did not satisfy password policy requirements")
        // `unsatisfiedRequirements` names minCharacters three times; the map holds it once.
        let inner = try XCTUnwrap(error["innerError"] as? [String: String])
        XCTAssertEqual(Set(inner.keys), ["minCharacters", "length", "minUniqueCharacters", "excludesCommonlyUsed"])
        XCTAssertEqual(inner["length"], "The provided password is shorter than the minimum required length of 8 characters")
    }

    func testDecodesASignOnsDetailsWhichNameNoField() throws {
        let details = DaVinciNodeMapper.errorDetails(try errorNode("ssoWrongPassword").details)

        let detail = try XCTUnwrap(details.first as? [String?: Any?])
        XCTAssertEqual(details.count, 1)
        // A user lookup's raw response is a user search result, not a PingOne error.
        XCTAssertEqual(detail["statusCode"] as? Int64, 200)
        let raw = try XCTUnwrap(detail["rawResponse"] as? [String?: Any?])
        for key in ["id", "code", "message", "details"] {
            XCTAssertNil(raw[key] ?? nil, key)
        }
    }

    func testDropsAMalformedDetailAndKeepsTheRest() {
        let node = ErrorNode(
            status: 409,
            input: ["details": [
                ["rawResponse": ["code": "NO_STATUS"]],
                ["rawResponse": ["code": "KEPT", "details": [["target": "email", "message": "Taken"]]], "statusCode": 409],
            ]],
            message: "Conflict",
            context: context
        )

        let details = DaVinciNodeMapper.errorDetails(node.details)

        XCTAssertEqual(details.count, 1)
        let kept = details.first as? [String?: Any?]
        XCTAssertEqual(kept?["statusCode"] as? Int64, 409)
        let error = ((kept?["rawResponse"] as? [String?: Any?])?["details"] as? [Any?])?.first as? [String?: Any?]
        XCTAssertEqual(error?["target"] as? String, "email")
        XCTAssertNil(error?["innerError"] ?? nil)
    }

    func testAnErrorNodeCarriesItsRetryNodesCollectors() async throws {
        let retry = try await continueNode("ssoRegisterForm")

        let message = DaVinciNodeMapper.map(
            try errorNode("ssoRegisterWeakPassword", retry: retry),
            unsupportedFields: [["key": nil, "type": "ERROR_DISPLAY"] as [String?: Any?]]
        )

        XCTAssertEqual(message.type, .errorNode)
        XCTAssertEqual(message.message, "password: User password did not satisfy password policy requirements")
        XCTAssertEqual(message.errorDetails?.count, 1)
        XCTAssertEqual(message.collectors?.map { $0?.key }, ["email", "password", "givenName", "familyName", "REGISTER", "CANCEL"])
        XCTAssertEqual(message.unsupportedFields?.count, 1)
    }
}
