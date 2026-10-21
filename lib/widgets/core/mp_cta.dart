import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design_system/design_system.dart';
import 'mp_press.dart';

/// The full-width primary call to action: 54px, annatto, white bold label.
/// The trailing arrow marks a step forward in the flow; pass a leading
/// [icon] with [iconLeading] for an action that stays on the screen. A null
/// [onPressed] renders it disabled (hairline fill, faint text) so the screen
/// can hold the user until its inputs are complete.
class MpCta extends StatelessWidget {
  const MpCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = LucideIcons.arrowRight,
    this.iconLeading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool iconLeading;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final enabled = onPressed != null;
    final fg = enabled ? c.surface : c.faint;
    final glyph = Icon(icon, size: 19, color: fg);
    return MpPress(
      onTap: onPressed,
      child: Container(
        height: MpSize.cta,
        decoration: BoxDecoration(
          color: enabled ? c.annatto : c.hairline,
          borderRadius: BorderRadius.circular(MpRadius.button),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconLeading) ...[glyph, const SizedBox(width: 9)],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MpTypography.button().copyWith(color: fg),
              ),
            ),
            if (!iconLeading) ...[const SizedBox(width: 8), glyph],
          ],
        ),
      ),
    );
  }
}

/// The quiet full-width button: white, 1px outline, ink label. Used where
/// the primary annatto CTA would shout (closing a sheet).
class MpSecondaryButton extends StatelessWidget {
  const MpSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return MpPress(
      onTap: onPressed,
      autofocus: autofocus,
      focusRadius: MpRadius.input,
      child: Container(
        height: MpSize.sheetButton,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(MpRadius.input),
          border: Border.all(color: c.outline),
        ),
        child: Text(label, style: MpTypography.bodyBold().copyWith(color: c.ink)),
      ),
    );
  }
}

/// The small muted line under a CTA ("An estimate, not medical advice.").
class MpCtaNote extends StatelessWidget {
  const MpCtaNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 11),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: MpTypography.small().copyWith(color: context.mp.faint),
      ),
    );
  }
}
