/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import 'package:ping_example/core/theme/app_theme.dart';
import 'package:ping_example/core/widgets/icon_tile.dart';

/// A small uppercase heading above a [RowListCard].
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.spacingMedium,
        bottom: AppTheme.spacingSmall,
      ),
      child: Text(title.toUpperCase(), style: AppTheme.sectionHeader(context)),
    );
  }
}

/// A card of [MenuRow]s separated by dividers inset past the icon tile.
class RowListCard extends StatelessWidget {
  const RowListCard({super.key, required this.rows});

  final List<Widget> rows;

  /// Aligns a divider with the row text: tile width plus the gap after it.
  static const double _dividerInset = 40 + AppTheme.spacingMedium;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: AppTheme.colors(context).groupedSurface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              const Divider(indent: _dividerInset),
          ],
        ],
      ),
    );
  }
}

/// A tappable row: icon tile, title and subtitle, an optional trailing mark, and a chevron.
class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.warning,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  /// A line in the error color under [subtitle], for a row that needs attention.
  final String? warning;

  /// Shown before the chevron, e.g. a signed-in checkmark.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppTheme.colors(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSmall),
        child: Row(
          children: [
            IconTile(icon: icon),
            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXXSmall),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.contentSecondary,
                    ),
                  ),
                  if (warning != null) ...[
                    const SizedBox(height: AppTheme.spacingXXSmall),
                    Text(
                      warning!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.statusError,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: AppTheme.spacingSmall),
            ],
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: colors.contentSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
