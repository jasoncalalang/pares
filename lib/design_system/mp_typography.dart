import 'package:flutter/material.dart';

/// Type tokens. Two faces, strictly divided: Fraunces (serif) for headings,
/// hero numbers, the wordmark and monograms; Plus Jakarta Sans for every
/// other piece of UI text.
///
/// Both ship as variable fonts, so each style sets the `wght` axis through
/// [TextStyle.fontVariations] as well as [TextStyle.fontWeight]: the latter
/// alone does not move a variable font's axis. Fraunces also gets an `opsz`
/// matched to its point size so small serif text keeps its ink traps.
abstract final class MpTypography {
  static const displayFamily = 'Fraunces';
  static const uiFamily = 'PlusJakartaSans';

  // ---- Fraunces ----

  static TextStyle wordmark() => _display(18, FontWeight.w600, height: 1.2);
  static TextStyle h1() => _display(28, FontWeight.w600, height: 1.1);
  static TextStyle heroNumber() => _display(50, FontWeight.w600, height: 1.0);
  static TextStyle ringNumber() => _display(30, FontWeight.w600, height: 1.0);
  static TextStyle totalValue() => _display(34, FontWeight.w600, height: 1.0);
  static TextStyle totalCap() => _display(17, FontWeight.w500, height: 1.0);
  static TextStyle budgetValue() => _display(26, FontWeight.w600, height: 1.1);
  static TextStyle monogram() => _display(16, FontWeight.w600, height: 1.0);

  // ---- Plus Jakarta Sans ----

  /// "STEP 1 OF 4": annatto, 0.12em tracking.
  static TextStyle eyebrow() => _ui(12, FontWeight.w700, tracking: 0.12);

  /// "WEEKLY BUDGET", "LOCAL TO THE PHILIPPINES": 0.08em tracking.
  static TextStyle sectionEyebrow() => _ui(12, FontWeight.w700, tracking: 0.08);

  /// Meal-card slot ("BREAKFAST").
  static TextStyle slotLabel() => _ui(11, FontWeight.w700, tracking: 0.08);

  /// "KCAL/DAY" inside the calorie ring.
  static TextStyle ringCaption() => _ui(10, FontWeight.w600, tracking: 0.08);

  static TextStyle body() => _ui(14, FontWeight.w400, height: 1.4);
  static TextStyle bodyStrong() => _ui(14, FontWeight.w600, height: 1.25);
  static TextStyle bodyBold() => _ui(14, FontWeight.w700, height: 1.25);
  static TextStyle label() => _ui(13, FontWeight.w600, height: 1.2);
  static TextStyle row() => _ui(13.5, FontWeight.w400, height: 1.2);
  static TextStyle rowTitle() => _ui(15, FontWeight.w700, height: 1.2);
  static TextStyle small() => _ui(12, FontWeight.w400, height: 1.4);
  static TextStyle smallStrong() => _ui(12, FontWeight.w600, height: 1.4);
  static TextStyle smallBold() => _ui(12, FontWeight.w700, height: 1.2);
  static TextStyle chip() => _ui(13, FontWeight.w600, height: 1.0);
  static TextStyle chipSelected() => _ui(13, FontWeight.w700, height: 1.0);
  static TextStyle button() => _ui(15, FontWeight.w700, height: 1.0);
  static TextStyle bigValue() => _ui(30, FontWeight.w700, height: 1.0);
  static TextStyle macroValue() => _ui(17, FontWeight.w700, height: 1.0);
  static TextStyle dayNumber() => _ui(14, FontWeight.w700, height: 1.0);
  static TextStyle dayName() => _ui(10, FontWeight.w700, tracking: 0.04);

  static TextStyle _display(double size, FontWeight weight, {double? height}) {
    return TextStyle(
      fontFamily: displayFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      fontVariations: [
        FontVariation.weight(weight.value.toDouble()),
        FontVariation.opticalSize(size.clamp(9, 144)),
      ],
    );
  }

  static TextStyle _ui(
    double size,
    FontWeight weight, {
    double? height,
    double tracking = 0,
  }) {
    return TextStyle(
      fontFamily: uiFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: tracking == 0 ? null : size * tracking,
      fontVariations: [FontVariation.weight(weight.value.toDouble())],
    );
  }
}
