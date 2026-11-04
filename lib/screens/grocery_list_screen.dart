import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design_system/design_system.dart';
import '../mealpal_ph.dart';
import '../widgets/widgets.dart';

/// Shown in every mode: what the numbers on the list are.
const String groceryListNote =
    'Amounts are what your meals use. Prices are rough estimates for now.';

/// The grocery list: estimated total against budget, then one collapsible
/// section per store with check-off rows. With no plan yet it says so.
class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({
    super.key,
    required this.list,
    required this.onBack,
  });

  final GroceryList list;
  final VoidCallback onBack;

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  // Keyed by store id and item key, not by position: a swap can land while
  // the list is open and move rows around.
  final Set<String> _collapsed = {};
  final Set<(String, String)> _checked = {};

  @override
  void didUpdateWidget(GroceryListScreen old) {
    super.didUpdateWidget(old);
    // Ticks for items that left the list are dropped, not carried over.
    final present = {
      for (final s in widget.list.sections)
        for (final i in s.items) (s.storeId, i.key),
    };
    _checked.removeWhere((k) => !present.contains(k));
  }

  void _toggleSection(String storeId) {
    setState(() {
      if (!_collapsed.remove(storeId)) _collapsed.add(storeId);
    });
  }

  void _check(GrocerySection section, int item) {
    final key = (section.storeId, section.items[item].key);
    setState(() {
      if (!_checked.remove(key)) _checked.add(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final list = widget.list;
    final over = list.overBudget;
    final headroom = over
        ? '${formatPeso(-list.remainingPhp, decimals: 0)} over budget'
        : '${formatPeso(list.remainingPhp, decimals: 0)} under budget';
    final headroomColor = over ? c.annattoDeep : c.green;
    final empty = list.sections.isEmpty;
    return MpPage(
      content: [
        MpBackHeader(label: 'THIS WEEK', onBack: widget.onBack),
        const SizedBox(height: 9),
        const MpTitle(
          title: 'Grocery list',
          subtitle: 'Grouped by where to buy it.',
        ),
        const SizedBox(height: 10),
        Text(
          groceryListNote,
          style: MpTypography.small().copyWith(color: c.annattoDeep),
        ),
        const SizedBox(height: 20),
        if (empty)
          MpCard(
            radius: MpRadius.cardLg,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.shoppingBasket, size: 22, color: c.green),
                const SizedBox(height: 14),
                Text(
                  'Nothing to buy yet',
                  style: MpTypography.rowTitle().copyWith(color: c.ink),
                ),
                const SizedBox(height: 6),
                Text(
                  "Build this week's plan first. The list fills itself in, "
                  'grouped by store.',
                  style: MpTypography.body().copyWith(color: c.muted),
                ),
              ],
            ),
          )
        else ...[
          MpCard(
            radius: MpRadius.cardLg,
            shadow: true,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTIMATED TOTAL',
                  style: MpTypography.sectionEyebrow().copyWith(color: c.faint),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatPeso(list.totalPhp, decimals: 0),
                        style: MpTypography.totalValue()
                            .copyWith(color: headroomColor),
                      ),
                      Text(
                        ' / ${formatPeso(list.budgetPhp, decimals: 0)}',
                        style: MpTypography.totalCap().copyWith(color: c.faint),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                MpProgressBar(fraction: list.budgetFraction, color: headroomColor),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      over ? LucideIcons.triangleAlert : LucideIcons.check,
                      size: 15,
                      color: headroomColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        headroom,
                        style: MpTypography.label().copyWith(color: headroomColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final (i, section) in list.sections.indexed) ...[
            if (i > 0) const SizedBox(height: 14),
            MpGrocerySection(
              section: section,
              expanded: !_collapsed.contains(section.storeId),
              onToggle: () => _toggleSection(section.storeId),
              checked: {
                for (final (n, item) in section.items.indexed)
                  if (_checked.contains((section.storeId, item.key))) n,
              },
              onCheck: (item) => _check(section, item),
            ),
          ],
          const SizedBox(height: 20),
          // TODO(delivery): replace with the GrabMart cart handoff once the
          // partner flow exists. Until then this stays an honest note, not a
          // button that goes nowhere.
          Text(
            'Delivery handoff to GrabMart is coming soon. For now, shop from '
            'the list.',
            textAlign: TextAlign.center,
            style: MpTypography.label().copyWith(
              color: c.faint,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}
