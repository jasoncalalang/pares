import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../core/mp_press.dart';

/// One option of a segmented choice (gender, activity, goal). Selected =
/// accent tint, 1.5px accent border, 3px halo and deep-accent bold text;
/// unselected = white, 1px outline, muted text. Transitions over
/// [MpMotion.select].
class MpChoiceButton extends StatelessWidget {
  const MpChoiceButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent = MpAccent.annatto,
    this.icon,
    this.height = MpSize.control,
    this.radius = MpRadius.input,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final MpAccent accent;
  final IconData? icon;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final fg = selected ? accent.deep(c) : c.muted;
    final style = selected ? MpTypography.chipSelected() : MpTypography.chip();
    return Semantics(
      inMutuallyExclusiveGroup: true,
      child: MpPress(
        onTap: onTap,
        selected: selected,
        focusRadius: radius,
        child: AnimatedContainer(
          duration: MpMotion.of(context, MpMotion.select),
          curve: MpMotion.ease,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? accent.tint(c) : c.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: selected ? accent.main(c) : c.outline,
              width: selected ? MpStroke.selected : MpStroke.hairline,
            ),
            boxShadow: [
              BoxShadow(
                color: selected ? c.halo(accent.main(c)) : Colors.transparent,
                spreadRadius: MpStroke.halo,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: fg),
                const SizedBox(width: 7),
              ],
              Text(label, style: style.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
