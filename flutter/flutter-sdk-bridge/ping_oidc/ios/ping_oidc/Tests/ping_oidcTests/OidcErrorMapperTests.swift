/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import XCTest
import PingOidc
@testable import ping_oidc

/// Unit tests for `OidcErrorMapper`'s classification logic.
final class OidcErrorMapperTests: XCTestCase {

    private let code = "OIDC_TEST_ERROR"

    private struct SampleError: Error {}

    // --- from(_:_:Error) -----------------------------------------------------------------------

    func testFromReturnsTheSamePigeonErrorUnchanged() {
        let original = PigeonError(code: "SOME_CODE", message: "already classified", details: "state")

        let result = OidcErrorMapper.from(code, original)

        XCTAssertTrue(result === original)
    }

    func testFromClassifiesArgumentErrorAsArgument() {
        let error = OidcHostApiError.argumentError("bad argument")

        let result = OidcErrorMapper.from(code, error)

        XCTAssertEqual(result.code, code)
        XCTAssertEqual(result.details as? String, "argument")
    }

    func testFromClassifiesStateErrorAsState() {
        let error = OidcHostApiError.stateError("bad state")

        let result = OidcErrorMapper.from(code, error)

        XCTAssertEqual(result.details as? String, "state")
    }

    func testFromUsesThePlainErrorMessageNotEnumReflection() {
        let error = OidcHostApiError.argumentError("OidcConfigMessage must set either discoveryEndpoint or openId")

        let result = OidcErrorMapper.from(code, error)

        XCTAssertEqual(result.message, "OidcConfigMessage must set either discoveryEndpoint or openId")
    }

    func testFromClassifiesUnrecognizedErrorTypesAsUnknown() {
        let error = SampleError()

        let result = OidcErrorMapper.from(code, error)

        XCTAssertEqual(result.details as? String, "unknown")
    }

    func testFromPreservesTheGivenCode() {
        let error = OidcHostApiError.stateError("bad state")

        let result = OidcErrorMapper.from("OIDC_CONFIGURE_ERROR", error)

        XCTAssertEqual(result.code, "OIDC_CONFIGURE_ERROR")
    }

    func testFromDispatchesOidcErrorToTheOidcOverload() {
        let error = OidcError.networkError(cause: nil, message: "no connection")

        let result = OidcErrorMapper.from(code, error as Error)

        XCTAssertEqual(result.details as? String, "network")
    }

    // --- from(_:_:OidcError) --------------------------------------------------------------------

    func testFromOidcErrorClassifiesAuthorizeErrorAsAuth() {
        let error = OidcError.authorizeError(cause: nil, message: "auth failed")

        let result = OidcErrorMapper.from(code, error)

        XCTAssertEqual(result.details as? String, "auth")
        XCTAssertEqual(result.message, error.errorMessage)
    }

    func testFromOidcErrorClassifiesNetworkErrorAsNetwork() {
        let error = OidcError.networkError(cause: nil, message: "no connection")

        let result = OidcErrorMapper.from(code, error)

        XCTAssertEqual(result.details as? String, "network")
    }

    func testFromOidcErrorClassifiesApiErrorAsExchange() {
        let error = OidcError.apiError(code: 403, message: "forbidden")

        let result = OidcErrorMapper.from(code, error)

        XCTAssertEqual(result.details as? String, "exchange")
        XCTAssertEqual(result.message, error.errorMessage)
    }

    func testFromOidcErrorClassifiesUnknownAsUnknown() {
        let error = OidcError.unknown(cause: nil, message: "mystery")

        let result = OidcErrorMapper.from(code, error)

        XCTAssertEqual(result.details as? String, "unknown")
    }

    // --- notImplemented -------------------------------------------------------------------------

    func testNotImplementedReturnsAStableNotImplementedClassification() {
        let result = OidcErrorMapper.notImplemented(OidcErrorCodes.authorize)

        XCTAssertEqual(result.code, OidcErrorCodes.authorize)
        XCTAssertEqual(result.details as? String, "not_implemented")
    }
}
