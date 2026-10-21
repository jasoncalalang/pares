import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design_system/design_system.dart';
import '../mealpal_ph.dart';
import '../widgets/widgets.dart';

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
  final Set<int> _collapsed = {};
  final Map<int, Set<int>> _checked = {};

  void _toggleSection(int i) {
    setState(() {
      if (!_collapsed.remove(i)) _collapsed.add(i);
    });
  }

  void _check(int section, int item) {
    setState(() {
      final set = _checked.putIfAbsent(section, () => {});
      if (!set.remove(item)) set.add(item);
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
        const SizedBox(height: 22),
        const MpTitle(
          title: 'Grocery list',
          subtitle: 'Everything for this week, grouped by where to buy it.',
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
                    Text(
                      headroom,
                      style: MpTypography.label().copyWith(color: headroomColor),
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
              expanded: !_collapsed.contains(i),
              onToggle: () => _toggleSection(i),
              checked: _checked[i] ?? const {},
              onCheck: (item) => _check(i, item),
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
