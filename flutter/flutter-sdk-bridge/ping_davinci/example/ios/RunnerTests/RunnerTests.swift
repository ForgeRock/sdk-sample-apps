/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import XCTest
import PingDavinci
import PingDavinciPlugin
import ping_core
@testable import ping_davinci

/// The iOS collector-registration race, measured natively where it can actually be observed.
///
/// Through the Flutter channel the race never shows: the round trip after `configure` gives the
/// SDK's detached registration `Task` time to finish. Here the factory is probed with no gap at
/// all, straight after construction, once with the SDK alone and once through the bridge.
final class CollectorRegistrationRaceTests: XCTestCase {
    private static let iterations = 50

    private func config() -> DaVinciConfigMessage {
        DaVinciConfigMessage(
            clientId: "client",
            discoveryEndpoint: "http://127.0.0.1:9/as/.well-known/openid-configuration",
            redirectUri: "pingdavinciexample://callback"
        )
    }

    /// Evidence that the race exists: with only `DaVinci.createDaVinci`, the factory is sometimes
    /// incomplete when construction returns. Skips (rather than fails) if no run catches it, since
    /// the outcome depends on thread scheduling.
    func testSdkAloneCanReturnBeforeCollectorsAreRegistered() async throws {
        let expected = CoreCollectorRegistration.registrations.count
        var incomplete = 0
        for _ in 0..<Self.iterations {
            await CollectorFactory.shared.reset()
            let daVinci = DaVinci.createDaVinci()
            if await CoreCollectorRegistration.resolvableTypes(daVinci: daVinci).count < expected {
                incomplete += 1
            }
        }
        let summary = XCTAttachment(
            string: "SDK alone: \(incomplete)/\(Self.iterations) constructions returned with an incomplete factory"
        )
        summary.lifetime = .keepAlways
        add(summary)
        try XCTSkipIf(incomplete == 0, "The race did not occur in \(Self.iterations) runs")
    }

    /// The fix: through `DaVinciFactory.create`, every core key resolves every time.
    func testBridgeFactoryAlwaysReturnsWithAllCollectorsRegistered() async throws {
        let expected = Set(CoreCollectorRegistration.registrations.map(\.type))
        for iteration in 0..<Self.iterations {
            await CollectorFactory.shared.reset()
            let id = try await DaVinciFactory.create(config())
            let resolved = await CoreRuntime.davinciRegistry.resolve(id)
            let handle = try XCTUnwrap(resolved as? DaVinciHandle)
            let types = await CoreCollectorRegistration.resolvableTypes(daVinci: handle.daVinci)
            XCTAssertEqual(Set(types), expected, "iteration \(iteration)")
            await CoreRuntime.davinciRegistry.remove(id)
        }
    }
}
