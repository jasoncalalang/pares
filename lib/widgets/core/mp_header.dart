import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design_system/design_system.dart';
import 'mp_press.dart';

/// Thin 4-segment onboarding progress bar. Filled segments animate in from
/// the left, one after another.
class MpProgressSegments extends StatelessWidget {
  const MpProgressSegments({super.key, required this.step, this.of = 4});

  final int step;
  final int of;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return Semantics(
      label: 'Step $step of $of',
      child: Row(
        children: [
          for (var i = 0; i < of; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(MpRadius.pill),
                child: Container(
                  height: MpSize.segment,
                  color: c.track,
                  child: i < step ? _SegmentFill(index: i) : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SegmentFill extends StatelessWidget {
  const _SegmentFill({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final fill = MpMotion.of(context, MpMotion.segment);
    final delay = MpMotion.of(
      context,
      Duration(milliseconds: 150 + 140 * index),
    );
    final total = fill + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: total == Duration.zero
          ? Curves.linear
          : Interval(
              delay.inMicroseconds / total.inMicroseconds,
              1,
              curve: MpMotion.ease,
            ),
      builder: (context, t, _) => Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: t,
          child: Container(color: context.mp.annatto),
        ),
      ),
    );
  }
}

/// "MealPal PH" in Fraunces, PH in annatto.
class MpWordmark extends StatelessWidget {
  const MpWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final style = MpTypography.wordmark().copyWith(color: c.ink);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          const TextSpan(text: 'MealPal '),
          TextSpan(text: 'PH', style: style.copyWith(color: c.annatto)),
        ],
      ),
    );
  }
}

/// Eyebrow "STEP n OF m" on the left, wordmark on the right. The eyebrow
/// doubles as a back affordance when [onBack] is given.
class MpStepHeader extends StatelessWidget {
  const MpStepHeader({super.key, required this.step, this.of = 4, this.onBack});

  final int step;
  final int of;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final eyebrow = Text(
      'STEP $step OF $of',
      style: MpTypography.eyebrow().copyWith(color: c.annatto),
    );
    return _TapBand(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: onBack == null
                ? eyebrow
                : MpPress(
                    onTap: onBack,
                    semanticLabel: 'Back',
                    child: _TapBand(child: eyebrow),
                  ),
          ),
          const MpWordmark(),
        ],
      ),
    );
  }
}

/// Holds [child] in a band at least [MpSize.tap] tall, centred on its left,
/// so a one-line back link is a full tap target. Screens trim the spacing
/// round a header by the band's extra height, so the text stays put.
class _TapBand extends StatelessWidget {
  const _TapBand({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: MpSize.tap),
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: 1,
        heightFactor: 1,
        child: child,
      ),
    );
  }
}

/// "← THIS WEEK" style back link on the left, wordmark on the right.
class MpBackHeader extends StatelessWidget {
  const MpBackHeader({super.key, required this.label, required this.onBack});

  final String label;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: MpPress(
            onTap: onBack,
            child: _TapBand(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.arrowLeft, size: 16, color: c.annatto),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: MpTypography.eyebrow().copyWith(
                        color: c.annatto,
                        letterSpacing: 12 * 0.10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const MpWordmark(),
      ],
    );
  }
}

/// Fraunces H1 with the muted one-line subtitle beneath it.
class MpTitle extends StatelessWidget {
  const MpTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: MpTypography.h1().copyWith(color: c.ink)),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: MpTypography.body().copyWith(color: c.muted)),
        ],
      ],
    );
  }
}
