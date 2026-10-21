import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design_system/design_system.dart';
import '../mealpal_ph.dart';
import '../state/plan_draft.dart';
import '../widgets/widgets.dart';

/// Step 1 of 4: gender, age, height, weight and activity level. The CTA
/// waits until every number field holds a value.
class BodyStatsScreen extends StatefulWidget {
  const BodyStatsScreen({super.key, required this.draft, required this.onNext});

  final PlanDraft draft;
  final VoidCallback onNext;

  @override
  State<BodyStatsScreen> createState() => _BodyStatsScreenState();
}

class _BodyStatsScreenState extends State<BodyStatsScreen> {
  static const _activities = [
    (ActivityLevel.sedentary, 'Sedentary'),
    (ActivityLevel.light, 'Light'),
    (ActivityLevel.moderate, 'Moderate'),
    (ActivityLevel.active, 'Active'),
  ];

  /// Fields the user has emptied since the screen opened.
  final Set<String> _empty = {};

  void _field(String name, int? value, ValueChanged<int> write) {
    setState(() {
      if (value == null) {
        _empty.add(name);
      } else {
        _empty.remove(name);
        write(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final draft = widget.draft;
    final complete = _empty.isEmpty;
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) => MpPage(
        content: [
          const MpProgressSegments(step: 1),
          const SizedBox(height: 16),
          const MpStepHeader(step: 1),
          const SizedBox(height: 24),
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
              value: draft.age,
              unit: 'yrs',
              fieldKey: const ValueKey('field-age'),
              onChanged: (v) => _field('age', v, (n) => draft.age = n),
            ),
            MpBigValueField(
              label: 'Height',
              value: draft.heightCm,
              unit: 'cm',
              fieldKey: const ValueKey('field-height'),
              onChanged: (v) => _field('height', v, (n) => draft.heightCm = n),
            ),
          ]),
          const SizedBox(height: 18),
          MpBigValueField(
            label: 'Weight',
            value: draft.weightKg,
            unit: 'kg',
            fieldKey: const ValueKey('field-weight'),
            onChanged: (v) => _field('weight', v, (n) => draft.weightKg = n),
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
              onPressed: complete ? widget.onNext : null,
            ),
            MpCtaNote(
              complete
                  ? 'An estimate, not medical advice. You can adjust it anytime.'
                  : 'Fill in age, height and weight to continue.',
            ),
          ],
        ),
      ),
    );
  }
}
