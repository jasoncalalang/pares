import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design_system/design_system.dart';
import '../mealpal_ph.dart';
import '../state/plan_draft.dart';
import '../widgets/widgets.dart';

/// Step 1 of 4 — gender, age, height, weight and activity level.
class BodyStatsScreen extends StatelessWidget {
  const BodyStatsScreen({super.key, required this.draft, required this.onNext});

  final PlanDraft draft;
  final VoidCallback onNext;

  static const _activities = [
    (ActivityLevel.sedentary, 'Sedentary'),
    (ActivityLevel.light, 'Light'),
    (ActivityLevel.moderate, 'Moderate'),
    (ActivityLevel.active, 'Active'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) => MpPage(
        content: [
          const MpProgressSegments(step: 1),
          const SizedBox(height: 16),
          const MpRise(
            delay: Duration(milliseconds: 50),
            child: MpStepHeader(step: 1),
          ),
          const SizedBox(height: 24),
          const MpRise(
            delay: Duration(milliseconds: 100),
            child: MpTitle(
              title: 'Tell us about you',
              subtitle:
                  "We'll set your daily calorie target. Everything in metric — kg and cm.",
            ),
          ),
          const SizedBox(height: 26),
          MpRise(
            delay: const Duration(milliseconds: 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
              ],
            ),
          ),
          const SizedBox(height: 18),
          MpRise(
            delay: const Duration(milliseconds: 200),
            child: MpGrid2(gap: 12, children: [
              MpBigValueField(
                label: 'Age',
                value: draft.age,
                unit: 'yrs',
                fieldKey: const ValueKey('field-age'),
                onChanged: (v) => draft.age = v,
              ),
              MpBigValueField(
                label: 'Height',
                value: draft.heightCm,
                unit: 'cm',
                fieldKey: const ValueKey('field-height'),
                onChanged: (v) => draft.heightCm = v,
              ),
            ]),
          ),
          const SizedBox(height: 18),
          MpRise(
            delay: const Duration(milliseconds: 250),
            child: MpBigValueField(
              label: 'Weight',
              value: draft.weightKg,
              unit: 'kg',
              fieldKey: const ValueKey('field-weight'),
              onChanged: (v) => draft.weightKg = v,
            ),
          ),
          const SizedBox(height: 22),
          MpRise(
            delay: const Duration(milliseconds: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Activity level',
                    style: MpTypography.label().copyWith(color: c.ink)),
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
            ),
          ),
        ],
        footer: MpRise(
          delay: const Duration(milliseconds: 350),
          child: Column(
            children: [
              MpCta(label: 'Compute my target', onPressed: onNext),
              const MpCtaNote(
                'An estimate, not medical advice — you can adjust it anytime.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
