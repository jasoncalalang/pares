import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/data/sample_week.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:mealpal_ph/widgets/widgets.dart';

import '../helpers.dart';

void main() {
  final meal = sampleWeek().first.meals.first;

  Future<void> pump(WidgetTester tester, Widget card) async {
    await phone(tester);
    await tester.pumpWidget(
      host(Padding(padding: const EdgeInsets.all(16), child: card)),
    );
    await tester.pump();
  }

  testWidgets('a swapping card says so and its swap button is disabled', (
    tester,
  ) async {
    var swaps = 0;
    await pump(
      tester,
      MpMealCard(meal: meal, swapping: true, onSwap: () => swaps++),
    );
    expect(find.text('Swapping this meal'), findsOneWidget);
    expect(find.text('560 kcal · ₱95'), findsNothing);
    // The old dish stays readable while the swap builds.
    expect(find.text(meal.name), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Swap breakfast'));
    await tester.pump();
    expect(swaps, 0);
  });

  testWidgets('a null onSwap disables the button and keeps the kcal line', (
    tester,
  ) async {
    await pump(tester, MpMealCard(meal: meal, onSwap: null));
    expect(find.text('560 kcal · ₱95'), findsOneWidget);
    expect(find.text('Swapping this meal'), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Swap breakfast')),
      isSemantics(isButton: true, isEnabled: false, hasEnabledState: true),
    );
  });

  testWidgets('an idle card swaps as before', (tester) async {
    var swaps = 0;
    await pump(tester, MpMealCard(meal: meal, onSwap: () => swaps++));
    await tester.tap(find.bySemanticsLabel('Swap breakfast'));
    await tester.pump();
    expect(swaps, 1);
  });

  testWidgets('a meal with other than one serving says how many', (
    tester,
  ) async {
    const two = PlannedMeal(
      slot: MealSlot.lunch,
      name: 'Tapsilog',
      kcal: 1120,
      pricePhp: 190,
      servings: 2,
    );
    await pump(tester, MpMealCard(meal: two, onSwap: () {}));
    expect(find.text('2 servings · 1120 kcal · ₱190'), findsOneWidget);
    const half = PlannedMeal(
      slot: MealSlot.lunch,
      name: 'Tapsilog',
      kcal: 280,
      pricePhp: 48,
      servings: 0.5,
    );
    await pump(tester, MpMealCard(meal: half, onSwap: () {}));
    expect(find.text('0.5 servings · 280 kcal · ₱48'), findsOneWidget);
  });

  testWidgets('one serving stays unsaid', (tester) async {
    await pump(tester, MpMealCard(meal: meal, onSwap: () {}));
    expect(find.textContaining('serving'), findsNothing);
  });

  group('screen reader', () {
    testWidgets('slot, dish and numbers are one live node; swap stays apart', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, MpMealCard(meal: meal, onSwap: () {}));
      final card = find.bySemanticsLabel(
        'Breakfast, Tapsilog: beef tapa, garlic rice and egg, 560 kcal, ₱95',
      );
      expect(card, findsOneWidget);
      expect(
        tester.getSemantics(card),
        isSemantics(
          label:
              'Breakfast, Tapsilog: beef tapa, garlic rice and egg, 560 kcal, ₱95',
          isLiveRegion: true,
        ),
      );
      expect(find.bySemanticsLabel('Swap breakfast'), findsOneWidget);
      expect(find.bySemanticsLabel('BREAKFAST'), findsNothing);
      expect(find.bySemanticsLabel('560 kcal · ₱95'), findsNothing);
      handle.dispose();
    });

    testWidgets('servings and swapping are spoken in the same node', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      const two = PlannedMeal(
        slot: MealSlot.lunch,
        name: 'Tinola',
        kcal: 1120,
        pricePhp: 190,
        servings: 2,
      );
      await pump(tester, MpMealCard(meal: two, onSwap: () {}));
      expect(
        find.bySemanticsLabel('Lunch, Tinola, 2 servings, 1120 kcal, ₱190'),
        findsOneWidget,
      );
      await pump(tester, MpMealCard(meal: two, swapping: true, onSwap: () {}));
      expect(
        find.bySemanticsLabel('Lunch, Tinola, Swapping this meal'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('the monogram of a photoless meal is not read', (tester) async {
      final handle = tester.ensureSemantics();
      const adobo = PlannedMeal(
        slot: MealSlot.dinner,
        name: 'Chicken adobo',
        kcal: 500,
        pricePhp: 80,
      );
      await pump(tester, MpMealCard(meal: adobo, onSwap: () {}));
      expect(find.text('C'), findsOneWidget);
      expect(find.bySemanticsLabel('C'), findsNothing);
      handle.dispose();
    });
  });
}
