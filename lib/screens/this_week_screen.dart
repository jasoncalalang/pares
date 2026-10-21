import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/sample_week.dart';
import '../design_system/design_system.dart';
import '../mealpal_ph.dart';
import '../state/plan_draft.dart';
import '../widgets/widgets.dart';

/// Where the week's plan is in its life: being built by the recommender,
/// ready to show, or failed.
enum PlanStatus { ready, building, failed }

/// The weekly plan: target + budget pills, day strip, the selected day's
/// four meal cards (each swappable for the next option in its slot), and
/// the way into the grocery list. While the plan is [PlanStatus.building]
/// or [PlanStatus.failed] the screen says so instead of showing meals.
class ThisWeekScreen extends StatefulWidget {
  const ThisWeekScreen({
    super.key,
    required this.draft,
    required this.week,
    required this.onGrocery,
    this.onBack,
    this.status = PlanStatus.ready,
    this.onRetry,
    this.weekStart,
  });

  final PlanDraft draft;
  final List<DayPlan> week;
  final VoidCallback onGrocery;

  /// Back to the stores and budget.
  final VoidCallback? onBack;
  final PlanStatus status;

  /// Rebuilds the plan after a failure.
  final VoidCallback? onRetry;

  /// The Monday the strip's dates count from; defaults to this week.
  final DateTime? weekStart;

  @override
  State<ThisWeekScreen> createState() => _ThisWeekScreenState();
}

class _ThisWeekScreenState extends State<ThisWeekScreen> {
  int _day = 0;

  /// Meals the user swapped in, keyed by day and slot.
  final Map<String, PlannedMeal> _swapped = {};

  DateTime get _monday {
    if (widget.weekStart != null) return widget.weekStart!;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  String _key(Weekday day, MealSlot slot) => '${day.name}-${slot.name}';

  /// The selected day with any swaps applied.
  DayPlan get _dayPlan {
    final base = widget.week[_day];
    return DayPlan(
      weekday: base.weekday,
      meals: [
        for (final m in base.meals) _swapped[_key(base.weekday, m.slot)] ?? m,
      ],
    );
  }

  void _swap(Weekday day, PlannedMeal current) {
    setState(() {
      _swapped[_key(day, current.slot)] = nextAlternative(current);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final ready = widget.status == PlanStatus.ready;
    final monday = _monday;
    return ListenableBuilder(
      listenable: widget.draft,
      builder: (context, _) {
        final target = formatThousands(widget.draft.target.targetCalories);
        final budget = formatPeso(widget.draft.weeklyBudgetPhp, decimals: 0);
        final day = ready ? _dayPlan : null;
        return MpPage(
          content: [
            if (widget.onBack != null) ...[
              MpBackHeader(label: 'STORES', onBack: widget.onBack!),
              const SizedBox(height: 9),
            ],
            Row(
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
                          MpPill(label: '$target kcal/day', accent: MpAccent.annatto),
                          MpPill(label: '≤ $budget', accent: MpAccent.green),
                        ],
                      ),
                    ],
                  ),
                ),
                if (ready)
                  MpPillButton(
                    label: 'Grocery list',
                    icon: LucideIcons.shoppingCart,
                    accent: MpAccent.annatto,
                    onTap: widget.onGrocery,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (day == null)
              _PlanStateCard(
                status: widget.status,
                target: target,
                budget: budget,
                onRetry: widget.onRetry,
              )
            else ...[
              MpDayStrip(
                days: [for (final d in widget.week) d.weekday],
                dayNumbers: [
                  for (var i = 0; i < widget.week.length; i++)
                    monday.add(Duration(days: i)).day,
                ],
                selected: _day,
                onSelect: (i) => setState(() => _day = i),
              ),
              const SizedBox(height: 13),
              Text(
                '${day.weekday.label} · ${formatThousands(day.kcal)} kcal · '
                '${formatPeso(day.pricePhp, decimals: 0)}',
                style: MpTypography.label().copyWith(
                  color: c.faint,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              for (final (i, meal) in day.meals.indexed) ...[
                if (i > 0) const SizedBox(height: MpSpacing.cardGap),
                MpMealCard(
                  key: ValueKey('${day.weekday.name}-${meal.slot.name}'),
                  meal: meal,
                  onSwap: () => _swap(day.weekday, meal),
                ),
              ],
            ],
          ],
          footer: ready
              ? MpCta(label: 'See grocery list', onPressed: widget.onGrocery)
              : null,
        );
      },
    );
  }
}

/// What the screen shows instead of meals while the recommender is working
/// or after it failed: the cause, and the one thing to do next.
class _PlanStateCard extends StatelessWidget {
  const _PlanStateCard({
    required this.status,
    required this.target,
    required this.budget,
    required this.onRetry,
  });

  final PlanStatus status;
  final String target;
  final String budget;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final failed = status == PlanStatus.failed;
    return MpCard(
      radius: MpRadius.cardLg,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (failed)
            Icon(LucideIcons.triangleAlert, size: 22, color: c.annattoDeep)
          else
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: c.annatto,
                semanticsLabel: 'Building your week',
              ),
            ),
          const SizedBox(height: 14),
          Text(
            failed ? "We couldn't build your week." : 'Building your week',
            style: MpTypography.rowTitle().copyWith(color: c.ink),
          ),
          const SizedBox(height: 6),
          Text(
            failed
                ? 'Your stats and stores are saved. Check your connection and '
                    'try again.'
                : 'Matching meals to your $target kcal target and $budget '
                    'weekly budget from the stores you picked.',
            style: MpTypography.body().copyWith(color: c.muted),
          ),
          if (failed) ...[
            const SizedBox(height: 16),
            MpCta(
              label: 'Try again',
              icon: LucideIcons.refreshCw,
              iconLeading: true,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
