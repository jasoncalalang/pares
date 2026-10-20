import 'package:flutter/material.dart';

import 'mp_colors.dart';
import 'mp_spacing.dart';
import 'mp_typography.dart';

/// Builds the Material theme for MealPal PH. Light only — the brand is a
/// warm cream page, not a dark tracker.
abstract final class MpTheme {
  static ThemeData light() {
    const c = MpColors.light;

    final textTheme = TextTheme(
      displayLarge: MpTypography.heroNumber().copyWith(color: c.ink),
      displayMedium: MpTypography.totalValue().copyWith(color: c.ink),
      headlineMedium: MpTypography.h1().copyWith(color: c.ink),
      titleMedium: MpTypography.rowTitle().copyWith(color: c.ink),
      bodyMedium: MpTypography.body().copyWith(color: c.ink),
      bodySmall: MpTypography.small().copyWith(color: c.faint),
      labelLarge: MpTypography.button(),
      labelMedium: MpTypography.label().copyWith(color: c.ink),
      labelSmall: MpTypography.eyebrow().copyWith(color: c.annatto),
    );

    final scheme = ColorScheme.light(
      primary: c.annatto,
      onPrimary: c.surface,
      secondary: c.green,
      onSecondary: c.surface,
      surface: c.surface,
      onSurface: c.ink,
      outline: c.hairline,
      error: c.annattoDeep,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.cream,
      canvasColor: c.cream,
      fontFamily: MpTypography.uiFamily,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: c.divider,
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MpRadius.card),
          side: BorderSide(color: c.hairline),
        ),
      ),
      extensions: const [c],
    );
  }
}
