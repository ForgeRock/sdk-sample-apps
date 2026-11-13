/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:flutter_davinci/ui/features/config/views/config_view.dart';
import 'package:flutter_davinci/ui/features/davinci/view_models/davinci_view_model.dart';
import 'package:flutter_davinci/ui/features/davinci/views/flow_view.dart';
import 'package:flutter_davinci/ui/features/success/views/success_view.dart';

/// `/config` -> `/flow` -> `/success`.
final GoRouter router = GoRouter(
  initialLocation: '/config',
  routes: [
    GoRoute(
      path: '/config',
      builder: (context, state) => ConfigView(
        onStart: (acrValues) async {
          await context.read<DaVinciViewModel>().start(acrValues);
          if (context.mounted) context.go('/flow');
        },
      ),
    ),
    GoRoute(
      path: '/flow',
      builder: (context, state) => FlowView(
        onSuccess: () => context.go('/success'),
        onRestart: () => context.go('/config'),
      ),
    ),
    GoRoute(
      path: '/success',
      builder: (context, state) => SuccessView(
        onSignOff: () async {
          await context.read<DaVinciViewModel>().signOff();
          if (context.mounted) context.go('/config');
        },
      ),
    ),
  ],
);
