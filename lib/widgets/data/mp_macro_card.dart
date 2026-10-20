import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../core/mp_card.dart';

/// Protein / Carbs / Fat card: a small semicircular gauge in the macro's
/// accent that fills to [fraction] on load, the grams, then the label.
class MpMacroCard extends StatelessWidget {
  const MpMacroCard({
    super.key,
    required this.label,
    required this.grams,
    required this.fraction,
    required this.accent,
    this.delay = Duration.zero,
  });

  final String label;
  final int grams;

  /// 0–1 share of the gauge to fill.
  final double fraction;
  final MpAccent accent;

  /// Stagger offset so the three gauges fill one after another.
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final reveal = MpMotion.of(context, MpMotion.reveal);
    final delay = MpMotion.of(context, MpMotion.revealDelay + this.delay);
    final total = reveal + delay;
    return MpCard(
      radius: MpRadius.button,
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: total,
            curve: total == Duration.zero
                ? Curves.linear
                : Interval(
                    delay.inMicroseconds / total.inMicroseconds,
                    1,
                    curve: MpMotion.ease,
                  ),
            builder: (context, f, _) => CustomPaint(
              size: const Size(MpSize.gaugeWidth, MpSize.gaugeHeight),
              painter: _GaugePainter(
                fraction: f,
                track: accent.tint(c),
                fill: accent.main(c),
                stroke: MpSize.gaugeStroke,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('${grams}g', style: MpTypography.macroValue().copyWith(color: c.ink)),
          const SizedBox(height: 2),
          Text(
            label,
            style: MpTypography.smallStrong().copyWith(
              color: c.muted,
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.fraction,
    required this.track,
    required this.fill,
    required this.stroke,
  });

  final double fraction;
  final Color track;
  final Color fill;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    // Semicircle whose baseline sits 2px above the bottom edge, radius 22
    // at the mockup's 56×32.
    final radius = size.width / 2 - stroke;
    final center = Offset(size.width / 2, size.height - 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, base..color = track);
    if (fraction <= 0) return;
    canvas.drawArc(rect, math.pi, math.pi * fraction, false, base..color = fill);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction || old.fill != fill || old.track != track;
}

/// Horizontal progress bar (budget). Fills its width over [MpMotion.reveal].
class MpProgressBar extends StatelessWidget {
  const MpProgressBar({
    super.key,
    required this.fraction,
    required this.color,
    this.height = MpSize.bar,
  });

  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final reveal = MpMotion.of(context, MpMotion.reveal);
    final delay = MpMotion.of(context, const Duration(milliseconds: 250));
    final total = reveal + delay;
    return ClipRRect(
      borderRadius: BorderRadius.circular(MpRadius.pill),
      child: Container(
        height: height,
        color: c.track,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: fraction.clamp(0, 1).toDouble()),
          duration: total,
          curve: total == Duration.zero
              ? Curves.linear
              : Interval(
                  delay.inMicroseconds / total.inMicroseconds,
                  1,
                  curve: MpMotion.ease,
                ),
          builder: (context, f, _) => Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: f,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(MpRadius.pill),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
