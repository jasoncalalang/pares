import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import 'mp_press.dart';

/// White card with the 1px hairline border. Flat; no shadow stacks.
class MpCard extends StatelessWidget {
  const MpCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(MpSpacing.lg),
    this.radius = MpRadius.card,
    this.color,
    this.borderColor,
    this.borderWidth = MpStroke.hairline,
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;

  /// The one soft shadow the grocery total card gets (`0 1px 3px 4%`).
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? c.hairline, width: borderWidth),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: c.ink.withValues(alpha: 0.04),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// The pill-shaped tinted chip ("2,087 kcal/day", "≤ ₱2,500").
class MpPill extends StatelessWidget {
  const MpPill({super.key, required this.label, required this.accent});

  final String label;
  final MpAccent accent;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: accent.tint(c),
        borderRadius: BorderRadius.circular(MpRadius.pill),
        border: Border.all(color: accent.tintBorder(c)),
      ),
      child: Text(
        label,
        style: MpTypography.smallBold().copyWith(color: accent.deep(c)),
      ),
    );
  }
}

/// Small outlined pill button with a leading icon ("Grocery list", "New").
class MpPillButton extends StatelessWidget {
  const MpPillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.accent,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  /// Colour the label and icon with this accent; muted when null.
  final MpAccent? accent;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final fg = accent?.main(c) ?? c.muted;
    return MpPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(MpRadius.pill),
          border: Border.all(color: c.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
            Text(label, style: MpTypography.smallBold().copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}

/// Rounded-square Fraunces monogram chip used for stores.
class MpMonogram extends StatelessWidget {
  const MpMonogram({
    super.key,
    required this.text,
    required this.accent,
    this.filled = false,
    this.size = MpSize.monogram,
  });

  final String text;
  final MpAccent accent;

  /// Solid accent background (selected tile) instead of the tint.
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return AnimatedContainer(
      duration: MpMotion.of(context, MpMotion.select),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? accent.main(c) : accent.tint(c),
        borderRadius: BorderRadius.circular(MpRadius.chip),
      ),
      child: Text(
        text,
        style: MpTypography.monogram().copyWith(
          color: filled ? c.surface : accent.deep(c),
          fontSize: text.length > 2 ? 12 : null,
        ),
      ),
    );
  }
}
