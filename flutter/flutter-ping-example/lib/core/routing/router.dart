/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ping_example/core/session/session_coordinator.dart';
import 'package:ping_example/features/davinci/ui/config/views/config_view.dart';
import 'package:ping_example/features/davinci/ui/davinci/view_models/davinci_view_model.dart';
import 'package:ping_example/features/davinci/ui/davinci/views/flow_view.dart';
import 'package:ping_example/features/davinci/ui/success/views/success_view.dart';
import 'package:ping_example/features/environment/views/environment_view.dart';
import 'package:ping_example/features/home/views/home_view.dart';
import 'package:ping_example/features/journey/ui/config/views/journey_name_view.dart';
import 'package:ping_example/features/journey/ui/journey/view_models/journey_view_model.dart';
import 'package:ping_example/features/journey/ui/journey/views/journey_view.dart';
import 'package:ping_example/features/journey/ui/success/views/success_view.dart';
import 'package:ping_example/features/oidc/ui/login/views/login_view.dart';
import 'package:ping_example/features/oidc/ui/success/views/success_view.dart';

/// `/` (Home) with each flow nested under it, so a flow screen's back arrow returns Home:
///
/// - `/journey/name` -> `/journey/run` -> `/journey/success`
/// - `/davinci/config` (ACR values) -> `/davinci/run` -> `/davinci/success`
/// - `/oidc/login` -> `/oidc/success`
/// - `/environment`: every flow's configuration, read-only
///
/// Reaching a success screen marks the flow as the app's active session; signing off clears it.
final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeView(),
      routes: [
        GoRoute(
          path: 'environment',
          builder: (context, state) => const EnvironmentView(),
        ),
        GoRoute(
          path: 'journey/name',
          builder: (context, state) => JourneyNameView(
            onSubmit: (name) async {
              await context.read<JourneyViewModel>().startJourney(name);
              if (context.mounted) context.go('/journey/run');
            },
          ),
        ),
        GoRoute(
          path: 'journey/run',
          builder: (context, state) => JourneyView(
            onSuccess: () {
              context.read<SessionCoordinator>().markSignedIn(PingFlow.journey);
              context.go('/journey/success');
            },
            onRestart: () => context.go('/journey/name'),
          ),
        ),
        GoRoute(
          path: 'journey/success',
          builder: (context, state) => JourneySuccessView(
            onSignOff: () async {
              final coordinator = context.read<SessionCoordinator>();
              if (await context.read<JourneyViewModel>().signOff()) {
                coordinator.markSignedOut(PingFlow.journey);
              }
              if (context.mounted) context.go('/');
            },
          ),
        ),
        GoRoute(
          path: 'davinci/config',
          builder: (context, state) => DaVinciConfigView(
            onStart: (acrValues) async {
              await context.read<DaVinciViewModel>().start(acrValues);
              if (context.mounted) context.go('/davinci/run');
            },
          ),
        ),
        GoRoute(
          path: 'davinci/run',
          builder: (context, state) => FlowView(
            onSuccess: () {
              context.read<SessionCoordinator>().markSignedIn(PingFlow.davinci);
              context.go('/davinci/success');
            },
            onRestart: () => context.go('/davinci/config'),
          ),
        ),
        GoRoute(
          path: 'davinci/success',
          builder: (context, state) => DaVinciSuccessView(
            onSignOff: () async {
              final coordinator = context.read<SessionCoordinator>();
              if (await context.read<DaVinciViewModel>().signOff()) {
                coordinator.markSignedOut(PingFlow.davinci);
              }
              if (context.mounted) context.go('/');
            },
          ),
        ),
        GoRoute(
          path: 'oidc/login',
          builder: (context, state) => LoginView(
            onSuccess: () {
              context.read<SessionCoordinator>().markSignedIn(PingFlow.oidc);
              context.go('/oidc/success');
            },
          ),
        ),
        GoRoute(
          path: 'oidc/success',
          builder: (context, state) => OidcSuccessView(
            // The view has already signed off through `OidcViewModel` by the time this runs.
            onSignOff: () {
              context.read<SessionCoordinator>().markSignedOut(PingFlow.oidc);
              context.go('/');
            },
          ),
        ),
      ],
    ),
  ],
);
