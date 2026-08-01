/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import XCTest
import PingJourney
import PingOidc
@testable import ping_journey

/// Unit tests for `JourneyErrorMapper`'s classification logic (`from(_:_:Error)` and
/// `from(_:_:OidcError)`).
final class JourneyErrorMapperTests: XCTestCase {

    private let code = "JOURNEY_TEST_ERROR"

    private struct SampleError: Error {}

    // --- from(_:_:Error) -----------------------------------------------------------------------

    func testFromReturnsTheSamePigeonErrorUnchanged() {
        let original = PigeonError(code: "SOME_CODE", message: "already classified", details: "state")

        let result = JourneyErrorMapper.from(code, original)

        XCTAssertTrue(result === original)
    }

    func testFromClassifiesJourneyNotFoundAsState() {
        let error = JourneyHostApiError.journeyNotFound("missing journey")

        let result = JourneyErrorMapper.from(code, error)

        XCTAssertEqual(result.code, code)
        XCTAssertEqual(result.details as? String, "state")
    }

    func testFromClassifiesStateErrorAsState() {
        let error = JourneyHostApiError.stateError("bad state")

        let result = JourneyErrorMapper.from(code, error)

        XCTAssertEqual(result.details as? String, "state")
    }

    func testFromClassifiesUnsupportedAsUnsupported() {
        // Matches Kotlin's UnsupportedOperationException -> "unsupported" mapping for the same
        // logical case (an unmapped callback type reaching value application).
        let error = JourneyHostApiError.unsupported("not supported")

        let result = JourneyErrorMapper.from(code, error)

        XCTAssertEqual(result.details as? String, "unsupported")
    }

    func testFromClassifiesCallbackApplyAsArgument() {
        let error = JourneyHostApiError.callbackApply("bad callback value")

        let result = JourneyErrorMapper.from(code, error)

        XCTAssertEqual(result.details as? String, "argument")
    }

    func testFromUsesThePlainErrorMessageNotEnumReflection() {
        let error = JourneyHostApiError.stateError("No active ContinueNode found for journeyId=abc")

        let result = JourneyErrorMapper.from(code, error)

        XCTAssertEqual(result.message, "No active ContinueNode found for journeyId=abc")
    }

    func testFromClassifiesUnrecognizedErrorTypesAsUnknown() {
        let error = SampleError()

        let result = JourneyErrorMapper.from(code, error)

        XCTAssertEqual(result.details as? String, "unknown")
    }

    func testFromPreservesTheGivenCode() {
        let error = JourneyHostApiError.stateError("bad state")

        let result = JourneyErrorMapper.from("JOURNEY_NEXT_ERROR", error)

        XCTAssertEqual(result.code, "JOURNEY_NEXT_ERROR")
    }

    func testFromDispatchesOidcErrorToTheOidcOverload() {
        let error = OidcError.networkError(cause: nil, message: "no connection")

        let result = JourneyErrorMapper.from(code, error as Error)

        XCTAssertEqual(result.details as? String, "network")
    }

    // --- from(_:_:OidcError) --------------------------------------------------------------------

    func testFromOidcErrorClassifiesAuthorizeErrorAsAuth() {
        let error = OidcError.authorizeError(cause: nil, message: "auth failed")

        let result = JourneyErrorMapper.from(code, error)

        XCTAssertEqual(result.details as? String, "auth")
        XCTAssertEqual(result.message, error.errorMessage)
    }

    func testFromOidcErrorClassifiesNetworkErrorAsNetwork() {
        let error = OidcError.networkError(cause: nil, message: "no connection")

        let result = JourneyErrorMapper.from(code, error)

        XCTAssertEqual(result.details as? String, "network")
    }

    func testFromOidcErrorClassifiesApiErrorAsExchange() {
        let error = OidcError.apiError(code: 403, message: "forbidden")

        let result = JourneyErrorMapper.from(code, error)

        XCTAssertEqual(result.details as? String, "exchange")
        XCTAssertEqual(result.message, error.errorMessage)
    }

    func testFromOidcErrorClassifiesUnknownAsUnknown() {
        let error = OidcError.unknown(cause: nil, message: "mystery")

        let result = JourneyErrorMapper.from(code, error)

        XCTAssertEqual(result.details as? String, "unknown")
    }
}
