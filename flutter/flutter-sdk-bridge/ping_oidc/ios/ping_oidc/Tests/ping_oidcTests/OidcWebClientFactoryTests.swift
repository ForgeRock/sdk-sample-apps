/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import XCTest
@testable import ping_oidc

/// Unit tests for `OidcWebClientFactory`'s handle-resolution validation.
final class OidcWebClientFactoryTests: XCTestCase {

    func testCreateThrowsForAnUnknownClientHandleId() async {
        do {
            _ = try await OidcWebClientFactory.create(clientHandleId: "unknown-id", options: nil)
            XCTFail("Expected create to throw for an unknown handle id")
        } catch let error as OidcHostApiError {
            XCTAssertTrue(error.description.contains("unknown-id"))
        } catch {
            XCTFail("Expected OidcHostApiError, got \(error)")
        }
    }
}
