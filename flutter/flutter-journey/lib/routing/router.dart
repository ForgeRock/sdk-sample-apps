/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:flutter_journey/ui/features/config/views/config_view.dart';
import 'package:flutter_journey/ui/features/config/views/journey_name_view.dart';
import 'package:flutter_journey/ui/features/journey/view_models/journey_view_model.dart';
import 'package:flutter_journey/ui/features/journey/views/journey_view.dart';
import 'package:flutter_journey/ui/features/success/views/success_view.dart';

/// `/config` -> `/journey-name` -> `/journey` -> `/success`.
final GoRouter router = GoRouter(
  initialLocation: '/config',
  routes: [
    GoRoute(
      path: '/config',
      builder: (context, state) =>
          ConfigView(onContinue: () => context.go('/journey-name')),
    ),
    GoRoute(
      path: '/journey-name',
      builder: (context, state) => JourneyNameView(
        onSubmit: (name) async {
          await context.read<JourneyViewModel>().startJourney(name);
          if (context.mounted) context.go('/journey');
        },
      ),
    ),
    GoRoute(
      path: '/journey',
      builder: (context, state) => JourneyView(
        onSuccess: () => context.go('/success'),
        onRestart: () => context.go('/journey-name'),
      ),
    ),
    GoRoute(
      path: '/success',
      builder: (context, state) => SuccessView(
        onSignOff: () async {
          final viewModel = context.read<JourneyViewModel>();
          await viewModel.signOff();
          if (context.mounted) context.go('/journey-name');
        },
      ),
    ),
  ],
);
