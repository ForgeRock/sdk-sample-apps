/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';

import 'package:ping_example/core/theme/app_theme.dart';

/// An icon on a filled rounded tile, the leading mark of a menu row (`PingIconTile` on iOS).
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 40,
    this.iconSize = 20,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.actionPrimary,
        borderRadius: BorderRadius.circular(AppTheme.tileRadius),
      ),
      child: Icon(icon, size: iconSize, color: colors.actionPrimaryForeground),
    );
  }
}
