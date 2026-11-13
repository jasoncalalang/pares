import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design_system/design_system.dart';
import '../../mealpal_ph.dart';
import '../core/mp_card.dart';
import '../core/mp_press.dart';

/// Collapsible per-store section of the grocery list: monogram, store name
/// (+ note), item count and subtotal in the header with a chevron that
/// rotates; beneath it a card of rows, each with an ingredient icon, name +
/// quantity, price and a checkbox. Checked rows dim and strike through.
class MpGrocerySection extends StatelessWidget {
  const MpGrocerySection({
    super.key,
    required this.section,
    required this.expanded,
    required this.onToggle,
    required this.checked,
    required this.onCheck,
  });

  final GrocerySection section;
  final bool expanded;
  final VoidCallback onToggle;

  /// Indices of checked-off items.
  final Set<int> checked;
  final ValueChanged<int> onCheck;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final accent = section.local ? MpAccent.green : MpAccent.annatto;
    // At large text the subtotal drops under the name, so the name keeps the
    // full width and no store name is broken in two.
    final bigText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final count = Text(
      '${section.items.length} items',
      style: MpTypography.small().copyWith(color: c.faint),
    );
    final subtotal = Text(
      formatPeso(section.subtotalPhp, decimals: 0),
      style: MpTypography.rowTitle().copyWith(color: c.ink),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MpPress(
          onTap: onToggle,
          expanded: expanded,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: MpSize.tap),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Row(
                children: [
                  MpMonogram(text: section.monogram, accent: accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // A Wrap, not a one-line Row: at large text the note
                        // drops under the name instead of cutting it off.
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            Text(
                              section.name,
                              style: MpTypography.rowTitle().copyWith(color: c.ink),
                            ),
                            if (section.note != null)
                              Text(
                                section.note!,
                                style: MpTypography.rowTitle().copyWith(
                                  color: c.faint,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        if (bigText)
                          Wrap(
                            spacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [count, subtotal],
                          )
                        else
                          count,
                      ],
                    ),
                  ),
                  if (!bigText) ...[subtotal, const SizedBox(width: 12)],
                  if (bigText) const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: expanded ? 0 : -0.25,
                    duration: MpMotion.of(context, MpMotion.expand),
                    curve: MpMotion.ease,
                    child: Icon(LucideIcons.chevronDown, size: 18, color: c.faint),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: MpMotion.of(context, MpMotion.expand),
          curve: MpMotion.ease,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: MpCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Column(
                      children: [
                        for (var i = 0; i < section.items.length; i++)
                          _GroceryRow(
                            item: section.items[i],
                            done: checked.contains(i),
                            last: i == section.items.length - 1,
                            onTap: () => onCheck(i),
                          ),
                      ],
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _GroceryRow extends StatelessWidget {
  const _GroceryRow({
    required this.item,
    required this.done,
    required this.last,
    required this.onTap,
  });

  final GroceryItem item;
  final bool done;
  final bool last;
  final VoidCallback onTap;

  /// Each glyph pictures its kind, so a row can be picked out by kind
  /// before its name is read: a leaf for vegetables, aromatics included, a
  /// bottle for condiments, a sprout for dried leaves and peppercorns, a
  /// pack for packaged pantry goods. The tint sorts rows by family: annatto
  /// for meat, fish and condiments, green for produce, amber for dry goods.
  static (IconData, MpAccent) _glyph(GroceryKind kind) => switch (kind) {
        GroceryKind.meat => (LucideIcons.beef, MpAccent.annatto),
        GroceryKind.poultry => (LucideIcons.drumstick, MpAccent.annatto),
        GroceryKind.fish => (LucideIcons.fish, MpAccent.annatto),
        GroceryKind.produce => (LucideIcons.leaf, MpAccent.green),
        GroceryKind.fruit => (LucideIcons.banana, MpAccent.amber),
        GroceryKind.aromatics => (LucideIcons.leaf, MpAccent.green),
        GroceryKind.grain => (LucideIcons.wheat, MpAccent.amber),
        GroceryKind.egg => (LucideIcons.egg, MpAccent.amber),
        GroceryKind.legume => (LucideIcons.bean, MpAccent.amber),
        GroceryKind.oil => (LucideIcons.droplet, MpAccent.amber),
        GroceryKind.condiment => (LucideIcons.milk, MpAccent.annatto),
        GroceryKind.spice => (LucideIcons.sprout, MpAccent.amber),
        GroceryKind.pantry => (LucideIcons.package, MpAccent.amber),
      };

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final (icon, accent) = _glyph(item.kind);
    final select = MpMotion.of(context, MpMotion.select);
    // The ingredient glyph is decoration; at large text the name gets its
    // room instead, so a word like "(tamarind)" is not cut.
    final bigText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final price = Text(
      formatPeso(item.pricePhp, decimals: 0),
      style: MpTypography.bodyStrong().copyWith(color: done ? c.faint : c.ink),
    );
    return MpPress(
      onTap: onTap,
      scale: 1,
      focusRadius: MpRadius.iconBox,
      // Checked rows dim their text to faint (still 4.5:1 on white) and
      // strike the name through; fading the whole row made it unreadable.
      child: Semantics(
        checked: done,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: last
                ? null
                : Border(bottom: BorderSide(color: c.dividerSoft)),
          ),
          child: Row(
            children: [
              if (!bigText) ...[
                Container(
                  width: MpSize.iconBox,
                  height: MpSize.iconBox,
                  decoration: BoxDecoration(
                    color: accent.tint(c),
                    borderRadius: BorderRadius.circular(MpRadius.iconBox),
                  ),
                  child: Icon(icon, size: 18, color: accent.deep(c)),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: MpTypography.bodyStrong().copyWith(
                        color: done ? c.faint : c.ink,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: c.faint,
                      ),
                    ),
                    Text(
                      item.quantity,
                      style: MpTypography.small().copyWith(color: c.faint),
                    ),
                    // At large text the price sits under the amount so the
                    // name keeps the row's width, hyphens and all.
                    if (bigText) price,
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (!bigText) ...[price, const SizedBox(width: 12)],
              AnimatedContainer(
                duration: select,
                width: MpSize.checkbox,
                height: MpSize.checkbox,
                decoration: BoxDecoration(
                  color: done ? c.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(MpRadius.checkbox),
                  border: Border.all(
                    color: done ? c.green : c.outline,
                    width: MpStroke.selected,
                  ),
                ),
                child: AnimatedOpacity(
                  opacity: done ? 1 : 0,
                  duration: select,
                  child: Icon(LucideIcons.check, size: 13, color: c.surface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
