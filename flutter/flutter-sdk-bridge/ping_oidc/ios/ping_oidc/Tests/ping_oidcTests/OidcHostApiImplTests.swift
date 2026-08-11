/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import XCTest
@testable import ping_oidc

/// Unit tests for `OidcHostApiImpl`'s Phase 4 methods.
///
/// `OidcWebClient` is a concrete native class (not a protocol), so there's no seam here to inject
/// a fake `User` in place of a real one — these tests cover only the "no session" failure path,
/// which is reachable via the real (empty) registry with no native scaffolding required. Full
/// method-body coverage against a real signed-in session is exercised at the runtime verification
/// gate instead (see IMPLEMENTATION_PLAN_OIDC.md Phase 4).
final class OidcHostApiImplTests: XCTestCase {
    private let impl = OidcHostApiImpl()

    private func awaitToken(_ webClientId: String) async -> Result<TokenMessage, Error> {
        await withCheckedContinuation { continuation in
            impl.token(webClientId: webClientId) { continuation.resume(returning: $0) }
        }
    }

    private func awaitRefresh(_ webClientId: String) async -> Result<TokenMessage, Error> {
        await withCheckedContinuation { continuation in
            impl.refresh(webClientId: webClientId) { continuation.resume(returning: $0) }
        }
    }

    private func awaitUserInfo(_ webClientId: String) async -> Result<[String?: Any?], Error> {
        await withCheckedContinuation { continuation in
            impl.userInfo(webClientId: webClientId, cache: false) {
                continuation.resume(returning: $0)
            }
        }
    }

    private func awaitRevoke(_ webClientId: String) async -> Result<Void, Error> {
        await withCheckedContinuation { continuation in
            impl.revoke(webClientId: webClientId) { continuation.resume(returning: $0) }
        }
    }

    private func awaitSignOff(_ webClientId: String) async -> Result<Bool, Error> {
        await withCheckedContinuation { continuation in
            impl.signOff(webClientId: webClientId) { continuation.resume(returning: $0) }
        }
    }

    func testTokenSurfacesATypedErrorForAnUnknownWebClientId() async {
        guard case .failure(let error as PigeonError) = await awaitToken("unknown-id") else {
            XCTFail("Expected a PigeonError failure")
            return
        }
        XCTAssertEqual(error.code, OidcErrorCodes.token)
    }

    func testRefreshSurfacesATypedErrorForAnUnknownWebClientId() async {
        guard case .failure(let error as PigeonError) = await awaitRefresh("unknown-id") else {
            XCTFail("Expected a PigeonError failure")
            return
        }
        XCTAssertEqual(error.code, OidcErrorCodes.refresh)
    }

    func testUserInfoSurfacesATypedErrorForAnUnknownWebClientId() async {
        guard case .failure(let error as PigeonError) = await awaitUserInfo("unknown-id") else {
            XCTFail("Expected a PigeonError failure")
            return
        }
        XCTAssertEqual(error.code, OidcErrorCodes.userInfo)
    }

    func testRevokeSurfacesATypedErrorForAnUnknownWebClientId() async {
        guard case .failure(let error as PigeonError) = await awaitRevoke("unknown-id") else {
            XCTFail("Expected a PigeonError failure")
            return
        }
        XCTAssertEqual(error.code, OidcErrorCodes.revoke)
    }

    func testSignOffSurfacesATypedErrorForAnUnknownWebClientId() async {
        guard case .failure(let error as PigeonError) = await awaitSignOff("unknown-id") else {
            XCTFail("Expected a PigeonError failure")
            return
        }
        XCTAssertEqual(error.code, OidcErrorCodes.signOff)
    }

    func testTheMissingSessionIsClassifiedAsStateAndNamesTheId() async {
        guard case .failure(let error as PigeonError) = await awaitToken("unknown-id") else {
            XCTFail("Expected a PigeonError failure")
            return
        }
        XCTAssertEqual(error.details as? String, "state")
        XCTAssertTrue((error.message ?? "").contains("unknown-id"))
    }
}
