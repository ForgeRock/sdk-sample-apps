/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingDavinci
import ping_core

/// Wraps a live native DaVinci workflow so it can be stored in `CoreRuntime.davinciRegistry`.
final class DaVinciHandle: NativeHandle, @unchecked Sendable {
    let daVinci: DaVinci

    init(daVinci: DaVinci) {
        self.daVinci = daVinci
    }
}

/// Builds a native DaVinci workflow from a `DaVinciConfigMessage` and registers it in the shared
/// core registry, returning the generated `daVinciId`.
enum DaVinciFactory {
    static func create(_ config: DaVinciConfigMessage) async throws -> String {
        let daVinci = try await DaVinciConfigParser.parse(config)
        // Must complete before the id is returned: see CoreCollectorRegistration.
        await CoreCollectorRegistration.register()
        return await CoreRuntime.davinciRegistry.register(DaVinciHandle(daVinci: daVinci))
    }
}
