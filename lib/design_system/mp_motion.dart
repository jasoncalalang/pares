import 'package:flutter/widgets.dart';

/// Motion tokens. Motion only where it carries information or feedback:
/// data reveals, selection, press and layout changes. There is no page-load
/// entrance animation; screens are simply there. Nothing bouncy. Every consumer reads durations through
/// [MpMotion.of] so `MediaQuery.disableAnimations` (the platform
/// reduce-motion setting) collapses them to zero.
abstract final class MpMotion {
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
