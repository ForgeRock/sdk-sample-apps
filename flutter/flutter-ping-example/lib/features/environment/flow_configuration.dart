/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:ping_example/core/session/session_coordinator.dart';
import 'package:ping_example/core/widgets/config_row.dart';
import 'package:ping_example/features/davinci/config/davinci_env.dart';
import 'package:ping_example/features/journey/config/journey_env.dart';
import 'package:ping_example/features/oidc/config/oidc_env.dart';

/// Whether each flow has the values it can't start without.
extension PingFlowConfiguration on PingFlow {
  /// The values the flow can't start without. Journey's OIDC client is optional: it can run as a
  /// session-only login.
  List<String> get requiredValues => switch (this) {
    PingFlow.journey => [JourneyEnv.serverUrl, JourneyEnv.realm],
    PingFlow.davinci => [
      DaVinciEnv.discoveryEndpoint,
      DaVinciEnv.clientId,
      DaVinciEnv.redirectUri,
    ],
    PingFlow.oidc => [
      OidcEnv.discoveryEndpoint,
      OidcEnv.clientId,
      OidcEnv.redirectUri,
    ],
  };

  /// `false` while any required value is empty or still a `<placeholder>`.
  bool get isConfigured => !requiredValues.any(isUnsetConfigValue);
}
