import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design_system/design_system.dart';
import '../../mealpal_ph.dart';
import '../core/mp_card.dart';
import '../core/mp_press.dart';

/// One meal in the day's plan: 54px photo thumbnail (or a tinted initial
/// when the bank has no photo), uppercase slot label, dish name, "kcal · ₱",
/// and a square swap button that spins half a turn when pressed.
class MpMealCard extends StatefulWidget {
  const MpMealCard({super.key, required this.meal, required this.onSwap});

  final PlannedMeal meal;
  final VoidCallback onSwap;

  static MpAccent accentFor(MealSlot slot) => switch (slot) {
        MealSlot.breakfast => MpAccent.annatto,
        MealSlot.lunch || MealSlot.dinner => MpAccent.green,
        MealSlot.snack => MpAccent.amber,
      };

  @override
  State<MpMealCard> createState() => _MpMealCardState();
}

class _MpMealCardState extends State<MpMealCard> {
  int _spins = 0;

  void _swap() {
    setState(() => _spins++);
    widget.onSwap();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final meal = widget.meal;
    final accent = MpMealCard.accentFor(meal.slot);
    return MpCard(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(MpRadius.thumb),
            child: Container(
              width: MpSize.thumb,
              height: MpSize.thumb,
              color: accent.tint(c),
              alignment: Alignment.center,
              child: meal.image == null
                  ? Text(
                      meal.name.substring(0, 1),
                      style: MpTypography.monogram().copyWith(
                        fontSize: 20,
                        color: accent.deep(c),
                      ),
                    )
                  : Image.asset(
                      'assets/images/meals/${meal.image}.jpg',
                      fit: BoxFit.cover,
                      width: MpSize.thumb,
                      height: MpSize.thumb,
                    ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.slot.label.toUpperCase(),
                  style: MpTypography.slotLabel().copyWith(color: c.annatto),
                ),
                const SizedBox(height: 2),
                Text(
                  meal.name,
                  style: MpTypography.bodyStrong().copyWith(color: c.ink),
                ),
                const SizedBox(height: 3),
                Text(
                  '${meal.kcal} kcal · ${formatPeso(meal.pricePhp, decimals: 0)}',
                  style: MpTypography.smallStrong().copyWith(color: c.faint),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          MpPress(
            onTap: _swap,
            semanticLabel: 'Swap meal',
            child: Container(
              width: MpSize.swap,
              height: MpSize.swap,
              decoration: BoxDecoration(
                color: c.cream,
                borderRadius: BorderRadius.circular(MpRadius.swap),
                border: Border.all(color: c.hairline),
              ),
              child: AnimatedRotation(
                turns: _spins / 2,
                duration: MpMotion.of(context, MpMotion.slide),
                curve: MpMotion.ease,
                child: Icon(LucideIcons.repeat, size: 18, color: c.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seven-day strip. The selected day sits in a dark rounded block that
/// slides across when another day is tapped.
class MpDayStrip extends StatelessWidget {
  const MpDayStrip({
    super.key,
    required this.days,
    required this.dayNumbers,
    required this.selected,
    required this.onSelect,
  });

  final List<Weekday> days;
  final List<int> dayNumbers;
  final int selected;
  final ValueChanged<int> onSelect;

  static const double _gap = 5;
  static const double _height = 52;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = days.length;
        final cell = (constraints.maxWidth - _gap * (n - 1)) / n;
        return SizedBox(
          height: _height,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: MpMotion.of(context, MpMotion.slide),
                curve: MpMotion.ease,
                left: selected * (cell + _gap),
                top: 0,
                width: cell,
                height: _height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.heroSurface,
                    borderRadius: BorderRadius.circular(MpRadius.segment),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < n; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelect(i),
                        child: SizedBox(
                          height: _height,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration:
                                    MpMotion.of(context, MpMotion.select),
                                style: MpTypography.dayName().copyWith(
                                  color: (i == selected ? c.heroText : c.muted)
                                      .withValues(alpha: 0.7),
                                ),
                                child: Text(days[i].short.toUpperCase()),
                              ),
                              const SizedBox(height: 3),
                              AnimatedDefaultTextStyle(
                                duration:
                                    MpMotion.of(context, MpMotion.select),
                                style: MpTypography.dayNumber().copyWith(
                                  color: i == selected ? c.heroText : c.muted,
                                ),
                                child: Text('${dayNumbers[i]}'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
