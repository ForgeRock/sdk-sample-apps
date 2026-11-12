/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';

/// Semantic colors, mirroring `PingTheme.Color` in the iOS PingDesignSystem package. Read them with
/// [AppTheme.colors] rather than hard-coding a color, so both appearances stay correct.
@immutable
class PingColors extends ThemeExtension<PingColors> {
  const PingColors({
    required this.appBackground,
    required this.groupedSurface,
    required this.inputSurface,
    required this.actionPrimary,
    required this.actionPrimaryForeground,
    required this.actionPrimaryPressed,
    required this.actionDisabled,
    required this.contentSecondary,
    required this.contentTertiary,
    required this.separator,
    required this.statusError,
    required this.statusWarning,
    required this.statusSuccess,
    required this.statusInfo,
  });

  /// The grouped background of a full screen.
  final Color appBackground;

  /// The elevated surface of cards and rows.
  final Color groupedSurface;

  /// The fill behind editable text controls.
  final Color inputSurface;

  /// The main action surface, and the tint of icons and accents.
  final Color actionPrimary;

  /// The foreground placed on [actionPrimary].
  final Color actionPrimaryForeground;

  /// The pressed state of [actionPrimary], and the end of the hero gradient.
  final Color actionPrimaryPressed;

  /// The surface of a disabled action.
  final Color actionDisabled;

  final Color contentSecondary;
  final Color contentTertiary;
  final Color separator;
  final Color statusError;
  final Color statusWarning;
  final Color statusSuccess;
  final Color statusInfo;

  /// iOS system colors plus the fixed Ping action colors (`#A31300`, paired for dark appearance).
  static const light = PingColors(
    appBackground: Color(0xFFF2F2F7),
    groupedSurface: Color(0xFFFFFFFF),
    inputSurface: Color(0xFFFFFFFF),
    actionPrimary: Color(0xFFA31300),
    actionPrimaryForeground: Color(0xFFFFFFFF),
    actionPrimaryPressed: Color(0xFF7D0F00),
    actionDisabled: Color(0x1F767680),
    contentSecondary: Color(0x993C3C43),
    contentTertiary: Color(0x4D3C3C43),
    separator: Color(0x4A3C3C43),
    statusError: Color(0xFFFF3B30),
    statusWarning: Color(0xFFFF9500),
    statusSuccess: Color(0xFF34C759),
    statusInfo: Color(0xFF007AFF),
  );

  static const dark = PingColors(
    appBackground: Color(0xFF000000),
    groupedSurface: Color(0xFF1C1C1E),
    inputSurface: Color(0xFF1C1C1E),
    actionPrimary: Color(0xFFFFB4A8),
    actionPrimaryForeground: Color(0xFF3A0700),
    actionPrimaryPressed: Color(0xFFFFDAD4),
    actionDisabled: Color(0x3D767680),
    contentSecondary: Color(0x99EBEBF5),
    contentTertiary: Color(0x4DEBEBF5),
    separator: Color(0xA6545458),
    statusError: Color(0xFFFF453A),
    statusWarning: Color(0xFFFF9F0A),
    statusSuccess: Color(0xFF30D158),
    statusInfo: Color(0xFF0A84FF),
  );

  @override
  PingColors copyWith() => this;

  @override
  PingColors lerp(ThemeExtension<PingColors>? other, double t) =>
      t < 0.5 ? this : (other as PingColors? ?? this);
}

/// Spacing, shape and control tokens, and the [ThemeData], mirroring the iOS `PingTheme`.
abstract final class AppTheme {
  static const double spacingXXSmall = 2;
  static const double spacingXSmall = 4;
  static const double spacingSmall = 8;
  static const double spacingCompact = 12;
  static const double spacingMedium = 16;
  static const double spacingLarge = 20;

  /// Edge inset of a screen.
  static const double spacingScreen = 20;

  static const double cardRadius = 12;
  static const double fieldRadius = 8;
  static const double tileRadius = 10;
  static const double buttonRadius = 12;

  /// Minimum height of a tappable action.
  static const double controlHeight = 50;

  /// The semantic colors of the current theme, falling back to the matching palette under a theme
  /// that doesn't carry them (a bare `MaterialApp`, for instance).
  static PingColors colors(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<PingColors>() ??
        (theme.brightness == Brightness.dark ? PingColors.dark : PingColors.light);
  }

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// Small uppercase-style heading above a group (the callers upper-case the text).
  static TextStyle sectionHeader(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: colors(context).contentSecondary,
    );
  }

  static ThemeData light() => _base(Brightness.light, PingColors.light);

  static ThemeData dark() => _base(Brightness.dark, PingColors.dark);

  static ThemeData _base(Brightness brightness, PingColors c) {
    final isLight = brightness == Brightness.light;
    final label = isLight ? Colors.black : Colors.white;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: PingColors.light.actionPrimary,
          brightness: brightness,
        ).copyWith(
          primary: c.actionPrimary,
          onPrimary: c.actionPrimaryForeground,
          surface: c.appBackground,
          onSurface: label,
          onSurfaceVariant: c.contentSecondary,
          outline: c.separator,
          outlineVariant: c.separator,
          error: c.statusError,
          onError: Colors.white,
          errorContainer: Color.alphaBlend(
            c.statusError.withValues(alpha: 0.12),
            c.groupedSurface,
          ),
          onErrorContainer: label,
          surfaceContainerHigh: c.groupedSurface,
          surfaceContainerHighest: c.groupedSurface,
        );

    // iOS text roles and their tracking: screen title 22, headline 17, subheadline 15, footnote 13,
    // caption 12. Material's default letter spacing is wider than SF's, so it is set explicitly.
    final base = ThemeData(brightness: brightness).textTheme;
    final textTheme = base.copyWith(
      titleLarge: base.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.35),
      titleMedium: base.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.41),
      titleSmall: base.titleSmall?.copyWith(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.24),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 17, letterSpacing: -0.41),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 15, letterSpacing: -0.24),
      bodySmall: base.bodySmall?.copyWith(fontSize: 13, letterSpacing: -0.08),
      labelLarge: base.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.24),
      labelMedium: base.labelMedium?.copyWith(fontSize: 12, letterSpacing: 0),
      labelSmall: base.labelSmall?.copyWith(fontSize: 11, letterSpacing: 0.07),
    );

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(color: color, width: width),
        );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [c],
      textTheme: textTheme,
      scaffoldBackgroundColor: c.appBackground,
      dividerTheme: DividerThemeData(color: c.separator, thickness: 0.5, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.inputSurface,
        contentPadding: const EdgeInsets.all(14),
        border: border(c.separator),
        enabledBorder: border(c.separator),
        focusedBorder: border(c.actionPrimary, 2),
        errorBorder: border(c.statusError),
        focusedErrorBorder: border(c.statusError, 2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(controlHeight)),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(textTheme.titleMedium),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? c.actionDisabled
                : states.contains(WidgetState.pressed)
                ? c.actionPrimaryPressed
                : c.actionPrimary,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? c.contentSecondary
                : c.actionPrimaryForeground,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(controlHeight)),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(textTheme.titleMedium),
          backgroundColor: WidgetStatePropertyAll(c.groupedSurface),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? c.contentSecondary
                : c.actionPrimary,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? c.separator
                  : c.actionPrimary,
            ),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: c.groupedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.groupedSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.appBackground,
        foregroundColor: label,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.actionPrimary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.actionPrimary.withValues(alpha: 0.5)
              : null,
        ),
      ),
    );
  }
}
