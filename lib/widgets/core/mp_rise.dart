import 'package:flutter/widgets.dart';

import '../../design_system/design_system.dart';

/// Entrance animation: the child fades in while rising [MpMotion.riseOffset]
/// over [MpMotion.rise], after an optional [delay] (siblings stagger by
/// [MpMotion.stagger]). The delay is folded into the one controller as an
/// [Interval], so there are no timers to leak. Under reduced motion the child
/// is simply shown.
class MpRise extends StatefulWidget {
  const MpRise({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<MpRise> createState() => _MpRiseState();
}

class _MpRiseState extends State<MpRise> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _t;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _t = _controller;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final rise = MpMotion.of(context, MpMotion.rise);
    final delay = MpMotion.of(context, widget.delay);
    final total = rise + delay;
    if (total == Duration.zero) {
      _controller.value = 1;
      return;
    }
    _controller.duration = total;
    final start = delay.inMicroseconds / total.inMicroseconds;
    _t = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: MpMotion.ease),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _t,
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, MpMotion.riseOffset * (1 - _t.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
