import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design_system/design_system.dart';
import '../mealpal_ph.dart';
import '../state/plan_draft.dart';
import '../widgets/widgets.dart';

/// The weekly plan: target + budget pills, day strip, the selected day's
/// four meal cards, and the way into the grocery list.
class ThisWeekScreen extends StatefulWidget {
  const ThisWeekScreen({
    super.key,
    required this.draft,
    required this.week,
    required this.onGrocery,
    required this.onNew,
    this.weekStart,
  });

  final PlanDraft draft;
  final List<DayPlan> week;
  final VoidCallback onGrocery;
  final VoidCallback onNew;

  /// The Monday the strip's dates count from; defaults to this week.
  final DateTime? weekStart;

  @override
  State<ThisWeekScreen> createState() => _ThisWeekScreenState();
}

class _ThisWeekScreenState extends State<ThisWeekScreen> {
  int _day = 0;

  DateTime get _monday {
    if (widget.weekStart != null) return widget.weekStart!;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final day = widget.week[_day];
    final monday = _monday;
    return ListenableBuilder(
      listenable: widget.draft,
      builder: (context, _) => MpPage(
        content: [
          MpRise(
            delay: const Duration(milliseconds: 50),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This week',
                        style: MpTypography.h1().copyWith(color: c.ink, height: 1.05),
                      ),
                      const SizedBox(height: 11),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          MpPill(
                            label:
                                '${formatThousands(widget.draft.target.targetCalories)} kcal/day',
                            accent: MpAccent.annatto,
                          ),
                          MpPill(
                            label:
                                '≤ ${formatPeso(widget.draft.weeklyBudgetPhp, decimals: 0)}',
                            accent: MpAccent.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      MpPillButton(
                        label: 'Grocery list',
                        icon: LucideIcons.shoppingCart,
                        accent: MpAccent.annatto,
                        onTap: widget.onGrocery,
                      ),
                      const SizedBox(height: 8),
                      MpPillButton(
                        label: 'New',
                        icon: LucideIcons.refreshCw,
                        onTap: widget.onNew,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          MpRise(
            delay: const Duration(milliseconds: 100),
            child: MpDayStrip(
              days: [for (final d in widget.week) d.weekday],
              dayNumbers: [
                for (var i = 0; i < widget.week.length; i++)
                  monday.add(Duration(days: i)).day,
              ],
              selected: _day,
              onSelect: (i) => setState(() => _day = i),
            ),
          ),
          const SizedBox(height: 13),
          MpRise(
            delay: const Duration(milliseconds: 140),
            child: Text(
              '${day.weekday.label} · ${formatThousands(day.kcal)} kcal · '
              '${formatPeso(day.pricePhp, decimals: 0)}',
              style: MpTypography.label().copyWith(
                color: c.faint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (final (i, meal) in day.meals.indexed) ...[
            if (i > 0) const SizedBox(height: MpSpacing.cardGap),
            MpRise(
              key: ValueKey('${day.weekday.name}-${meal.slot.name}'),
              delay: Duration(milliseconds: 180 + 60 * i),
              child: MpMealCard(meal: meal, onSwap: () {}),
            ),
          ],
        ],
        footer: MpRise(
          delay: const Duration(milliseconds: 400),
          child: MpCta(label: 'See grocery list', onPressed: widget.onGrocery),
        ),
      ),
    );
  }
}
