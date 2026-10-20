import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design_system/design_system.dart';
import '../mealpal_ph.dart';
import '../widgets/widgets.dart';

/// The grocery list: estimated total against budget, then one collapsible
/// section per store with check-off rows, then the delivery handoff.
class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({
    super.key,
    required this.list,
    required this.onBack,
    required this.onOrder,
  });

  final GroceryList list;
  final VoidCallback onBack;
  final VoidCallback onOrder;

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
    return MpPage(
      content: [
        MpRise(
          delay: const Duration(milliseconds: 50),
          child: MpBackHeader(label: 'THIS WEEK', onBack: widget.onBack),
        ),
        const SizedBox(height: 22),
        const MpRise(
          delay: Duration(milliseconds: 100),
          child: MpTitle(
            title: 'Grocery list',
            subtitle: 'Everything for this week, grouped by where to buy it.',
          ),
        ),
        const SizedBox(height: 20),
        MpRise(
          delay: const Duration(milliseconds: 150),
          child: MpCard(
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
        ),
        const SizedBox(height: 18),
        for (final (i, section) in list.sections.indexed) ...[
          if (i > 0) const SizedBox(height: 14),
          MpRise(
            delay: Duration(milliseconds: 200 + 60 * i),
            child: MpGrocerySection(
              section: section,
              expanded: !_collapsed.contains(i),
              onToggle: () => _toggleSection(i),
              checked: _checked[i] ?? const {},
              onCheck: (item) => _check(i, item),
            ),
          ),
        ],
        const SizedBox(height: 20),
        MpRise(
          delay: const Duration(milliseconds: 380),
          child: Column(
            children: [
              MpCta(
                label: 'Order delivery via GrabMart',
                icon: LucideIcons.shoppingBag,
                iconLeading: true,
                onPressed: widget.onOrder,
              ),
              const MpCtaNote(
                'Supermarket items ship; the wet market and corner store are a '
                'quick in-person run.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
