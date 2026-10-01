/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'package:flutter_oidc/data/oidc_repository.dart';
import 'package:flutter_oidc/routing/router.dart';
import 'package:flutter_oidc/ui/core/theme/app_theme.dart';
import 'package:flutter_oidc/ui/features/oidc/view_models/oidc_view_model.dart';

void main() {
  usePathUrlStrategy();
  runApp(const FlutterOidcApp());
}

class FlutterOidcApp extends StatelessWidget {
  const FlutterOidcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (_) => OidcRepository(),
          dispose: (_, repo) => repo.dispose(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              OidcViewModel(repository: context.read<OidcRepository>()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Flutter OIDC',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}
