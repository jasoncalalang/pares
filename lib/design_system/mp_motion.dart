import 'package:flutter/widgets.dart';

/// Motion tokens. Purposeful and quiet: entrance rise, data reveal, selection
/// and press — nothing bouncy. Every consumer reads durations through
/// [MpMotion.of] so `MediaQuery.disableAnimations` (the platform
/// reduce-motion setting) collapses them to zero.
abstract final class MpMotion {
  /// Sections fade in and rise ~10px on load.
  static const Duration rise = Duration(milliseconds: 380);

  /// Delay between staggered siblings.
  static const Duration stagger = Duration(milliseconds: 50);

  /// Rise distance in logical pixels.
  static const double riseOffset = 10;

  /// Button / tile press feedback.
  static const Duration press = Duration(milliseconds: 120);
  static const double pressScale = 0.97;

  /// Selected-state colour / border transitions.
  static const Duration select = Duration(milliseconds: 250);

  /// Selected tile pop (scale 1 → 1.03).
  static const Duration pop = Duration(milliseconds: 400);
  static const double popScale = 1.03;

  /// Calorie arc draw, count-up, gauge and bar fills.
  static const Duration reveal = Duration(milliseconds: 850);
  static const Duration revealDelay = Duration(milliseconds: 350);

  /// Onboarding progress segment fill.
  static const Duration segment = Duration(milliseconds: 700);

  /// Day-strip highlight slide.
  static const Duration slide = Duration(milliseconds: 320);

  /// Grocery section expand / collapse.
  static const Duration expand = Duration(milliseconds: 350);

  /// `cubic-bezier(.2,.7,.3,1)` from the mockups.
  static const Curve ease = Cubic(0.2, 0.7, 0.3, 1);

  /// [duration], or [Duration.zero] when the platform asks for reduced motion.
  static Duration of(BuildContext context, Duration duration) {
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false
        ? Duration.zero
        : duration;
  }
}
