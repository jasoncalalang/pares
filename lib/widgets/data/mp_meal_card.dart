import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design_system/design_system.dart';
import '../../mealpal_ph.dart';
import '../core/mp_card.dart';
import '../core/mp_press.dart';

/// One meal in the day's plan: 54px photo thumbnail (or a tinted initial
/// when the bank has no photo), uppercase slot label, dish name, "kcal · ₱",
/// and a square swap button that spins half a turn when pressed.
///
/// At 150% text and up the thumbnail steps aside, so long dish names keep
/// the width they need and no word breaks in two. When a name's longest word
/// still does not fit the room left (the largest sizes, a 320dp phone), the
/// name alone shrinks, by no more than [_DishName.minScale], until it does.
///
/// While [swapping] the card keeps showing the current dish, says "Swapping
/// this meal" in place of the kcal line (announced to screen readers) and
/// shows a spinner in the button. A null [onSwap] disables the button.
class MpMealCard extends StatefulWidget {
  const MpMealCard({
    super.key,
    required this.meal,
    required this.onSwap,
    this.swapping = false,
  });

  final PlannedMeal meal;
  final VoidCallback? onSwap;
  final bool swapping;

  static MpAccent accentFor(MealSlot slot) => switch (slot) {
    // Meals are annatto (DESIGN.md); green is for local stores, budget and
    // protein, so a dinner with no photo does not borrow it.
    MealSlot.breakfast ||
    MealSlot.lunch ||
    MealSlot.dinner => MpAccent.annatto,
    MealSlot.snack => MpAccent.amber,
  };

  @override
  State<MpMealCard> createState() => _MpMealCardState();
}

/// "2 servings · " when the numbers cover other than one portion.
String _servingsPrefix(double servings) {
  if (servings == 1) return '';
  final n = servings == servings.roundToDouble()
      ? servings.round().toString()
      : servings.toString();
  return '$n servings · ';
}

/// What a screen reader says for the card: "Breakfast, Tapsilog, 797 kcal,
/// ₱84", with the servings before the numbers, or "Swapping this meal" in
/// their place while a swap builds.
String _spoken(PlannedMeal meal, {required bool swapping}) {
  final head = '${meal.slot.label}, ${meal.name}';
  if (swapping) return '$head, Swapping this meal';
  final servings = meal.servings == 1
      ? ''
      : '${_servingsPrefix(meal.servings).replaceAll(' · ', '')}, ';
  return '$head, $servings${meal.kcal} kcal, '
      '${formatPeso(meal.pricePhp, decimals: 0)}';
}

/// The dish name, shrunk just enough that its longest word fits the width it
/// is given, so no word breaks in two. Bold, the weight it is drawn in.
class _DishName extends StatelessWidget {
  const _DishName({required this.name, required this.color});

  final String name;
  final Color color;

  /// The least a name may shrink to, as a share of the person's text size.
  static const double minScale = 0.6;

  /// The widest word of [name] at [scaler], in pixels.
  static double _widest(String name, TextStyle style, TextScaler scaler) {
    var widest = 0.0;
    for (final word in name.split(' ')) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    return widest;
  }

  @override
  Widget build(BuildContext context) {
    final style = MpTypography.bodyStrong().copyWith(color: color);
    // What the Text really draws: its style on top of the inherited one
    // (the theme adds letter spacing), so the measure matches the paint.
    final drawn = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final wanted = scaler.scale(1);
        final floor = wanted * minScale;
        var scale = wanted;
        var widest = _widest(name, drawn, scaler);
        // Glyph advances do not scale exactly with the size, so measure at
        // each step, with the clamped scaler the text will use, instead of
        // trusting the ratio; a few steps converge.
        for (var i = 0; i < 8 && widest > box.maxWidth && scale > floor; i++) {
          scale = math.max(floor, scale * box.maxWidth / widest * 0.98);
          widest = _widest(name, drawn, scaler.clamp(maxScaleFactor: scale));
        }
        final text = Text(name, style: style);
        if (scale >= wanted) return text;
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: scale,
          child: text,
        );
      },
    );
  }
}

class _MpMealCardState extends State<MpMealCard> {
  int _spins = 0;

  void _swap() {
    setState(() => _spins++);
    widget.onSwap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final meal = widget.meal;
    final accent = MpMealCard.accentFor(meal.slot);
    final bigText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return MpCard(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          if (!bigText) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(MpRadius.thumb),
              child: Container(
                width: MpSize.thumb,
                height: MpSize.thumb,
                color: accent.tint(c),
                alignment: Alignment.center,
                child: meal.image == null
                    // Decorative: the dish name is read in full beside it.
                    ? ExcludeSemantics(
                        child: Text(
                          meal.name.substring(0, 1),
                          style: MpTypography.monogram().copyWith(
                            fontSize: 20,
                            color: accent.deep(c),
                          ),
                        ),
                      )
                    : Image.asset(
                        'assets/images/meals/${meal.image}.jpg',
                        // Decorative, like the initial: the dish name is
                        // read in full beside it.
                        excludeFromSemantics: true,
                        fit: BoxFit.cover,
                        width: MpSize.thumb,
                        height: MpSize.thumb,
                      ),
              ),
            ),
            const SizedBox(width: 13),
          ],
          Expanded(
            // One node for slot, dish and numbers, so they are read together
            // rather than as three fragments sorted by position. A live
            // region, so a swap reads out the new dish.
            child: Semantics(
              container: true,
              liveRegion: true,
              label: _spoken(meal, swapping: widget.swapping),
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.slot.label.toUpperCase(),
                      style: MpTypography.slotLabel().copyWith(
                        color: c.annatto,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _DishName(name: meal.name, color: c.ink),
                    const SizedBox(height: 3),
                    Text(
                      widget.swapping
                          ? 'Swapping this meal'
                          : '${_servingsPrefix(meal.servings)}${meal.kcal} '
                                'kcal · '
                                '${formatPeso(meal.pricePhp, decimals: 0)}',
                      style: MpTypography.smallStrong().copyWith(
                        color: widget.swapping ? c.annattoDeep : c.faint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          MpPress(
            // A card in flight keeps a live (inert) button so focus stays on it.
            onTap: widget.onSwap == null
                ? null
                : widget.swapping
                ? () {}
                : _swap,
            semanticLabel: 'Swap ${meal.slot.label.toLowerCase()}',
            focusRadius: MpRadius.swap,
            child: Container(
              width: MpSize.swap,
              height: MpSize.swap,
              // Disabled (another meal is swapping) takes the disabled CTA's
              // look, hairline fill and no control outline, so it is not
              // told apart by the announcement alone.
              decoration: BoxDecoration(
                color: widget.onSwap == null ? c.hairline : c.paper,
                borderRadius: BorderRadius.circular(MpRadius.swap),
                border: Border.all(
                  color: widget.onSwap == null ? c.hairline : c.outline,
                ),
              ),
              alignment: Alignment.center,
              child: widget.swapping
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.annatto,
                      ),
                    )
                  : AnimatedRotation(
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
        // Narrow phones give up gap before a day drops under MpSize.tap.
        // Below 352dp even that is not enough: at 320dp a day is 39px wide
        // (and 52 tall). Owner decision, 2026-11-13: keep the whole week in
        // view there instead of scrolling the strip.
        final spare = (constraints.maxWidth - n * MpSize.tap) / (n - 1);
        final gap = spare.clamp(0.0, _gap);
        final cell = (constraints.maxWidth - gap * (n - 1)) / n;
        // At least 52px tall, growing with large text.
        return IntrinsicHeight(
          child: Stack(
            // The focus ring is drawn round each day, outside its cell.
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: MpMotion.of(context, MpMotion.slide),
                curve: MpMotion.ease,
                left: selected * (cell + gap),
                top: 0,
                bottom: 0,
                width: cell,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.heroSurface,
                    borderRadius: BorderRadius.circular(MpRadius.segment),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < n; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    Expanded(
                      child: MpPress(
                        onTap: () => onSelect(i),
                        semanticLabel: '${days[i].label} ${dayNumbers[i]}',
                        selected: i == selected,
                        scale: 1,
                        focusRadius: MpRadius.segment,
                        // The label above says the day once, in full.
                        child: ExcludeSemantics(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: _height,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: MpMotion.of(
                                    context,
                                    MpMotion.select,
                                  ),
                                  style: MpTypography.dayName().copyWith(
                                    // faint, not dimmed muted: 10px names
                                    // need 4.5:1 on the page.
                                    color: i == selected
                                        ? c.heroMuted
                                        : c.faint,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(days[i].short.toUpperCase()),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                AnimatedDefaultTextStyle(
                                  duration: MpMotion.of(
                                    context,
                                    MpMotion.select,
                                  ),
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
