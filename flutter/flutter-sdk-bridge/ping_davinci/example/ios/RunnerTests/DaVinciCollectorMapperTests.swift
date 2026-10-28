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

/// A captured node from `example/integration_test/support/fixtures/<name>.json`, read from the
/// source tree (the simulator can read host paths), so iOS tests the same payloads as Android.
func fixture(_ name: String) throws -> [String: Any] {
    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("../../integration_test/support/fixtures/\(name).json")
    let data = try Data(contentsOf: url)
    return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
}

/// The node the SDK builds for a captured response, the way its internal `Form.parse` and
/// `Connector` do: the factory over `form.components.fields`, `formData.value` as initial values,
/// then `inject(continueNode:)` so `PasswordCollector` can fall back to the node's policy.
func continueNode(_ name: String) async throws -> ContinueNode {
    let input = try fixture(name)
    let daVinci = DaVinci.createDaVinci()
    await CoreCollectorRegistration.register()
    let form = input["form"] as? [String: Any]
    let fields = (form?["components"] as? [String: Any])?["fields"] as? [[String: Any]] ?? []
    let collectors = await CollectorFactory.shared.collector(daVinci: daVinci, from: fields)
    if let values = (input["formData"] as? [String: Any])?["value"] as? [String: Any] {
        for case let field as any AnyFieldCollector in collectors {
            if let value = values[field.id] { field.initialize(with: value) }
        }
    }
    let node = ContinueNode(
        context: FlowContext(flowContext: SharedContext()), workflow: daVinci, input: input, actions: collectors
    )
    await CollectorFactory.shared.inject(continueNode: node)
    return node
}

private func mapped(_ name: String) async throws -> [CollectorMessage] {
    DaVinciCollectorMapper.map(try await continueNode(name).collectors)
}

/// Every core collector class, mapped from node JSON captured from the live test tenant.
/// Mirrors Android's `DaVinciCollectorMapperTest`, assertion for assertion.
final class DaVinciCollectorMapperTests: XCTestCase {
    func testMapsTheFormFieldsFormByClassKeepingServerTypes() async throws {
        let messages = try await mapped("formFieldsForm")

        XCTAssertEqual(messages.map(\.index), Array(0..<13))
        XCTAssertEqual(messages.map { "\($0.type)/\($0.kind)" }, [
            "LABEL/label", "LABEL/label", "LABEL/label", "TEXT/text",
            "CHECKBOX/multiSelect", "DROPDOWN/singleSelect", "RADIO/singleSelect",
            "COMBOBOX/multiSelect", "PHONE_NUMBER/phoneNumber",
            "SINGLE_CHECKBOX/boolean", "FLOW_BUTTON/flow", "FLOW_LINK/flow",
            "SUBMIT_BUTTON/submit",
        ])
    }

    func testMapsLabelsWithAndWithoutRichContent() async throws {
        let messages = try await mapped("formFieldsForm")
        let (plain, translatable, linked) = (messages[0], messages[1], messages[2])

        XCTAssertEqual(plain.key, "", "the first label has no key")
        XCTAssertEqual(plain.content, "<p><strong><em>Rich Text fields produce LABELs</em></strong></p><hr><p><br></p>")
        XCTAssertNil(plain.richContent)
        XCTAssertEqual(translatable.richContent?.content, "Translatable Rich Text produce LABELs too!")
        XCTAssertEqual(translatable.richContent?.replacements?.count, 0)
        XCTAssertEqual(linked.id, "rich-text")
        XCTAssertEqual(linked.richContent?.content, "A translatable rich text to take the user to {{link1}} and {{link2}}")
        XCTAssertEqual(linked.richContent?.replacements, [
            RichContentReplacementMessage(key: "link1", value: "google.com", href: "https://www.google.com", type: "link", target: "_self"),
            RichContentReplacementMessage(key: "link2", value: "apple.com", href: "https://www.apple.com", type: "link", target: "_blank"),
        ])
        XCTAssertNil(linked.value, "display-only")
    }

    func testMapsTextSelectsAndTheirFormDataDefaults() async throws {
        let messages = try await mapped("formFieldsForm")
        let (text, checkbox, dropdown, radio, combobox) = (messages[3], messages[4], messages[5], messages[6], messages[7])

        XCTAssertEqual(text.id, "text-input-key")
        XCTAssertEqual(text.label, "Text Input Label")
        XCTAssertEqual(text.required, true)
        XCTAssertEqual(text.value as? String, "default text")
        XCTAssertNil(text.validationRegex)

        XCTAssertEqual(checkbox.value as? [String], ["option1 value", "option2 value"])
        XCTAssertEqual(checkbox.options, [
            OptionMessage(label: "option1 label", value: "option1 value"),
            OptionMessage(label: "option2 label", value: "option2 value"),
        ])
        XCTAssertEqual(combobox.value as? [String], ["option1 value", "option3 value"])
        XCTAssertEqual(dropdown.value as? String, "dropdown-option2-value")
        XCTAssertEqual(dropdown.options?.count, 3)
        XCTAssertEqual(radio.value as? String, "option2 value")
        XCTAssertEqual(radio.key, "radio-group-key")
    }

    func testMapsThePhoneNumberIntoItsThreeFields() async throws {
        let phone = try await mapped("formFieldsForm")[8]

        XCTAssertEqual(phone.id, "phone-field")
        XCTAssertEqual(phone.defaultCountryCode, "BF")
        XCTAssertEqual(phone.validatePhoneNumber, true)
        XCTAssertEqual(phone.showExtension, true)
        XCTAssertEqual(phone.extensionLabel, "Extension")
        XCTAssertEqual(phone.countryCode, "GB")
        XCTAssertEqual(phone.phoneNumber, "(555)555-1234")
        XCTAssertEqual(phone.phoneExtension, "4321")
        XCTAssertNil(phone.value)
    }

    func testMapsTheBooleanWithItsAppearanceAndRichContent() async throws {
        let boolean = try await mapped("formFieldsForm")[9]

        XCTAssertEqual(boolean.id, "single-checkbox-field")
        XCTAssertEqual(boolean.value as? Bool, false)
        XCTAssertEqual(boolean.appearance, "SWITCH")
        XCTAssertEqual(boolean.errorMessage, "Select the checkbox to continue.")
        XCTAssertEqual(boolean.richContent?.content, "I agree to the {{link1}}")
        XCTAssertEqual(boolean.richContent?.replacements?.first??.href, "https://www.pingidentity.com")
    }

    func testMapsButtonsWithAnEmptyValueUntilOneIsChosen() async throws {
        let buttons = try await mapped("formFieldsForm").suffix(3)

        XCTAssertEqual(buttons.map(\.id), ["flow-button-field", "flow-link-field", "submit"])
        XCTAssertEqual(buttons.map(\.label), ["Flow Button", "Flow Link", "Submit"])
        XCTAssertEqual(buttons.map { $0.value as? String }, ["", "", ""])
    }

    func testMapsTextValidationAndTheVerifyPasswordPolicy() async throws {
        let messages = try await mapped("formValidationForm")
        let (username, email, password) = (messages[1], messages[2], messages[3])

        XCTAssertEqual(username.validationRegex, "^[a-zA-Z0-9]+$")
        XCTAssertEqual(username.validationErrorMessage, "Must be alphanumeric")
        XCTAssertEqual(email.validationRegex, "^[^@]+@[^@]+\\.[^@]+$")
        XCTAssertEqual("\(password.type)/\(password.kind)", "PASSWORD_VERIFY/password")
        XCTAssertNil(password.value, "passwords never cross the bridge, formData default included")
        let policy = try XCTUnwrap(password.passwordPolicy)
        XCTAssertEqual(policy.lengthMin, 8)
        XCTAssertEqual(policy.lengthMax, 255)
        XCTAssertEqual(policy.minUniqueCharacters, 5)
        XCTAssertEqual(policy.maxRepeatedCharacters, 2)
        XCTAssertEqual(policy.minCharacters, [
            "~!@#$%^&*()-_=+[]{}|;:,.<>/?": 1,
            "0123456789": 1,
            "ABCDEFGHIJKLMNOPQRSTUVWXYZ": 1,
            "abcdefghijklmnopqrstuvwxyz": 1,
        ])
    }

    func testMapsAnUnboundedPolicyAndAnEmptyRegexToNil() {
        let password = PasswordCollector(with: ["type": "PASSWORD", "key": "p", "passwordPolicy": ["name": "Open"]])
        let text = TextCollector(with: ["type": "TEXT", "key": "t", "validation": ["regex": "", "errorMessage": "x"]])

        let messages = DaVinciCollectorMapper.map([password, text])

        let policy = messages[0].passwordPolicy
        XCTAssertEqual(policy?.lengthMin, 0)
        XCTAssertNil(policy?.lengthMax)
        XCTAssertNil(policy?.maxRepeatedCharacters)
        XCTAssertEqual(policy?.minCharacters, [:])
        XCTAssertNil(messages[1].validationRegex)
        XCTAssertNil(messages[1].validationErrorMessage)
    }

    func testAPasswordWithNoPolicyAnywhereMapsNone() async throws {
        let sso = try await mapped("ssoMenu")

        XCTAssertEqual(sso.map(\.kind), ["text", "password", "submit", "flow", "flow"])
        XCTAssertNil(sso[1].passwordPolicy)
    }

    func testMapsTheAgreementReadOnlyText() async throws {
        let agreement = try await mapped("agreementForm")[0]

        XCTAssertEqual("\(agreement.type)/\(agreement.kind)", "AGREEMENT/readOnlyText")
        XCTAssertEqual(agreement.id, "agreement")
        XCTAssertEqual(agreement.content, "This is example agreement text, you can edit this text in the agreements section.")
        XCTAssertEqual(agreement.title, "Terms of Service Agreement")
        XCTAssertEqual(agreement.titleEnabled, true)
        XCTAssertEqual(agreement.enabled, true)
        XCTAssertEqual(agreement.agreementId, "1c3de4cc-74c0-4a42-b484-4047b10122ce")
        XCTAssertEqual(agreement.useDynamicAgreement, false)
        XCTAssertNil(agreement.value)
    }

    func testMapsTheImage() async throws {
        let messages = try await mapped("imageForm")
        let image = try XCTUnwrap(messages.first { $0.kind == "image" })

        XCTAssertEqual(image.type, "IMAGE")
        XCTAssertEqual(image.id, "image")
        XCTAssertEqual(image.imageDescription, "Image Collector Test")
        XCTAssertEqual(
            image.imageUrl,
            "https://img.magnific.com/free-photo/closeup-shot-beautiful-butterfly-with-interesting-textures-orange-petaled-flower_181624-7640.jpg"
        )
        XCTAssertEqual(image.hyperlinkUrl, "https://www.pingidentity.com/en.html")
        XCTAssertNil(image.value)
    }

    func testRejectsAValueForEveryDisplayOnlyCollector() async throws {
        let agreement = try await continueNode("agreementForm").collectors
        let image = try await continueNode("imageForm").collectors
        let imageIndex = Int64(try XCTUnwrap(image.firstIndex { $0 is ImageCollector }))

        for (collectors, message) in [
            (agreement, CollectorValueMessage(type: "AGREEMENT", index: 0, value: "x")),
            (image, CollectorValueMessage(type: "IMAGE", index: imageIndex, value: "x")),
            (image, CollectorValueMessage(type: "LABEL", index: 0, value: "x")),
        ] {
            XCTAssertThrowsError(try DaVinciCollectorValueApplier.apply(collectors, values: [message])) { error in
                guard case DaVinciHostApiError.argument = error else {
                    return XCTFail("expected an argument error for \(message), got \(error)")
                }
            }
        }
    }
    func testMapsTheQRCodeAsItsDataURINeverDecoded() async throws {
        let messages = try await mapped("qrCodeForm")
        let qrCode = try XCTUnwrap(messages.first { $0.kind == "qrCode" })
        let fields = ((try fixture("qrCodeForm")["form"] as? [String: Any])?["components"] as? [String: Any])?["fields"] as? [[String: Any]]
        let field = try XCTUnwrap(fields?.first { $0["type"] as? String == "QR_CODE" })

        XCTAssertEqual(qrCode.type, "QR_CODE")
        XCTAssertEqual(qrCode.id, "qr-code")
        XCTAssertEqual(qrCode.key, "qr-code")
        XCTAssertEqual(qrCode.content, field["content"] as? String, "2.2.0: the full data URI (SDKS-5299)")
        XCTAssertTrue(qrCode.content?.hasPrefix("data:image/png;base64,") == true)
        XCTAssertEqual(
            qrCode.fallbackText,
            "If you can't scan the QR code, use the following link:https://www.pingidentity.com/en.html"
        )
        XCTAssertNil(qrCode.value)
    }

    func testMapsSimpleAndChallengePolling() async throws {
        let simpleForm = try await mapped("pollingContinueForm")
        let challengeForm = try await mapped("pollingChallengeForm")
        let simple = try XCTUnwrap(simpleForm.first { $0.kind == "polling" })
        let challenge = try XCTUnwrap(challengeForm.first { $0.kind == "polling" })
        let fields = ((try fixture("pollingChallengeForm")["form"] as? [String: Any])?["components"] as? [String: Any])?["fields"] as? [[String: Any]]

        XCTAssertEqual(simple.type, "POLLING")
        XCTAssertEqual(simple.id, "polling-field")
        XCTAssertEqual(simple.pollIntervalMillis, 2000)
        XCTAssertEqual(simple.pollRetries, 3)
        XCTAssertEqual(simple.retriesAllowed, 3)
        XCTAssertEqual(simple.pollChallengeStatus, false)
        XCTAssertNil(simple.challenge)
        XCTAssertNil(simple.value, "polling sets its own value")

        XCTAssertEqual(challenge.pollChallengeStatus, true)
        XCTAssertEqual(challenge.challenge, fields?.first { $0["type"] as? String == "POLLING" }?["challenge"] as? String)
    }

    func testMapsRegistrationDevicesWhichHaveNoId() async throws {
        let registrationForm = try await mapped("deviceRegistrationForm")
        let registration = try XCTUnwrap(registrationForm.first)

        XCTAssertEqual("\(registration.type)/\(registration.kind)", "DEVICE_REGISTRATION/deviceRegistration")
        XCTAssertEqual(registration.key, "device-registration")
        XCTAssertEqual(registration.required, true)
        XCTAssertEqual(registration.devices?.map { $0?.type }, ["EMAIL", "SMS", "VOICE"])
        XCTAssertEqual(
            registration.devices?.first,
            DeviceMessage(
                id: nil,
                type: "EMAIL",
                title: "Email",
                deviceDescription: "Receive an authentication passcode in your email.",
                iconSrc: "https://assets.pingone.com/ux/end-user/2.10.0/images/icon-outline-mail.svg",
                isDefault: false
            ),
            "a missing default is false, as on Android"
        )
        XCTAssertNil(registration.value, "no device chosen yet")
    }

    func testMapsAuthenticationDevicesWithTheirIdsAndDefault() async throws {
        let authenticationForm = try await mapped("deviceAuthenticationForm")
        let authentication = try XCTUnwrap(authenticationForm.first)

        XCTAssertEqual(authentication.kind, "deviceAuthentication")
        XCTAssertEqual(authentication.devices?.map { $0?.id }, ["fixture-device-1", "fixture-device-2", "fixture-device-3"])
        XCTAssertEqual(authentication.devices?.map { $0?.isDefault }, [true, false, false])
        XCTAssertNil(authentication.value)
    }

    func testMapsTheMetadataPayload() async throws {
        let metadataForm = try await mapped("metadataForm")
        let metadata = try XCTUnwrap(metadataForm.first)

        XCTAssertEqual("\(metadata.type)/\(metadata.kind)", "METADATA/metadata")
        XCTAssertEqual(metadata.key, "sdkMetadata")
        XCTAssertEqual(metadata.metadata?.count, 1)
        XCTAssertEqual(metadata.metadata?["testkey"] as? String, "testValue")
        XCTAssertNil(metadata.value, "no result set yet")
    }

    func testSetsAMetadataResultOrErrorWhichTheCollectorTurnsIntoItsPayload() async throws {
        let result = try await continueNode("metadataForm").collectors
        let metadata = try XCTUnwrap(result.first as? MetadataCollector)
        XCTAssertEqual(metadata.validate().count, 1, "Required until a result or error is set")

        try DaVinciCollectorValueApplier.apply(result, values: [CollectorValueMessage(
            type: "METADATA", index: 0, value: ["result": ["ok": true, "count": Int64(2), "tags": ["a", nil]] as [String: Any?]]
        )])
        let payload = try XCTUnwrap(metadata.payload())
        XCTAssertEqual(payload["ok"] as? Bool, true)
        XCTAssertEqual(payload["count"] as? Int64, 2)
        XCTAssertEqual((payload["tags"] as? [Any])?.count, 2)
        XCTAssertTrue((payload["tags"] as? [Any])?.last is NSNull)
        XCTAssertEqual(metadata.actionKey, "sdkMetadata")
        XCTAssertTrue(metadata.validate().isEmpty)

        let error = try await continueNode("metadataForm").collectors
        try DaVinciCollectorValueApplier.apply(error, values: [CollectorValueMessage(
            type: "METADATA", index: 0, value: ["error": ["code": "USER_CANCELLED", "message": "No"]]
        )])
        let errorPayload = try XCTUnwrap((error.first as? MetadataCollector)?.payload()?["error"] as? [String: Any])
        XCTAssertEqual(errorPayload["code"] as? String, "USER_CANCELLED")
        XCTAssertEqual(errorPayload["message"] as? String, "No")
    }

    func testRejectsAMalformedMetadataValue() async throws {
        let cases: [Any?] = [
            "not a map",
            [String: Any](),
            ["result": ["a": 1], "error": ["code": "c", "message": "m"]],
            ["result": [1]],
            ["result": [1: "non-string key"]],
            ["error": ["code": "c"]],
            ["error": ["code": 1, "message": "m"]],
            ["other": [String: Any]()],
        ]
        for bad in cases {
            let collectors = try await continueNode("metadataForm").collectors
            XCTAssertThrowsError(try DaVinciCollectorValueApplier.apply(
                collectors, values: [CollectorValueMessage(type: "METADATA", index: 0, value: bad)]
            )) { error in
                guard case DaVinciHostApiError.argument = error else {
                    return XCTFail("expected an argument error for \(String(describing: bad)), got \(error)")
                }
            }
            XCTAssertNil((collectors.first as? MetadataCollector)?.payload())
        }
    }

    func testSelectsAnAuthenticationDeviceByIdSoItsPayloadIsTheSDKsOwn() async throws {
        let collectors = try await continueNode("deviceAuthenticationForm").collectors

        try DaVinciCollectorValueApplier.apply(collectors, values: [CollectorValueMessage(
            type: "DEVICE_AUTHENTICATION", index: 0, value: ["id": "fixture-device-2", "type": "SMS"]
        )])

        let device = try XCTUnwrap(collectors.first as? DeviceAuthenticationCollector)
        XCTAssertEqual(device.value?.id, "fixture-device-2")
        XCTAssertEqual(device.payload()?["type"] as? String, "SMS")
        XCTAssertThrowsError(try DaVinciCollectorValueApplier.apply(collectors, values: [CollectorValueMessage(
            type: "DEVICE_AUTHENTICATION", index: 0, value: ["id": "no-such-device"]
        )]))
    }

    func testRejectsAValueForPollingAndTheQRCode() async throws {
        let collectors = try await continueNode("pollingQrCodeForm").collectors
        let qrCode = Int64(try XCTUnwrap(collectors.firstIndex { $0 is QRCodeCollector }))
        let polling = Int64(try XCTUnwrap(collectors.firstIndex { $0 is PollingCollector }))

        XCTAssertThrowsError(try DaVinciCollectorValueApplier.apply(
            collectors, values: [CollectorValueMessage(type: "QR_CODE", index: qrCode, value: "x")]
        ))
        XCTAssertThrowsError(try DaVinciCollectorValueApplier.apply(
            collectors, values: [CollectorValueMessage(type: "POLLING", index: polling, value: "continue")]
        )) { error in
            XCTAssertEqual("\(error)", "POLLING at index=\(polling) takes no value from the app: polling sets it")
        }
    }
}

/// `NodeMessage.unsupportedFields`, over captured forms. Mirrors Android's `DaVinciNodeMapperTest`.
final class UnsupportedFieldsTests: XCTestCase {
    private func unsupported(_ input: [String: Any], registered: Set<String>) async -> [[String?: Any?]] {
        await DaVinciNodeMapper.unsupportedFields(input: input) { type, _ in registered.contains(type) }
            .compactMap { $0 as? [String?: Any?] }
    }

    private func describe(_ fields: [[String?: Any?]]) -> [String] {
        fields.map { "\(($0["key"] as? String?).flatMap { $0 } ?? "nil")/\($0["type"] as? String ?? "")" }
    }

    func testReportsFieldsWithNoRegisteredCollectorKeyLessOnesIncluded() async throws {
        let agreement = try fixture("agreementForm")
        let core = CoreCollectorRegistration.types

        let withCore = await unsupported(agreement, registered: core)
        XCTAssertEqual(describe(withCore), ["nil/ERROR_DISPLAY"])
        // The lookup key is inputType ?? type, as in the factory: AGREEMENT resolves through
        // READ_ONLY_TEXT, so dropping that registration drops the field.
        let withoutReadOnly = await unsupported(agreement, registered: core.subtracting(["READ_ONLY_TEXT"]))
        XCTAssertEqual(describe(withoutReadOnly), ["agreement/READ_ONLY_TEXT", "nil/ERROR_DISPLAY"])
    }

    func testReportsAFieldWithAnUnregisteredInputType() async {
        let input: [String: Any] = ["form": ["components": ["fields": [
            ["type": "TEXT", "key": "username"],
            ["type": "TEXT", "inputType": "FUTURE_FIELD", "key": "future"],
            ["type": "PROTECT", "key": "protectsdk"],
        ]]]]

        let fields = await unsupported(input, registered: CoreCollectorRegistration.types)
        XCTAssertEqual(describe(fields), ["future/FUTURE_FIELD", "protectsdk/PROTECT"])
    }

    func testAFormWithEveryFieldRegisteredReportsNothing() async throws {
        let formFields = await unsupported(try fixture("formFieldsForm"), registered: CoreCollectorRegistration.types)
        let empty = await unsupported([:], registered: CoreCollectorRegistration.types)
        XCTAssertTrue(formFields.isEmpty)
        XCTAssertTrue(empty.isEmpty)
    }

    /// The production check: the real factory, through the bridge's own mapping entry point.
    func testTheFactoryProbeMatchesTheRegistry() async throws {
        let node = try await continueNode("agreementForm")
        let daVinci: DaVinci = node.workflow

        let message = await DaVinciNodeMapper.map(node, daVinci: daVinci)

        XCTAssertEqual(describe((message.unsupportedFields ?? []).compactMap { $0 as? [String?: Any?] }), ["nil/ERROR_DISPLAY"])
        XCTAssertEqual(message.collectors?.count, 3)
    }
}
