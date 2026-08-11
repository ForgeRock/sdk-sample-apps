/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'package:flutter_journey/data/journey_repository.dart';
import 'package:flutter_journey/routing/router.dart';
import 'package:flutter_journey/ui/core/theme/app_theme.dart';
import 'package:flutter_journey/ui/features/config/view_models/journey_name_view_model.dart';
import 'package:flutter_journey/ui/features/journey/view_models/journey_view_model.dart';
import 'package:flutter_journey/ui/features/success/view_models/success_view_model.dart';

void main() {
  usePathUrlStrategy();
  runApp(const FlutterJourneyApp());
}

class FlutterJourneyApp extends StatelessWidget {
  const FlutterJourneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (_) => JourneyRepository(),
          dispose: (_, repo) => repo.dispose(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              JourneyViewModel(repository: context.read<JourneyRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              SuccessViewModel(repository: context.read<JourneyRepository>()),
        ),
        ChangeNotifierProvider(create: (_) => JourneyNameViewModel()..load()),
      ],
      child: MaterialApp.router(
        title: 'Flutter Journey',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}
