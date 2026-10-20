import 'package:flutter/widgets.dart';

import '../../design_system/design_system.dart';

/// Tap target with the brand's press feedback: a gentle scale to
/// [MpMotion.pressScale] while the finger is down. Declares itself a button
/// to assistive tech; pass [semanticLabel] when the child has no text.
class MpPress extends StatefulWidget {
  const MpPress({
    super.key,
    required this.onTap,
    required this.child,
    this.semanticLabel,
    this.scale = MpMotion.pressScale,
  });

  final VoidCallback? onTap;
  final Widget child;
  final String? semanticLabel;
  final double scale;

  @override
  State<MpPress> createState() => _MpPressState();
}

class _MpPressState extends State<MpPress> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: MpMotion.of(context, MpMotion.press),
          child: widget.child,
        ),
      ),
    );
  }
}
