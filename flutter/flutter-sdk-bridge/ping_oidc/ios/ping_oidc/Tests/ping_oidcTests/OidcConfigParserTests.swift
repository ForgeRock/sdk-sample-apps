/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import XCTest
@testable import ping_oidc

/// Unit tests for `OidcConfigParser`'s validation and field-mapping logic.
final class OidcConfigParserTests: XCTestCase {

    private func baseMessage(discoveryEndpoint: String? = nil, openId: OidcOpenIdConfigMessage? = nil) -> OidcConfigMessage {
        var message = OidcConfigMessage(
            clientId: "client-1",
            redirectUri: "https://example.com/callback",
            par: false
        )
        message.discoveryEndpoint = discoveryEndpoint
        message.openId = openId
        return message
    }

    func testParseThrowsWhenNeitherDiscoveryEndpointNorOpenIdIsSet() {
        let message = baseMessage()

        XCTAssertThrowsError(try OidcConfigParser.parse(message)) { error in
            guard case OidcHostApiError.argumentError = error else {
                XCTFail("Expected argumentError, got \(error)")
                return
            }
        }
    }

    func testParseSucceedsWhenOnlyDiscoveryEndpointIsSet() throws {
        let message = baseMessage(discoveryEndpoint: "https://example.com/.well-known/openid-configuration")

        let result = try OidcConfigParser.parse(message)

        XCTAssertEqual(result.discoveryEndpoint, "https://example.com/.well-known/openid-configuration")
    }

    func testParseThrowsWhenOnlyOpenIdIsSetWithNoDiscoveryEndpoint() {
        let openId = OidcOpenIdConfigMessage(
            authorizationEndpoint: "https://example.com/authorize",
            tokenEndpoint: "https://example.com/token",
            userinfoEndpoint: "https://example.com/userinfo"
        )
        let message = baseMessage(openId: openId)

        // Must throw — `openIdOverride` cannot fire without a prior successful `discover()`
        // call, so an openId-only config can never actually populate `openId` on iOS at 2.1.0.
        XCTAssertThrowsError(try OidcConfigParser.parse(message)) { error in
            guard case OidcHostApiError.argumentError = error else {
                XCTFail("Expected argumentError, got \(error)")
                return
            }
        }
    }

    func testParseSucceedsWhenBothDiscoveryEndpointAndOpenIdAreSet() throws {
        let openId = OidcOpenIdConfigMessage(
            authorizationEndpoint: "https://example.com/authorize",
            tokenEndpoint: "https://example.com/token",
            userinfoEndpoint: "https://example.com/userinfo"
        )
        let message = baseMessage(
            discoveryEndpoint: "https://example.com/.well-known/openid-configuration",
            openId: openId
        )

        // Must not throw — discoveryEndpoint is present, so openId is a valid override on top
        // of it rather than a standalone (and unreachable) config source.
        XCTAssertNoThrow(try OidcConfigParser.parse(message))
    }

    func testParseMapsClientIdAndRedirectUri() throws {
        let message = baseMessage(discoveryEndpoint: "https://example.com/.well-known/openid-configuration")

        let result = try OidcConfigParser.parse(message)

        XCTAssertEqual(result.clientId, "client-1")
        XCTAssertEqual(result.redirectUri, "https://example.com/callback")
    }

    func testParseMapsPar() throws {
        var message = OidcConfigMessage(
            clientId: "client-1",
            redirectUri: "https://example.com/callback",
            par: true
        )
        message.discoveryEndpoint = "https://example.com/.well-known/openid-configuration"

        let result = try OidcConfigParser.parse(message)

        XCTAssertTrue(result.par)
    }

    func testParseConvertsRefreshThresholdSeconds() throws {
        var message = baseMessage(discoveryEndpoint: "https://example.com/.well-known/openid-configuration")
        message.refreshThresholdSeconds = 120

        let result = try OidcConfigParser.parse(message)

        XCTAssertEqual(result.refreshThreshold, 120)
    }

    func testApplyMapsFieldsOntoAnExistingConfig() {
        let message = baseMessage(discoveryEndpoint: "https://example.com/.well-known/openid-configuration")
        let config = OidcClientConfig()

        OidcConfigParser.apply(config, from: message)

        XCTAssertEqual(config.clientId, "client-1")
        XCTAssertEqual(config.redirectUri, "https://example.com/callback")
        XCTAssertEqual(config.discoveryEndpoint, "https://example.com/.well-known/openid-configuration")
    }
}
