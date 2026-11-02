import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/data/sample_week.dart';
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
}
