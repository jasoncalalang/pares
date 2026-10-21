import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design_system/design_system.dart';
import '../mealpal_ph.dart';
import '../state/plan_draft.dart';
import '../widgets/widgets.dart';

/// Step 1 of 4: gender, age, height, weight and activity level. The CTA
/// waits until every number field holds a value.
class BodyStatsScreen extends StatelessWidget {
  const BodyStatsScreen({
    super.key,
    required this.draft,
    required this.onNext,
    this.onBack,
  });

  final PlanDraft draft;
  final VoidCallback onNext;

  /// Back to Welcome.
  final VoidCallback? onBack;

  static const _activities = [
    (ActivityLevel.sedentary, 'Sedentary'),
    (ActivityLevel.light, 'Light'),
    (ActivityLevel.moderate, 'Moderate'),
    (ActivityLevel.active, 'Active'),
  ];

  void _field(BodyStat stat, int? value, ValueChanged<int> write) {
    if (value != null) write(value);
    draft.setBlank(stat, blank: value == null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) {
        final complete = draft.bodyStatsComplete;
        int? shown(BodyStat stat, int value) => draft.isBlank(stat) ? null : value;
        return MpPage(
          content: [
            const MpProgressSegments(step: 1),
            const SizedBox(height: 3),
            MpStepHeader(step: 1, onBack: onBack),
            const SizedBox(height: 10),
            const MpTitle(
              title: 'Tell us about you',
              subtitle:
                  "We'll set your daily calorie target. Everything is in metric: kg and cm.",
            ),
            const SizedBox(height: 26),
            Text('Gender', style: MpTypography.label().copyWith(color: c.ink)),
            const SizedBox(height: 9),
            MpGrid2(children: [
              MpChoiceButton(
                label: 'Male',
                icon: LucideIcons.mars,
                selected: draft.sex == BiologicalSex.male,
                onTap: () => draft.sex = BiologicalSex.male,
              ),
              MpChoiceButton(
                label: 'Female',
                icon: LucideIcons.venus,
                selected: draft.sex == BiologicalSex.female,
                onTap: () => draft.sex = BiologicalSex.female,
              ),
            ]),
            const SizedBox(height: 18),
            MpGrid2(gap: 12, children: [
              MpBigValueField(
                label: 'Age',
                value: shown(BodyStat.age, draft.age),
                unit: 'yrs',
                spokenUnit: 'years',
                fieldKey: const ValueKey('field-age'),
                onChanged: (v) => _field(BodyStat.age, v, (n) => draft.age = n),
              ),
              MpBigValueField(
                label: 'Height',
                value: shown(BodyStat.height, draft.heightCm),
                unit: 'cm',
                spokenUnit: 'centimeters',
                fieldKey: const ValueKey('field-height'),
                onChanged: (v) => _field(BodyStat.height, v, (n) => draft.heightCm = n),
              ),
            ]),
            const SizedBox(height: 18),
            MpBigValueField(
              label: 'Weight',
              value: shown(BodyStat.weight, draft.weightKg),
              unit: 'kg',
              spokenUnit: 'kilograms',
              fieldKey: const ValueKey('field-weight'),
              onChanged: (v) => _field(BodyStat.weight, v, (n) => draft.weightKg = n),
            ),
            const SizedBox(height: 22),
            Text('Activity level', style: MpTypography.label().copyWith(color: c.ink)),
            const SizedBox(height: 10),
            MpGrid2(children: [
              for (final (level, label) in _activities)
                MpChoiceButton(
                  label: label,
                  accent: MpAccent.green,
                  height: MpSize.pillButton,
                  radius: MpRadius.pill,
                  selected: draft.activity == level,
                  onTap: () => draft.activity = level,
                ),
            ]),
          ],
          footer: Column(
            children: [
              MpCta(
                label: 'Compute my target',
                onPressed: complete ? onNext : null,
              ),
              MpCtaNote(
                complete
                    ? 'An estimate, not medical advice. You can adjust it anytime.'
                    : 'Fill in age, height and weight to continue.',
              ),
            ],
          ),
        );
      },
    );
  }
}
