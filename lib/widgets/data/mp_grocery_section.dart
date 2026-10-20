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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MpPress(
          onTap: onToggle,
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              section.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MpTypography.rowTitle().copyWith(color: c.ink),
                            ),
                          ),
                          if (section.note != null) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                section.note!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MpTypography.rowTitle().copyWith(
                                  color: c.faint,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${section.items.length} items',
                        style: MpTypography.small().copyWith(color: c.faint),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatPeso(section.subtotalPhp, decimals: 0),
                  style: MpTypography.rowTitle().copyWith(color: c.ink),
                ),
                const SizedBox(width: 12),
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

  static (IconData, MpAccent) _glyph(GroceryKind kind) => switch (kind) {
        GroceryKind.meat => (LucideIcons.beef, MpAccent.annatto),
        GroceryKind.poultry => (LucideIcons.drumstick, MpAccent.annatto),
        GroceryKind.produce => (LucideIcons.leaf, MpAccent.green),
        GroceryKind.fruit => (LucideIcons.banana, MpAccent.amber),
        GroceryKind.aromatics => (LucideIcons.carrot, MpAccent.annatto),
        GroceryKind.grain => (LucideIcons.wheat, MpAccent.amber),
        GroceryKind.egg => (LucideIcons.egg, MpAccent.amber),
        GroceryKind.legume => (LucideIcons.bean, MpAccent.amber),
        GroceryKind.oil => (LucideIcons.droplet, MpAccent.amber),
        GroceryKind.condiment => (LucideIcons.flaskConical, MpAccent.annatto),
        GroceryKind.spice => (LucideIcons.utensils, MpAccent.amber),
        GroceryKind.pantry => (LucideIcons.shoppingBag, MpAccent.amber),
      };

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final (icon, accent) = _glyph(item.kind);
    final select = MpMotion.of(context, MpMotion.select);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        checked: done,
        label: item.name,
        child: AnimatedOpacity(
          opacity: done ? 0.5 : 1,
          duration: MpMotion.of(context, MpMotion.expand),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: last
                  ? null
                  : Border(bottom: BorderSide(color: c.dividerSoft)),
            ),
            child: Row(
              children: [
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
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatPeso(item.pricePhp, decimals: 0),
                  style: MpTypography.bodyStrong().copyWith(color: c.ink),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: select,
                  width: MpSize.checkbox,
                  height: MpSize.checkbox,
                  decoration: BoxDecoration(
                    color: done ? c.green : Colors.transparent,
                    borderRadius: BorderRadius.circular(MpRadius.checkbox),
                    border: Border.all(
                      color: done ? c.green : c.hairline,
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
      ),
    );
  }
}
