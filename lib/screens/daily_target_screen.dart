import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import '../mealpal_ph.dart';
import '../state/plan_draft.dart';
import '../widgets/widgets.dart';

/// Step 2 of 4: the calorie target reveal. Dark hero card with ring and
/// big number, goal toggle, BMR to TDEE to delta breakdown, macro cards.
class DailyTargetScreen extends StatelessWidget {
  const DailyTargetScreen({
    super.key,
    required this.draft,
    required this.onNext,
    this.onBack,
  });

  final PlanDraft draft;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  static String _activityName(ActivityLevel a) => switch (a) {
        ActivityLevel.sedentary => 'sedentary',
        ActivityLevel.light => 'light',
        ActivityLevel.moderate => 'moderate',
        ActivityLevel.active => 'active',
        ActivityLevel.veryActive => 'very active',
      };

  static ({String row, String tagline}) _goalCopy(Goal g) => switch (g) {
        Goal.lose => (
            row: 'Deficit for losing',
            tagline: 'kcal a day, to lose about 0.5 kg a week',
          ),
        Goal.maintain => (
            row: 'Maintenance',
            tagline: 'kcal a day, to hold your weight',
          ),
        Goal.gain => (
            row: 'Surplus for gaining',
            tagline: 'kcal a day, to gain about 0.4 kg a week',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) {
        final target = draft.target;
        final macros = draft.macros;
        final goal = _goalCopy(draft.goal);
        // The change from maintenance the math actually produced. Raised to
        // the safe floor, it is smaller than the goal's, or even a surplus,
        // so the screen states it and drops the weekly-rate claim.
        final maintenance = target.tdee.round();
        final delta = target.targetCalories - maintenance;
        final clamped = target.clampedToFloor;
        final deltaText = delta < 0
            ? '−${formatThousands(-delta)} kcal'
            : delta > 0
                ? '+${formatThousands(delta)} kcal'
                : '0 kcal';
        final deltaRow = clamped && delta > 0 ? 'Above maintenance' : goal.row;
        final tagline =
            clamped ? 'kcal a day, the safe minimum for you' : goal.tagline;
        final deltaColor = delta < 0
            ? c.annatto
            : delta > 0
                ? c.green
                : c.ink;
        final floor = formatThousands(target.targetCalories);
        return MpPage(
          content: [
            const MpProgressSegments(step: 2),
            const SizedBox(height: 3),
            MpStepHeader(step: 2, onBack: onBack),
            const SizedBox(height: 10),
            const MpTitle(
              title: 'Your daily target',
              subtitle: 'Based on your stats and goal.',
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                color: c.heroSurface,
                borderRadius: BorderRadius.circular(MpRadius.hero),
              ),
              child: Row(
                children: [
                  MpCalorieRing(
                    value: target.targetCalories,
                    fraction: draft.targetFraction,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAILY ENERGY',
                          style: MpTypography.eyebrow().copyWith(
                            fontSize: 11,
                            letterSpacing: 11 * 0.12,
                            color: c.annattoFleck,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatThousands(target.targetCalories),
                          style: MpTypography.heroNumber()
                              .copyWith(color: c.heroText),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          tagline,
                          style: MpTypography.small().copyWith(
                            fontSize: 12.5,
                            color: c.heroMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (clamped) ...[
              const SizedBox(height: 10),
              Text(
                delta < 0
                    ? 'Raised to the safe minimum of $floor kcal. A steeper '
                        'deficit needs a doctor in the loop.'
                    : 'Raised to the safe minimum of $floor kcal, which is '
                        'above your maintenance of '
                        '${formatThousands(maintenance)} kcal. Talk to a '
                        'doctor before trying to lose weight.',
                style: MpTypography.small().copyWith(color: c.annattoDeep),
              ),
            ],
            const SizedBox(height: 20),
            Text('Goal', style: MpTypography.label().copyWith(color: c.ink)),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final (i, (g, label)) in const [
                  (Goal.lose, 'Lose'),
                  (Goal.maintain, 'Maintain'),
                  (Goal.gain, 'Gain'),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: MpChoiceButton(
                      label: label,
                      height: MpSize.pillButton,
                      radius: MpRadius.segment,
                      selected: draft.goal == g,
                      onTap: () => draft.goal = g,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            MpCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  _BreakdownRow(
                    label: 'BMR (at rest)',
                    value: '${formatThousands(target.bmr.round())} kcal',
                  ),
                  _BreakdownRow(
                    label:
                        'Activity ×${draft.activity.factor} (${_activityName(draft.activity)})',
                    value: '${formatThousands(maintenance)} kcal',
                  ),
                  _BreakdownRow(
                    label: deltaRow,
                    value: deltaText,
                    valueColor: deltaColor,
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MpMacroCard(
                    label: 'Protein',
                    grams: macros.proteinG,
                    fraction: macros.proteinShare,
                    accent: MpAccent.green,
                    delay: const Duration(milliseconds: 150),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MpMacroCard(
                    label: 'Carbs',
                    grams: macros.carbsG,
                    fraction: macros.carbsShare,
                    accent: MpAccent.annatto,
                    delay: const Duration(milliseconds: 230),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MpMacroCard(
                    label: 'Fat',
                    grams: macros.fatG,
                    fraction: macros.fatShare,
                    accent: MpAccent.amber,
                    delay: const Duration(milliseconds: 310),
                  ),
                ),
              ],
            ),
          ],
          footer: Column(
            children: [
              MpCta(label: 'Next: where you shop', onPressed: onNext),
              const MpCtaNote(
                'An estimate for healthy adults, not medical advice.',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.last = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: MpTypography.row().copyWith(color: c.muted)),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: MpTypography.bodyBold().copyWith(color: valueColor ?? c.ink),
          ),
        ],
      ),
    );
  }
}
