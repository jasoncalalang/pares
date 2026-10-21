import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/store_tiles.dart';
import '../design_system/design_system.dart';
import '../mealpal_ph.dart';
import '../state/plan_draft.dart';
import '../widgets/widgets.dart';

/// Step 3 of 4: weekly ₱ budget stepper, supermarket grid, local stores.
/// The CTA waits until at least one store is picked.
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
      builder: (context, _) {
        final count = draft.selectedStoreCount;
        return MpPage(
          content: [
            const MpProgressSegments(step: 3),
            const SizedBox(height: 3),
            MpStepHeader(step: 3, onBack: onBack),
            const SizedBox(height: 10),
            const MpTitle(
              title: 'Where do you shop?',
              subtitle: 'Pick the stores you actually buy from.',
            ),
            const SizedBox(height: 22),
            MpCard(
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
                    onTap: draft.canBudgetDown ? draft.budgetDown : null,
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
            const SizedBox(height: 16),
            // One fit for both grids, so every store name is the same size.
            LayoutBuilder(builder: (context, box) {
              final fit = MpStoreTile.fit(
                context,
                names: [for (final t in [...chainTiles, ...localTiles]) t.name],
                width: box.maxWidth,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MpGrid2(columns: fit.columns, children: [
                    for (final t in chainTiles)
                      MpStoreTile(
                        name: t.name,
                        monogram: t.monogram,
                        nameScale: fit.nameScale,
                        selected: draft.isStoreSelected(t.id),
                        onTap: () => draft.toggleStore(t.id),
                      ),
                  ]),
                  const SizedBox(height: 24),
                  Text(
                    'LOCAL TO THE PHILIPPINES',
                    style: MpTypography.sectionEyebrow().copyWith(color: c.green),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Pick the ones you actually use',
                    style: MpTypography.small().copyWith(color: c.faint),
                  ),
                  const SizedBox(height: 12),
                  MpGrid2(columns: fit.columns, children: [
                    for (final t in localTiles)
                      MpStoreTile(
                        name: t.name,
                        monogram: t.monogram,
                        local: true,
                        nameScale: fit.nameScale,
                        selected: draft.isStoreSelected(t.id),
                        onTap: () => draft.toggleStore(t.id),
                      ),
                  ]),
                ],
              );
            }),
          ],
          footer: Column(
            children: [
              MpCta(
                label: 'Build my plan ($count)',
                onPressed: count > 0 ? onNext : null,
              ),
              if (count == 0)
                const MpCtaNote('Pick at least one store to build a plan.'),
            ],
          ),
        );
      },
    );
  }
}
