/// Layout tokens (all logical pixels), pinned to the 390×844 mockups.
abstract final class MpSpacing {
  /// Horizontal page padding.
  static const double gutter = 22;

  /// Top page padding.
  static const double top = 24;

  /// Bottom page padding under the CTA.
  static const double bottom = 22;

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  /// Gap between grid tiles / segmented buttons.
  static const double tileGap = 10;

  /// Gap between stacked cards (meal cards, grocery rows).
  static const double cardGap = 11;
}

abstract final class MpRadius {
  static const double input = 13;
  static const double button = 15;
  static const double segment = 12;
  static const double card = 16;
  static const double cardLg = 18;
  static const double hero = 20;
  static const double tile = 14;
  static const double chip = 9;
  static const double thumb = 13;
  static const double iconBox = 10;
  static const double swap = 11;
  static const double checkbox = 7;
  static const double pill = 999;
}

abstract final class MpSize {
  /// Full-width primary CTA height.
  static const double cta = 54;

  /// Segmented toggle / standard control height.
  static const double control = 52;

  /// Activity / goal pill-button height.
  static const double pillButton = 48;

  /// Big-value input (age / height / weight) height.
  static const double bigInput = 64;

  /// Minimum tap target.
  static const double tap = 44;

  /// Store monogram chip.
  static const double monogram = 34;

  /// Meal-card photo thumbnail.
  static const double thumb = 54;

  /// Square swap button on a meal card (a full 44px tap target).
  static const double swap = 44;

  /// Round budget stepper button (a full 44px tap target).
  static const double stepper = 44;

  /// Grocery row ingredient icon box.
  static const double iconBox = 36;

  /// Grocery row checkbox.
  static const double checkbox = 22;

  /// Calorie ring diameter / stroke.
  static const double ring = 118;
  static const double ringStroke = 8;

  /// Macro gauge width / height / stroke.
  static const double gaugeWidth = 56;
  static const double gaugeHeight = 32;
  static const double gaugeStroke = 6;

  /// Onboarding progress segment height.
  static const double segment = 3;

  /// Budget progress bar height.
  static const double bar = 9;
}

abstract final class MpStroke {
  static const double hairline = 1;
  static const double selected = 1.5;
  static const double halo = 3;
  static const double icon = 2;
  static const double iconBold = 2.2;
}
