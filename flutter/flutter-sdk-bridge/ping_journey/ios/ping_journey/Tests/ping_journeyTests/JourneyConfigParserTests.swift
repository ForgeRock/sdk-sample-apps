/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import XCTest
import PingOidc
import ping_core
@testable import ping_journey

/// Test-local `OidcConfigHandle` implementation, registered directly into
/// `CoreRuntime.oidcClientRegistry` so these tests can exercise `JourneyConfigParser`'s
/// handle-resolution path with no `ping_oidc` test dependency.
private final class FakeOidcConfigHandle: NativeHandle, OidcConfigHandle {
    let clientId: String
    let discoveryEndpoint: String?
    let openId: OidcOpenIdConfig?
    let redirectUri: String?
    let scopes: [String]
    let acrValues: String?
    let signOutRedirectUri: String?
    let state: String?
    let nonce: String?
    let uiLocales: String?
    let refreshThreshold: Int64?
    let loginHint: String?
    let display: String?
    let prompt: String?
    let additionalParameters: [String: String]
    let par: Bool

    init(
        clientId: String = "client-1",
        discoveryEndpoint: String? = "https://example.com/.well-known/openid-configuration",
        openId: OidcOpenIdConfig? = nil,
        redirectUri: String? = "https://example.com/callback",
        scopes: [String] = ["openid", "profile"],
        acrValues: String? = nil,
        signOutRedirectUri: String? = nil,
        state: String? = nil,
        nonce: String? = nil,
        uiLocales: String? = nil,
        refreshThreshold: Int64? = nil,
        loginHint: String? = nil,
        display: String? = nil,
        prompt: String? = nil,
        additionalParameters: [String: String] = [:],
        par: Bool = false
    ) {
        self.clientId = clientId
        self.discoveryEndpoint = discoveryEndpoint
        self.openId = openId
        self.redirectUri = redirectUri
        self.scopes = scopes
        self.acrValues = acrValues
        self.signOutRedirectUri = signOutRedirectUri
        self.state = state
        self.nonce = nonce
        self.uiLocales = uiLocales
        self.refreshThreshold = refreshThreshold
        self.loginHint = loginHint
        self.display = display
        self.prompt = prompt
        self.additionalParameters = additionalParameters
        self.par = par
    }
}

/// Unit tests for `JourneyConfigParser`'s handle-resolution logic.
///
/// These call `JourneyConfigParser.resolveOidcHandle`/`applyHandleFields` directly rather than
/// through `parse` — `parse` always constructs a full native `Journey` via
/// `Journey.createJourney`, which this module's tests cannot currently run standalone outside a
/// full `flutter build ios`. `hasOidcFields` is a pure field check and is
/// tested directly too.
final class JourneyConfigParserTests: XCTestCase {
    private var registeredIds: [String] = []

    override func tearDown() async throws {
        for id in registeredIds {
            await CoreRuntime.oidcClientRegistry.remove(id)
        }
        registeredIds = []
    }

    private func register(_ handle: FakeOidcConfigHandle) async -> String {
        let id = await CoreRuntime.oidcClientRegistry.register(handle)
        registeredIds.append(id)
        return id
    }

    func testResolveOidcHandleReturnsTheRegisteredHandle() async throws {
        let id = await register(FakeOidcConfigHandle(clientId: "client-42"))

        let handle = try await JourneyConfigParser.resolveOidcHandle(id)

        XCTAssertEqual(handle.clientId, "client-42")
    }

    func testResolveOidcHandleThrowsForAnUnregisteredId() async {
        do {
            _ = try await JourneyConfigParser.resolveOidcHandle("not-registered")
            XCTFail("Expected resolveOidcHandle to throw")
        } catch JourneyHostApiError.argument(let message) {
            XCTAssertTrue(message.contains("OIDC client instance not found for id=not-registered"))
        } catch {
            XCTFail("Expected JourneyHostApiError.argument, got \(error)")
        }
    }

    func testResolveOidcHandleThrowsWhenTheHandleHasNeitherDiscoveryEndpointNorOpenId() async {
        let id = await register(FakeOidcConfigHandle(discoveryEndpoint: nil, openId: nil))

        do {
            _ = try await JourneyConfigParser.resolveOidcHandle(id)
            XCTFail("Expected resolveOidcHandle to throw")
        } catch JourneyHostApiError.argument(let message) {
            XCTAssertTrue(message.contains("does not expose discoveryEndpoint or openId"))
        } catch {
            XCTFail("Expected JourneyHostApiError.argument, got \(error)")
        }
    }

    func testResolveOidcHandleSucceedsWhenTheHandleExposesOnlyOpenId() async throws {
        let openId = OidcOpenIdConfig(
            authorizationEndpoint: "https://example.com/authorize",
            tokenEndpoint: "https://example.com/token",
            userinfoEndpoint: "https://example.com/userinfo"
        )
        let id = await register(FakeOidcConfigHandle(discoveryEndpoint: nil, openId: openId))

        let handle = try await JourneyConfigParser.resolveOidcHandle(id)

        XCTAssertNil(handle.discoveryEndpoint)
        XCTAssertEqual(handle.openId?.authorizationEndpoint, "https://example.com/authorize")
    }

    func testApplyHandleFieldsMapsClientIdDiscoveryEndpointRedirectUriAndScopes() {
        let handle = FakeOidcConfigHandle(
            clientId: "client-42",
            discoveryEndpoint: "https://example.com/.well-known/openid-configuration",
            redirectUri: "https://example.com/callback",
            scopes: ["openid", "email"]
        )
        let config = OidcClientConfig()

        JourneyConfigParser.applyHandleFields(handle, to: config)

        XCTAssertEqual(config.clientId, "client-42")
        XCTAssertEqual(config.discoveryEndpoint, "https://example.com/.well-known/openid-configuration")
        XCTAssertEqual(config.redirectUri, "https://example.com/callback")
        XCTAssertEqual(config.scopes, Set(["openid", "email"]))
    }

    func testApplyHandleFieldsMapsPar() {
        let handle = FakeOidcConfigHandle(par: true)
        let config = OidcClientConfig()

        JourneyConfigParser.applyHandleFields(handle, to: config)

        XCTAssertTrue(config.par)
    }

    func testHasOidcFieldsReturnsTrueWhenOnlyOidcClientIdIsSet() {
        var message = JourneyConfigMessage(serverUrl: "https://example.com/am")
        message.oidcClientId = "any-id"

        XCTAssertTrue(JourneyConfigParser.hasOidcFields(message))
    }

    func testHasOidcFieldsReturnsTrueForTheExistingInlineOnlyPath() {
        var message = JourneyConfigMessage(serverUrl: "https://example.com/am")
        message.clientId = "client-1"

        XCTAssertTrue(JourneyConfigParser.hasOidcFields(message))
    }

    func testHasOidcFieldsReturnsFalseWhenNeitherOidcClientIdNorInlineFieldsAreSet() {
        let message = JourneyConfigMessage(serverUrl: "https://example.com/am")

        XCTAssertFalse(JourneyConfigParser.hasOidcFields(message))
    }
}
