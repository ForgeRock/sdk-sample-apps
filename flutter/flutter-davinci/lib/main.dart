/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'package:flutter_davinci/data/davinci_repository.dart';
import 'package:flutter_davinci/routing/router.dart';
import 'package:flutter_davinci/ui/core/theme/app_theme.dart';
import 'package:flutter_davinci/ui/features/config/view_models/flow_settings_view_model.dart';
import 'package:flutter_davinci/ui/features/davinci/view_models/davinci_view_model.dart';
import 'package:flutter_davinci/ui/features/success/view_models/success_view_model.dart';

void main() {
  usePathUrlStrategy();
  runApp(const FlutterDaVinciApp());
}

class FlutterDaVinciApp extends StatelessWidget {
  const FlutterDaVinciApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (_) => DaVinciRepository(),
          dispose: (_, repo) => repo.dispose(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              DaVinciViewModel(repository: context.read<DaVinciRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              SuccessViewModel(repository: context.read<DaVinciRepository>()),
        ),
        ChangeNotifierProvider(create: (_) => FlowSettingsViewModel()..load()),
      ],
      child: MaterialApp.router(
        title: 'Flutter DaVinci',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}
