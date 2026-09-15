/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:go_router/go_router.dart';

import 'package:flutter_oidc/ui/features/config/views/config_view.dart';
import 'package:flutter_oidc/ui/features/login/views/login_view.dart';
import 'package:flutter_oidc/ui/features/success/views/success_view.dart';

/// `/config` -> `/login` -> `/success`.
final GoRouter router = GoRouter(
  initialLocation: '/config',
  routes: [
    GoRoute(
      path: '/config',
      builder: (context, state) =>
          ConfigView(onContinue: () => context.go('/login')),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) =>
          LoginView(onSuccess: () => context.go('/success')),
    ),
    GoRoute(
      path: '/success',
      builder: (context, state) =>
          SuccessView(onSignOff: () => context.go('/login')),
    ),
  ],
);
