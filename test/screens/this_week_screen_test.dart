import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/data/sample_week.dart';
import 'package:mealpal_ph/screens/this_week_screen.dart';
import 'package:mealpal_ph/state/plan_draft.dart';

import '../helpers.dart';

void main() {
  late PlanDraft draft;
  var groceries = 0;
  var retries = 0;

  Future<void> pump(
    WidgetTester tester, {
    PlanStatus status = PlanStatus.ready,
  }) async {
    await phone(tester);
    draft = PlanDraft();
    groceries = 0;
    retries = 0;
    await tester.pumpWidget(
      host(ThisWeekScreen(
        draft: draft,
        week: sampleWeek(),
        status: status,
        onGrocery: () => groceries++,
        onRetry: () => retries++,
      )),
    );
    // The building state spins forever, so it can never settle.
    if (status == PlanStatus.building) {
      await tester.pump(const Duration(seconds: 1));
    } else {
      await tester.pumpAndSettle();
    }
  }

  testWidgets('shows the header pills, day strip and Monday meals',
      (tester) async {
    await pump(tester);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('2,087 kcal/day'), findsOneWidget);
    expect(find.text('≤ ₱2,500'), findsOneWidget);
    expect(find.text('Grocery list'), findsOneWidget);
    expect(find.text('New'), findsNothing);
    for (final d in ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']) {
      expect(find.text(d), findsOneWidget, reason: d);
    }
    expect(find.text('Monday · 2,087 kcal · ₱250'), findsOneWidget);
    expect(find.text('BREAKFAST'), findsOneWidget);
    expect(find.text('Tapsilog: beef tapa, garlic rice and egg'), findsOneWidget);
    expect(find.text('560 kcal · ₱95'), findsOneWidget);
    expect(find.text('LUNCH'), findsOneWidget);
    expect(find.text('DINNER'), findsOneWidget);
    expect(find.text('SNACK'), findsOneWidget);
    expect(find.text('See grocery list'), findsOneWidget);
  });

  testWidgets('selecting a day swaps the summary and meals', (tester) async {
    await pump(tester);
    await tester.tap(find.text('TUE'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tuesday · '), findsOneWidget);
    expect(find.text('Monday · 2,087 kcal · ₱250'), findsNothing);
  });

  testWidgets('swapping a meal replaces it and re-totals the day',
      (tester) async {
    await pump(tester);
    await tester.tap(find.bySemanticsLabel('Swap meal').first);
    await tester.pumpAndSettle();
    expect(find.text('Daingsilog: fried milkfish, garlic rice and egg'),
        findsOneWidget);
    expect(find.text('Tapsilog: beef tapa, garlic rice and egg'), findsNothing);
    expect(find.text('Monday · 2,067 kcal · ₱235'), findsOneWidget);
    // The swap belongs to Monday only.
    await tester.tap(find.text('THU'));
    await tester.pumpAndSettle();
    expect(find.text('Tapsilog: beef tapa, garlic rice and egg'), findsOneWidget);
  });

  testWidgets('swapping again moves on from the meal now showing',
      (tester) async {
    await pump(tester);
    final swap = find.bySemanticsLabel('Swap meal').first;
    await tester.tap(swap);
    await tester.pumpAndSettle();
    expect(find.text('Daingsilog: fried milkfish, garlic rice and egg'),
        findsOneWidget);
    await tester.tap(swap);
    await tester.pumpAndSettle();
    expect(find.text('Lugaw with egg and toasted garlic'), findsOneWidget);
    expect(find.text('Monday · 1,947 kcal · ₱190'), findsOneWidget);
    await tester.tap(swap);
    await tester.pumpAndSettle();
    expect(find.text('Tapsilog: beef tapa, garlic rice and egg'), findsOneWidget);
    expect(find.text('Monday · 2,087 kcal · ₱250'), findsOneWidget);
  });

  testWidgets('a swap survives visiting another day', (tester) async {
    await pump(tester);
    await tester.tap(find.bySemanticsLabel('Swap meal').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('TUE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MON'));
    await tester.pumpAndSettle();
    expect(find.text('Daingsilog: fried milkfish, garlic rice and egg'),
        findsOneWidget);
    expect(find.text('Monday · 2,067 kcal · ₱235'), findsOneWidget);
  });

  testWidgets('both grocery entry points fire the callback', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Grocery list'));
    await tester.tap(find.text('See grocery list'));
    await tester.pumpAndSettle();
    expect(groceries, 2);
  });

  testWidgets('while the plan is building it says so and hides the meals',
      (tester) async {
    await pump(tester, status: PlanStatus.building);
    expect(find.text('Building your week'), findsOneWidget);
    expect(
      find.text('Matching meals to your 2,087 kcal target and ₱2,500 weekly '
          'budget from the stores you picked.'),
      findsOneWidget,
    );
    expect(find.text('BREAKFAST'), findsNothing);
    expect(find.text('See grocery list'), findsNothing);
    expect(find.text('Grocery list'), findsNothing);
  });

  testWidgets('a failed build explains itself and can be retried',
      (tester) async {
    await pump(tester, status: PlanStatus.failed);
    expect(find.text("We couldn't build your week."), findsOneWidget);
    expect(
      find.text('Your stats and stores are saved. Check your connection and '
          'try again.'),
      findsOneWidget,
    );
    expect(find.text('BREAKFAST'), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(retries, 1);
  });
}
