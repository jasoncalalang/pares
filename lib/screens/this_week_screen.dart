import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design_system/design_system.dart';
import '../mealpal_ph.dart';
import '../state/plan_draft.dart';
import '../state/week_plan_controller.dart';
import '../widgets/widgets.dart';

/// The weekly plan: target + budget pills, day strip, the selected day's
/// four meal cards (each swappable through the planner), and the way into
/// the grocery list. It draws whatever [controller] holds: the building
/// card while the plan builds, the failed card with Try again when it
/// fails, and the week when it is ready. A swap keeps the week on screen.
class ThisWeekScreen extends StatefulWidget {
  const ThisWeekScreen({
    super.key,
    required this.draft,
    required this.controller,
    required this.onGrocery,
    this.onBack,
    this.weekStart,
  });

  final PlanDraft draft;
  final WeekPlanController controller;
  final VoidCallback onGrocery;

  /// Back to the stores and budget.
  final VoidCallback? onBack;

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
    final monday = _monday;
    return ListenableBuilder(
      listenable: Listenable.merge([widget.draft, widget.controller]),
      builder: (context, _) {
        final plan = widget.controller;
        final week = plan.week;
        final ready = plan.status == PlanStatus.ready && week != null;
        final swapping = plan.swapping;
        final target = formatThousands(widget.draft.brief.targetKcal);
        final budget = formatPeso(widget.draft.weeklyBudgetPhp, decimals: 0);
        final day = ready ? week[_day.clamp(0, week.length - 1)] : null;
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
                        style: MpTypography.h1().copyWith(
                          color: c.ink,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 11),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          MpPill(
                            label: '$target kcal/day',
                            accent: MpAccent.annatto,
                          ),
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
                status: plan.status,
                target: target,
                budget: budget,
                failure: plan.failure,
                onRetry: plan.retry,
              )
            else ...[
              MpDayStrip(
                days: [for (final d in week!) d.weekday],
                dayNumbers: [
                  for (var i = 0; i < week.length; i++)
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
              if (plan.notice != null) ...[
                _Notice(plan.notice!),
                const SizedBox(height: MpSpacing.cardGap),
              ],
              for (final (i, meal) in day.meals.indexed) ...[
                if (i > 0) const SizedBox(height: MpSpacing.cardGap),
                MpMealCard(
                  key: ValueKey('${day.weekday.name}-${meal.slot.name}'),
                  meal: meal,
                  swapping: swapping == (day.weekday, meal.slot),
                  onSwap: swapping != null
                      ? null
                      : () => plan.swap(day.weekday, meal.slot),
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
    required this.failure,
    required this.onRetry,
  });

  final PlanStatus status;
  final String target;
  final String budget;

  /// What went wrong, in words fit to show; null falls back to a general line.
  final String? failure;
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
                ? failure ??
                      'Your stats and stores are still here. Check your '
                          'connection and try again.'
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

/// A line above the meals: why a swap changed nothing or did not go through.
class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(LucideIcons.info, size: 16, color: c.annattoDeep),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: MpTypography.body().copyWith(color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}
