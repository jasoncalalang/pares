import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/store_tiles.dart';
import '../design_system/design_system.dart';
import '../mealpal_ph.dart';
import '../state/plan_draft.dart';
import '../widgets/widgets.dart';

/// Step 3 of 4 — weekly ₱ budget stepper, supermarket grid, local stores.
class WhereYouShopScreen extends StatelessWidget {
  const WhereYouShopScreen({
    super.key,
    required this.draft,
    required this.onNext,
    this.onBack,
  });

  final PlanDraft draft;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) => MpPage(
        content: [
          const MpProgressSegments(step: 3),
          const SizedBox(height: 16),
          MpRise(
            delay: const Duration(milliseconds: 50),
            child: MpStepHeader(step: 3, onBack: onBack),
          ),
          const SizedBox(height: 24),
          const MpRise(
            delay: Duration(milliseconds: 100),
            child: MpTitle(
              title: 'Where do you shop?',
              subtitle: 'Pick the stores you actually buy from.',
            ),
          ),
          const SizedBox(height: 22),
          MpRise(
            delay: const Duration(milliseconds: 140),
            child: MpCard(
              radius: MpRadius.cardLg,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WEEKLY BUDGET',
                          style: MpTypography.sectionEyebrow()
                              .copyWith(color: c.faint),
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
                                formatPeso(draft.weeklyBudgetPhp, decimals: 0),
                                style: MpTypography.budgetValue()
                                    .copyWith(color: c.ink),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '/ week',
                                style: MpTypography.body().copyWith(
                                  color: c.faint,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  MpStepperButton(
                    icon: LucideIcons.minus,
                    semanticLabel: 'Decrease budget',
                    onTap: draft.budgetDown,
                  ),
                  const SizedBox(width: 10),
                  MpStepperButton(
                    icon: LucideIcons.plus,
                    semanticLabel: 'Increase budget',
                    filled: true,
                    onTap: draft.budgetUp,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          MpGrid2(children: [
            for (final (i, t) in chainTiles.indexed)
              MpRise(
                delay: Duration(milliseconds: 180 + 40 * i),
                child: MpStoreTile(
                  name: t.name,
                  monogram: t.monogram,
                  selected: draft.isStoreSelected(t.id),
                  onTap: () => draft.toggleStore(t.id),
                ),
              ),
          ]),
          const SizedBox(height: 24),
          MpRise(
            delay: const Duration(milliseconds: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOCAL TO THE PHILIPPINES',
                  style: MpTypography.sectionEyebrow().copyWith(color: c.green),
                ),
                const SizedBox(height: 5),
                Text(
                  'Pick the ones you actually use',
                  style: MpTypography.small().copyWith(color: c.faint),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MpGrid2(children: [
            for (final (i, t) in localTiles.indexed)
              MpRise(
                delay: Duration(milliseconds: 560 + 40 * i),
                child: MpStoreTile(
                  name: t.name,
                  monogram: t.monogram,
                  local: true,
                  selected: draft.isStoreSelected(t.id),
                  onTap: () => draft.toggleStore(t.id),
                ),
              ),
          ]),
        ],
        footer: MpRise(
          delay: const Duration(milliseconds: 640),
          child: MpCta(
            label: 'Build my plan (${draft.selectedStoreCount})',
            onPressed: onNext,
          ),
        ),
      ),
    );
  }
}
