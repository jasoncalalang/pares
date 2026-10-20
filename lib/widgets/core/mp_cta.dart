import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design_system/design_system.dart';
import 'mp_press.dart';

/// The full-width primary call to action: 54px, annatto, white bold label
/// with a trailing arrow (or a leading [icon] when [iconLeading]).
class MpCta extends StatelessWidget {
  const MpCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = LucideIcons.arrowRight,
    this.iconLeading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final bool iconLeading;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final glyph = Icon(icon, size: 19, color: c.surface);
    return MpPress(
      onTap: onPressed,
      child: Container(
        height: MpSize.cta,
        decoration: BoxDecoration(
          color: c.annatto,
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
                style: MpTypography.button().copyWith(color: c.surface),
              ),
            ),
            if (!iconLeading) ...[const SizedBox(width: 8), glyph],
          ],
        ),
      ),
    );
  }
}

/// The small muted line under a CTA ("An estimate, not medical advice…").
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
