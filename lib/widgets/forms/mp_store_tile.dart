import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design_system/design_system.dart';
import '../core/mp_card.dart';
import '../core/mp_press.dart';

/// Selectable store tile: monogram chip + name. Selected tiles take the
/// accent ring, tint and halo, pop to 1.03× and grow a check badge on the
/// top-right corner. Annatto for chains, green for local stores.
class MpStoreTile extends StatelessWidget {
  const MpStoreTile({
    super.key,
    required this.name,
    required this.monogram,
    required this.selected,
    required this.onTap,
    this.local = false,
    this.nameScale = 1,
  });

  final String name;
  final String monogram;
  final bool selected;
  final VoidCallback onTap;
  final bool local;

  /// Shrinks the name so its longest word fits the tile (see [fit]).
  final double nameScale;

  static const double _padX = 14;
  static const double _gap = 11;

  /// Everything across a tile that is not its name.
  static const double _chrome =
      _padX * 2 + MpStroke.selected * 2 + MpSize.monogram + _gap;

  /// The least a name may shrink to keep two tiles a row.
  static const double minNameScale = 0.8;

  /// How a grid [width] wide lays out tiles for [names] at the current text
  /// size so no word breaks mid-word: two a row as they are; two a row with
  /// every name shrunk alike by up to [minNameScale]; or one a row.
  static ({int columns, double nameScale}) fit(
    BuildContext context, {
    required Iterable<String> names,
    required double width,
    double gap = MpSpacing.tileGap,
  }) {
    final scaler = MediaQuery.textScalerOf(context);
    var widest = 0.0;
    for (final word in names.expand((n) => n.split(' '))) {
      // Bold, the selected weight, is the wider of the two.
      final painter = TextPainter(
        text: TextSpan(text: word, style: MpTypography.bodyBold()),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    final room = (width - gap) / 2 - _chrome;
    if (widest <= room) return (columns: 2, nameScale: 1.0);
    // A hair under the exact ratio, so rounding never breaks the word.
    final shrink = room / widest * 0.98;
    if (shrink >= minNameScale) return (columns: 2, nameScale: shrink);
    return (columns: 1, nameScale: 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final accent = local ? MpAccent.green : MpAccent.annatto;
    final select = MpMotion.of(context, MpMotion.select);
    return MpPress(
      onTap: onTap,
      selected: selected,
      focusRadius: MpRadius.tile,
      child: AnimatedScale(
        scale: selected ? MpMotion.popScale : 1,
        duration: MpMotion.of(context, MpMotion.pop),
        curve: MpMotion.ease,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: select,
              curve: MpMotion.ease,
              padding: const EdgeInsets.symmetric(horizontal: _padX, vertical: 13),
              decoration: BoxDecoration(
                color: selected ? accent.tint(c) : c.surface,
                borderRadius: BorderRadius.circular(MpRadius.tile),
                border: Border.all(
                  color: selected ? accent.main(c) : c.outline,
                  width: selected ? MpStroke.selected : MpStroke.hairline,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? c.halo(accent.main(c))
                        : Colors.transparent,
                    spreadRadius: MpStroke.halo,
                  ),
                ],
              ),
              child: Row(
                children: [
                  MpMonogram(text: monogram, accent: accent, filled: selected),
                  const SizedBox(width: _gap),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: (selected
                              ? MpTypography.bodyBold()
                              : MpTypography.bodyStrong())
                          .copyWith(color: selected ? accent.deep(c) : c.ink)
                          .apply(fontSizeFactor: nameScale),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -7,
              right: -7,
              child: AnimatedScale(
                scale: selected ? 1 : 0,
                duration: MpMotion.of(context, MpMotion.select),
                curve: MpMotion.ease,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: accent.main(c),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.check, size: 13, color: c.surface),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round 44px stepper button (minus / plus). [filled] draws it solid annatto.
/// A null [onTap] disables it (at a limit) and draws its glyph faint.
class MpStepperButton extends StatelessWidget {
  const MpStepperButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return MpPress(
      onTap: onTap,
      semanticLabel: semanticLabel,
      focusRadius: MpRadius.pill,
      child: Container(
        width: MpSize.stepper,
        height: MpSize.stepper,
        decoration: BoxDecoration(
          color: filled ? c.annatto : c.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: filled ? c.annatto : c.outline,
            width: MpStroke.selected,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? c.faint : (filled ? c.surface : c.ink),
        ),
      ),
    );
  }
}
