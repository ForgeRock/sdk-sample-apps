/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import XCTest
import PingOidc
@testable import ping_davinci

private func hoisted() -> DaVinciConfigMessage {
    DaVinciConfigMessage(
        clientId: "client",
        discoveryEndpoint: "https://example.com/.well-known/openid-configuration",
        redirectUri: "com.example://callback"
    )
}

final class DaVinciConfigParserTests: XCTestCase {
    func testValidateAcceptsACompleteHoistedConfig() throws {
        XCTAssertNoThrow(try DaVinciConfigParser.validate(hoisted()))
    }

    func testValidateAcceptsAnOpenIdOnlyHoistedConfig() {
        var config = hoisted()
        config.discoveryEndpoint = nil
        config.openId = OpenIdConfigMessage(
            authorizationEndpoint: "https://a", tokenEndpoint: "https://t", userinfoEndpoint: "https://u"
        )
        XCTAssertNoThrow(try DaVinciConfigParser.validate(config))
    }

    func testValidateAcceptsOidcClientIdAlone() {
        XCTAssertNoThrow(try DaVinciConfigParser.validate(DaVinciConfigMessage(oidcClientId: "some-id")))
    }

    func testValidateRejectsOidcClientIdCombinedWithAnInlineField() {
        XCTAssertThrowsError(try DaVinciConfigParser.validate(DaVinciConfigMessage(acrValues: "flow", oidcClientId: "id")))
        XCTAssertThrowsError(try DaVinciConfigParser.validate(DaVinciConfigMessage(par: false, oidcClientId: "id")))
    }

    func testValidateRejectsAConfigWithNeitherDiscoveryEndpointNorOpenId() {
        var config = hoisted()
        config.discoveryEndpoint = "  "
        XCTAssertThrowsError(try DaVinciConfigParser.validate(config)) { error in
            XCTAssertEqual(String(describing: error), "DaVinciConfigMessage requires discoveryEndpoint or openId.")
        }
    }

    func testValidateRejectsAConfigWithNoOidcAtAll() {
        XCTAssertThrowsError(try DaVinciConfigParser.validate(DaVinciConfigMessage()))
    }

    func testApplyMessageFieldsMapsEveryHoistedField() {
        var message = hoisted()
        message.scopes = ["openid", nil, "email"]
        message.acrValues = "flow-acr"
        message.state = "s"
        message.nonce = "n"
        message.uiLocales = "en"
        message.refreshThreshold = 60
        message.loginHint = "user"
        message.display = "page"
        message.prompt = "login"
        message.additionalParameters = ["k": "v", "drop": nil]
        message.par = true
        let config = OidcClientConfig()

        DaVinciConfigParser.applyMessageFields(message, to: config)

        XCTAssertEqual(config.clientId, "client")
        XCTAssertEqual(config.redirectUri, "com.example://callback")
        XCTAssertEqual(config.discoveryEndpoint, "https://example.com/.well-known/openid-configuration")
        XCTAssertEqual(config.scopes, ["openid", "email"])
        XCTAssertEqual(config.acrValues, "flow-acr")
        XCTAssertEqual(config.state, "s")
        XCTAssertEqual(config.nonce, "n")
        XCTAssertEqual(config.uiLocales, "en")
        XCTAssertEqual(config.refreshThreshold, 60)
        XCTAssertEqual(config.loginHint, "user")
        XCTAssertEqual(config.display, "page")
        XCTAssertEqual(config.prompt, "login")
        XCTAssertEqual(config.additionalParameters, ["k": "v"])
        XCTAssertTrue(config.par)
    }

    func testApplyMessageFieldsWithOpenIdOnlySetsOpenIdDirectly() {
        var message = hoisted()
        message.discoveryEndpoint = nil
        message.openId = OpenIdConfigMessage(
            authorizationEndpoint: "https://a", tokenEndpoint: "https://t", userinfoEndpoint: "https://u"
        )
        let config = OidcClientConfig()

        DaVinciConfigParser.applyMessageFields(message, to: config)

        XCTAssertEqual(config.openId?.tokenEndpoint, "https://t")
        XCTAssertNil(config.openIdOverride)
    }
}

final class CoreCollectorRegistrationTests: XCTestCase {
    /// The 17 Android keys plus iOS's six aliases, as `DaVinci.swift` registers them at 2.2.0.
    func testRegistrationTableMatchesTheSdk() {
        let keys = CoreCollectorRegistration.registrations.map(\.type)
        XCTAssertEqual(keys.count, 23)
        XCTAssertEqual(Set(keys).count, 23)
        XCTAssertTrue(Set(keys).isSuperset(of: ["TEXT", "IMAGE", "METADATA", "DEVICE_AUTHENTICATION"]))
    }
}

final class DaVinciErrorMapperTests: XCTestCase {
    private func type(of error: Error) -> String? {
        DaVinciErrorMapper.from(DaVinciErrorCodes.configure, error).details as? String
    }

    func testBridgeErrorsMapToTheirTypes() {
        XCTAssertEqual(type(of: DaVinciHostApiError.argument("x")), "argument")
        XCTAssertEqual(type(of: DaVinciHostApiError.stateError("x")), "state")
        XCTAssertEqual(type(of: DaVinciHostApiError.daVinciNotFound("x")), "state")
        XCTAssertEqual(type(of: DaVinciHostApiError.unsupported("x")), "unsupported")
    }

    func testOidcConfigurationErrorMapsToArgument() {
        XCTAssertEqual(type(of: OidcError.configurationError(message: "no endpoint")), "argument")
    }
}
