import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../mealpal_ph.dart';

/// 118px calorie ring for the dark hero card: an annatto arc draws from
/// zero to [fraction] while the number inside counts up to [value]. Replays
/// whenever either changes (goal switch). Under reduced motion it shows the
/// final state at once.
class MpCalorieRing extends StatefulWidget {
  const MpCalorieRing({
    super.key,
    required this.value,
    required this.fraction,
    this.size = MpSize.ring,
  });

  final int value;

  /// 0 to 1 share of the ring to fill.
  final double fraction;
  final double size;

  @override
  State<MpCalorieRing> createState() => _MpCalorieRingState();
}

class _MpCalorieRingState extends State<MpCalorieRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this);
  late Animation<double> _t = _controller;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _play(withDelay: true);
  }

  @override
  void didUpdateWidget(MpCalorieRing old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value || old.fraction != widget.fraction) {
      _play(withDelay: false);
    }
  }

  void _play({required bool withDelay}) {
    final reveal = MpMotion.of(context, MpMotion.reveal);
    final delay = withDelay
        ? MpMotion.of(context, MpMotion.revealDelay)
        : Duration.zero;
    final total = reveal + delay;
    if (total == Duration.zero) {
      _t = _controller;
      _controller.value = 1;
      return;
    }
    _controller.duration = total;
    _t = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: MpMotion.ease,
      ),
    );
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final t = _t.value;
          return CustomPaint(
            painter: _RingPainter(
              fraction: widget.fraction * t,
              track: c.heroTrack,
              arc: c.annatto,
              stroke: MpSize.ringStroke,
            ),
            // Inside the stroke, shrinking at large text sizes.
            child: Padding(
              padding: const EdgeInsets.all(MpSize.ringStroke),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatThousands((widget.value * t).round()),
                      style: MpTypography.ringNumber().copyWith(color: c.heroText),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'KCAL/DAY',
                      style:
                          MpTypography.ringCaption().copyWith(color: c.heroMuted),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fraction,
    required this.track,
    required this.arc,
    required this.stroke,
  });

  final double fraction;
  final Color track;
  final Color arc;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(
      r,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (fraction <= 0) return;
    canvas.drawArc(
      r,
      -math.pi / 2,
      math.pi * 2 * fraction,
      false,
      Paint()
        ..color = arc
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.arc != arc || old.track != track;
}
