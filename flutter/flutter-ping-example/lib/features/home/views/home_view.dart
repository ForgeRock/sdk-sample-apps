/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ping_example/core/session/session_coordinator.dart';
import 'package:ping_example/core/theme/app_theme.dart';
import 'package:ping_example/core/widgets/brand_logo.dart';
import 'package:ping_example/core/widgets/error_banner.dart';
import 'package:ping_example/core/widgets/menu_row.dart';
import 'package:ping_example/features/environment/flow_configuration.dart';

/// The version of the native Ping SDKs the bridge pins (see the README).
const _nativeSdkVersion = '2.2.0';

/// Entry screen, laid out like the iOS PingExample: a branded hero, then a card of rows per
/// section. The active session, when there is one, gets a section of its own.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final coordinator = context.watch<SessionCoordinator>();
    final active = coordinator.active;
    final colors = AppTheme.colors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        // The hero is dark red in light appearance and pale pink in dark appearance.
        value: isDark ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hero(onEnvironments: () => context.go('/environment')),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingScreen,
                  AppTheme.spacingLarge,
                  AppTheme.spacingScreen,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      ErrorBanner(message: _error!),
                      const SizedBox(height: AppTheme.spacingLarge),
                    ],
                    if (active != null) ...[
                      const SectionTitle('Session'),
                      RowListCard(
                        rows: [
                          MenuRow(
                            icon: CupertinoIcons.ticket_fill,
                            title: 'Access Token',
                            subtitle: 'View the ${active.title} session',
                            onTap: () => context.go(active.successRoute),
                          ),
                          MenuRow(
                            icon: CupertinoIcons.square_arrow_right,
                            title: 'Logout',
                            subtitle: 'End the ${active.title} session',
                            onTap: _busy ? null : _signOff,
                            trailing: _busy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),
                    ],
                    const SectionTitle('Authentication'),
                    RowListCard(
                      rows: [
                        for (final flow in PingFlow.values)
                          MenuRow(
                            icon: flow.icon,
                            title: flow.menuTitle,
                            subtitle: flow.subtitle,
                            warning: flow.isConfigured
                                ? null
                                : 'Not configured',
                            trailing: flow == active
                                ? Icon(
                                    CupertinoIcons.checkmark_circle_fill,
                                    size: 18,
                                    color: colors.statusSuccess,
                                  )
                                : null,
                            onTap: _busy ? null : () => _open(flow),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                    const SectionTitle('Developer Tools'),
                    RowListCard(
                      rows: [
                        MenuRow(
                          icon: CupertinoIcons.gear_solid,
                          title: 'Environments',
                          subtitle: 'View configuration values',
                          onTap: () => context.go('/environment'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOff() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final signedOff = await context.read<SessionCoordinator>().signOffActive();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!signedOff) _error = 'Sign off failed. Try again.';
    });
  }

  Future<void> _showNotConfigured(PingFlow flow) async {
    final viewEnvironments = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${flow.title} isn't configured"),
        content: const Text(
          'Some of its required values are still placeholders. Open Environments to see '
          "which, then set them in the flow's Env class or pass them with "
          '--dart-define-from-file=.env.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('View Environments'),
          ),
        ],
      ),
    );
    if (viewEnvironments == true && mounted) context.go('/environment');
  }

  Future<void> _open(PingFlow flow) async {
    final coordinator = context.read<SessionCoordinator>();
    final active = coordinator.active;
    if (active == flow) {
      context.go(flow.successRoute);
      return;
    }
    if (!flow.isConfigured) {
      await _showNotConfigured(flow);
      return;
    }
    if (active == null) {
      context.go(flow.route);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign out of ${active.title}?'),
        content: Text(
          'The Ping SDKs keep tokens in one shared native store, so starting ${flow.title} '
          'signs you out of ${active.title} first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    final signedOff = await coordinator.signOffActive();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!signedOff) _error = 'Could not sign out of ${active.title}.';
    });
    if (signedOff) context.go(flow.route);
  }
}

/// A pill with the Flutter mark, saying this app is built with Flutter. It sits on a neutral
/// surface so the blue mark reads on both hero gradients.
class _FlutterBadge extends StatelessWidget {
  const _FlutterBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.colors(context).groupedSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FlutterLogo(size: 18),
          const SizedBox(width: AppTheme.spacingSmall),
          Text(
            'Built with Flutter',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The full-bleed branded header: gradient, logo, title, and the Environments button.
class _Hero extends StatelessWidget {
  const _Hero({required this.onEnvironments});

  final VoidCallback onEnvironments;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);
    final foreground = colors.actionPrimaryForeground;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.actionPrimary, colors.actionPrimaryPressed],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.spacingLarge,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLogo(size: 80),
                    const SizedBox(height: AppTheme.spacingMedium),
                    Text(
                      'Ping Example',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMedium),
                    Text(
                      'Native Ping SDK $_nativeSdkVersion',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: foreground.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMedium),
                    const _FlutterBadge(),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                child: IconButton(
                  tooltip: 'Environments',
                  onPressed: onEnvironments,
                  icon: Icon(
                    CupertinoIcons.gear_solid,
                    size: 24,
                    color: foreground.withValues(alpha: 0.9),
                  ),
                  style: IconButton.styleFrom(
                    fixedSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                      side: BorderSide(color: foreground.withValues(alpha: 0.4)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
