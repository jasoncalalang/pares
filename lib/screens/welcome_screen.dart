import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design_system/design_system.dart';
import '../mealpal_ph.dart';
import '../widgets/widgets.dart';

/// The first screen: the job in one line over a collage of the example day's
/// plates, one primary action that needs no account, and the sign-in row for
/// people coming back.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.exampleDay, required this.onStart});

  /// The day whose plates fill the collage and whose numbers the stickers
  /// quote. Only meals with a photo are shown, at most four.
  final DayPlan exampleDay;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final plates = [
      for (final m in exampleDay.meals)
        if (m.image != null) m,
    ].take(4).toList();
    void signIn() => showSignInSheet(context);
    return MpPage(
      content: [
        const Align(alignment: Alignment.centerLeft, child: MpWordmark()),
        const SizedBox(height: 18),
        _Collage(plates: plates, dayKcal: exampleDay.kcal),
        const SizedBox(height: 20),
        Text(
          'Filipino meals that fit your calorie goal and your weekly budget.',
          style: MpTypography.display().copyWith(color: c.ink),
        ),
        const SizedBox(height: 10),
        Text(
          'Your stats become a daily target. Your target becomes a week of '
          'real meals from the stores near you, with the grocery list to '
          'match.',
          style: MpTypography.body().copyWith(color: c.muted, height: 1.45),
        ),
      ],
      footer: Column(
        children: [
          MpCta(label: 'Find my calorie target', onPressed: onStart),
          const SizedBox(height: MpSpacing.lg),
          const _OrDivider(),
          const SizedBox(height: MpSpacing.lg),
          // TODO(auth): wire Google, Apple and email sign-in once accounts
          // exist. Until then each opens a sheet that says so.
          Row(
            children: [
              Expanded(
                child: _ProviderButton(
                  label: 'Continue with Google',
                  onTap: signIn,
                  child: const MpBrandMark(MpBrand.google),
                ),
              ),
              const SizedBox(width: MpSpacing.tileGap),
              Expanded(
                child: _ProviderButton(
                  label: 'Continue with Apple',
                  dark: true,
                  onTap: signIn,
                  child: MpBrandMark(MpBrand.apple, size: 20, color: c.cream),
                ),
              ),
              const SizedBox(width: MpSpacing.tileGap),
              Expanded(
                child: _ProviderButton(
                  label: 'Continue with email',
                  onTap: signIn,
                  child: Icon(LucideIcons.mail, size: 21, color: c.ink),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Opens the bottom sheet the provider buttons lead to. It closes on Close,
/// on the scrim, on Escape and on the system back gesture.
Future<void> showSignInSheet(BuildContext context) {
  final c = context.mp;
  final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.surface,
    barrierColor: c.ink.withValues(alpha: 0.34),
    barrierLabel: 'Close sign-in',
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(MpRadius.hero)),
    ),
    sheetAnimationStyle: still
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: MpMotion.slide,
            reverseDuration: MpMotion.select,
          ),
    builder: (context) => const _SignInSheet(),
  );
}

class _SignInSheet extends StatelessWidget {
  const _SignInSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('Sign in', style: MpTypography.sheetTitle().copyWith(color: c.ink)),
            ),
            const SizedBox(height: MpSpacing.sm),
            Text(
              'Sign-in arrives with accounts. For now your plan stays on this '
              'device, and no account is needed.',
              style: MpTypography.body().copyWith(color: c.muted, height: 1.45),
            ),
            const SizedBox(height: 18),
            MpSecondaryButton(
              label: 'Close',
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Four plates at a slight tilt, as if set down on a table, with kcal and ₱
/// stickers quoting the example day. Drawn at the mockup's 346x280 and
/// scaled down on narrower phones.
class _Collage extends StatelessWidget {
  const _Collage({required this.plates, required this.dayKcal});

  final List<PlannedMeal> plates;
  final int dayKcal;

  static const _width = 346.0;
  static const _height = 280.0;

  /// left, top, right, bottom (one of each pair is null), size, tilt in
  /// degrees, and paint order (higher draws on top).
  static const _slots = [
    (left: 8.0, top: 6.0, right: null, bottom: null, size: 150.0, tilt: -4.0, z: 2),
    (left: null, top: 0.0, right: 6.0, bottom: null, size: 152.0, tilt: 3.0, z: 1),
    (left: 18.0, top: null, right: null, bottom: 0.0, size: 148.0, tilt: 2.0, z: 1),
    (left: null, top: null, right: 16.0, bottom: 4.0, size: 150.0, tilt: -3.0, z: 2),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final placed = [
      for (var i = 0; i < plates.length && i < _slots.length; i++) (plates[i], _slots[i]),
    ]..sort((a, b) => a.$2.z.compareTo(b.$2.z));
    final lead = plates.isEmpty ? null : plates.first;
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: _width,
          height: _height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final (meal, slot) in placed)
                Positioned(
                  left: slot.left,
                  top: slot.top,
                  right: slot.right,
                  bottom: slot.bottom,
                  child: Transform.rotate(
                    angle: slot.tilt * math.pi / 180,
                    child: _Plate(meal: meal, size: slot.size),
                  ),
                ),
              if (lead != null) ...[
                Positioned(
                  left: 0,
                  top: 118,
                  child: _Sticker('${formatThousands(lead.kcal)} kcal', color: c.annatto),
                ),
                Positioned(
                  right: 0,
                  top: 138,
                  child: _Sticker(formatPeso(lead.pricePhp, decimals: 0), color: c.green),
                ),
              ],
              Positioned(
                left: 0,
                right: 0,
                bottom: -6,
                child: Center(
                  child: _Sticker('${formatThousands(dayKcal)} kcal / day', color: c.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate({required this.meal, required this.size});

  final PlannedMeal meal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final radius = BorderRadius.circular(MpRadius.hero);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: c.hairline),
        boxShadow: MpElevation.plate(c),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          'assets/images/meals/${meal.image}.jpg',
          fit: BoxFit.cover,
          semanticLabel: meal.name,
        ),
      ),
    );
  }
}

class _Sticker extends StatelessWidget {
  const _Sticker(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MpRadius.pill),
        border: Border.all(color: c.hairline),
        boxShadow: MpElevation.sticker(c),
      ),
      child: Text(text, style: MpTypography.smallBold().copyWith(color: color)),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final rule = Expanded(child: Container(height: MpStroke.hairline, color: c.hairline));
    return Row(
      children: [
        rule,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MpSpacing.md),
          child: Text(
            'or continue with',
            style: MpTypography.small().copyWith(
              color: c.faint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        rule,
      ],
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.onTap,
    required this.child,
    this.dark = false,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  /// Ink fill (the Apple button); otherwise white with the control outline.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return MpPress(
      onTap: onTap,
      semanticLabel: label,
      focusRadius: MpRadius.input,
      child: Container(
        height: MpSize.control,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: dark ? c.ink : c.surface,
          borderRadius: BorderRadius.circular(MpRadius.input),
          border: Border.all(color: dark ? c.ink : c.outline),
        ),
        child: child,
      ),
    );
  }
}
