/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ping_example/core/routing/router.dart';
import 'package:ping_example/core/session/session_coordinator.dart';
import 'package:ping_example/core/theme/app_theme.dart';
import 'package:ping_example/features/davinci/data/davinci_repository.dart';
import 'package:ping_example/features/davinci/ui/config/view_models/flow_settings_view_model.dart';
import 'package:ping_example/features/davinci/ui/davinci/view_models/davinci_view_model.dart';
import 'package:ping_example/features/davinci/ui/success/view_models/success_view_model.dart';
import 'package:ping_example/features/journey/data/journey_repository.dart';
import 'package:ping_example/features/journey/ui/config/view_models/journey_name_view_model.dart';
import 'package:ping_example/features/journey/ui/journey/view_models/journey_view_model.dart';
import 'package:ping_example/features/journey/ui/success/view_models/success_view_model.dart';
import 'package:ping_example/features/oidc/data/oidc_repository.dart';
import 'package:ping_example/features/oidc/ui/oidc/view_models/oidc_view_model.dart';

void main() {
  runApp(const PingExampleApp());
}

class PingExampleApp extends StatelessWidget {
  const PingExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionCoordinator()),

        // Journey
        Provider(
          create: (_) => JourneyRepository(),
          dispose: (_, repo) => repo.dispose(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) {
            final viewModel = JourneyViewModel(
              repository: context.read<JourneyRepository>(),
            );
            context.read<SessionCoordinator>().registerSignOff(
              PingFlow.journey,
              viewModel.signOff,
            );
            return viewModel;
          },
        ),
        ChangeNotifierProvider(
          create: (context) => JourneySuccessViewModel(
            repository: context.read<JourneyRepository>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => JourneyNameViewModel()..load()),

        // DaVinci
        Provider(
          create: (_) => DaVinciRepository(),
          dispose: (_, repo) => repo.dispose(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) {
            final viewModel = DaVinciViewModel(
              repository: context.read<DaVinciRepository>(),
            );
            context.read<SessionCoordinator>().registerSignOff(
              PingFlow.davinci,
              viewModel.signOff,
            );
            return viewModel;
          },
        ),
        ChangeNotifierProvider(
          create: (context) => DaVinciSuccessViewModel(
            repository: context.read<DaVinciRepository>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => FlowSettingsViewModel()..load()),

        // OIDC
        Provider(
          create: (_) => OidcRepository(),
          dispose: (_, repo) => repo.dispose(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) {
            final viewModel = OidcViewModel(
              repository: context.read<OidcRepository>(),
            );
            context.read<SessionCoordinator>().registerSignOff(
              PingFlow.oidc,
              viewModel.signOff,
            );
            return viewModel;
          },
        ),
      ],
      child: MaterialApp.router(
        title: 'Ping Example',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}
