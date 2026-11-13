/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import XCTest
import PingDavinci
import PingOidc
import PingOrchestrate
@testable import ping_davinci

final class DaVinciSessionMapperTests: XCTestCase {
    private func successResponse(_ authorizeResponse: [String: Any]) -> SessionResponse {
        SessionResponse(json: ["authorizeResponse": authorizeResponse])
    }

    func testSessionMapsTheAuthorizationCode() throws {
        let message = try DaVinciSessionMapper.session(successResponse(["code": "code-1"]))
        XCTAssertEqual(message.authorizationCode, "code-1")
    }

    /// iOS's `SessionResponse` returns `""` for a missing code where Android throws
    /// `AuthorizeException`; the bridge turns both into an `auth` error.
    func testAMissingCodeIsAnAuthError() {
        XCTAssertThrowsError(try DaVinciSessionMapper.session(successResponse([:]))) { error in
            let mapped = DaVinciErrorMapper.from(DaVinciErrorCodes.getSession, error)
            XCTAssertEqual(mapped.code, DaVinciErrorCodes.getSession)
            XCTAssertEqual(mapped.details as? String, "auth")
        }
    }

    func testTokenMapsEveryField() {
        let token = Token(
            accessToken: "access",
            tokenType: "Bearer",
            scope: "openid profile",
            expiresIn: 3599,
            refreshToken: "refresh",
            idToken: "id"
        )
        XCTAssertEqual(
            DaVinciSessionMapper.token(token),
            TokenMessage(
                accessToken: "access",
                tokenType: "Bearer",
                scope: "openid profile",
                expiresIn: 3599,
                refreshToken: "refresh",
                idToken: "id"
            )
        )
    }

    func testTokenLeavesAbsentOptionalFieldsNil() {
        let token = Token(accessToken: "access", tokenType: nil, scope: nil, expiresIn: 60, refreshToken: nil, idToken: nil)
        XCTAssertEqual(DaVinciSessionMapper.token(token), TokenMessage(accessToken: "access", expiresIn: 60))
    }

    /// Userinfo arrives from `JSONSerialization`; nested containers and `NSNull` pass through as-is.
    func testUserInfoKeepsJsonValues() throws {
        let json = #"{"sub":"user-1","email_verified":true,"address":{"country":"CA"},"groups":["a"],"middle_name":null}"#
        let userInfo = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(json.utf8)) as? UserInfo
        )

        let mapped = DaVinciSessionMapper.userInfo(userInfo)

        XCTAssertEqual(mapped.count, 5)
        XCTAssertEqual(mapped["sub"] as? String, "user-1")
        XCTAssertEqual(mapped["email_verified"] as? Bool, true)
        XCTAssertEqual((mapped["address"] as? [String: Any])?["country"] as? String, "CA")
        XCTAssertEqual(mapped["groups"] as? [String], ["a"])
        XCTAssertTrue(mapped["middle_name"].flatMap { $0 } is NSNull)
    }
}
