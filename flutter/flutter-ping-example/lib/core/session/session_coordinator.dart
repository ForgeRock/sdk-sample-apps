/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

/// The three authentication flows this app demonstrates, in the order of the iOS PingExample menu.
/// Icons match its SF Symbols (`key.fill`, `map.fill`, `lock.shield.fill`); Cupertino has no key
/// glyph, so DaVinci uses Material's.
enum PingFlow {
  davinci(
    title: 'DaVinci',
    menuTitle: 'DaVinci Flow',
    subtitle: 'PingOne flow, rendered natively from collectors',
    icon: Icons.key,
    route: '/davinci/config',
    successRoute: '/davinci/success',
  ),
  journey(
    title: 'Journey',
    menuTitle: 'Journey Flow',
    subtitle: 'PingAM / AIC tree, rendered natively from callbacks',
    icon: CupertinoIcons.map_fill,
    route: '/journey/name',
    successRoute: '/journey/success',
  ),
  oidc(
    title: 'OIDC',
    menuTitle: 'OIDC (Web) Login',
    subtitle: 'Centralized login in the system browser',
    icon: CupertinoIcons.lock_shield_fill,
    route: '/oidc/login',
    successRoute: '/oidc/success',
  );

  const PingFlow({
    required this.title,
    required this.menuTitle,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.successRoute,
  });

  /// Short name, for sentences and headings.
  final String title;

  /// The label of the flow's row on Home.
  final String menuTitle;
  final String subtitle;
  final IconData icon;

  /// Where the flow starts.
  final String route;

  /// Where a signed-in user of this flow lands.
  final String successRoute;
}

/// Tracks which flow currently owns the signed-in session.
///
/// The native Ping SDKs store OIDC tokens in one default slot (on iOS, a single Keychain account),
/// and the bridge doesn't expose per-client storage. Journey, DaVinci and OIDC therefore overwrite
/// each other's tokens, so the app keeps one active session at a time and signs the current flow
/// off before another one starts.
class SessionCoordinator extends ChangeNotifier {
  PingFlow? _active;
  final Map<PingFlow, Future<bool> Function()> _signOffs = {};

  /// The flow that holds the signed-in session, or `null` when nobody is signed in.
  PingFlow? get active => _active;

  /// Registers how to sign [flow] off. Called once per flow when its view model is created.
  void registerSignOff(PingFlow flow, Future<bool> Function() signOff) {
    _signOffs[flow] = signOff;
  }

  void markSignedIn(PingFlow flow) {
    if (_active == flow) return;
    _active = flow;
    notifyListeners();
  }

  void markSignedOut(PingFlow flow) {
    if (_active != flow) return;
    _active = null;
    notifyListeners();
  }

  /// Signs the active flow off. Returns `true` when nothing was active or the sign-off succeeded.
  Future<bool> signOffActive() async {
    final flow = _active;
    if (flow == null) return true;
    final signedOff = await (_signOffs[flow]?.call() ?? Future.value(true));
    if (signedOff) markSignedOut(flow);
    return signedOff;
  }
}
