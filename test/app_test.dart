import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/app.dart';
import 'package:mealpal_ph/screens/grocery_list_screen.dart';
import 'package:mealpal_ph/data/sample_planner.dart';
import 'package:mealpal_ph/mealpal_ph.dart';

import 'helpers.dart';

void main() {
  testWidgets('walks the whole flow and carries the budget through', (
    tester,
  ) async {
    await phone(tester);
    await tester.pumpWidget(const MealPalApp());
    await tester.pumpAndSettle();

    expect(find.text('Find my calorie target'), findsOneWidget);
    await tester.tap(find.text('Find my calorie target'));
    await tester.pumpAndSettle();

    expect(find.text('Tell us about you'), findsOneWidget);
    await tester.tap(find.text('Compute my target'));
    await tester.pumpAndSettle();

    expect(find.text('Your daily target'), findsOneWidget);
    await tester.tap(find.text('Next: where you shop'));
    await tester.pumpAndSettle();

    expect(find.text('Where do you shop?'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Increase budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build my plan (2)'));
    await tester.pumpAndSettle();

    expect(find.text('This week'), findsOneWidget);
    expect(find.text('≤ ₱2,600'), findsOneWidget);
    await tester.tap(find.text('See grocery list'));
    await tester.pumpAndSettle();

    expect(find.text('Grocery list'), findsOneWidget);
    expect(find.text(groceryListNote), findsOneWidget);
    expect(find.text(' / ₱2,600'), findsOneWidget);
    await tester.tap(find.text('THIS WEEK'));
    await tester.pumpAndSettle();
    expect(find.text('This week'), findsOneWidget);
  });

  testWidgets('every screen has an on-screen way back', (tester) async {
    await phone(tester);
    await tester.pumpWidget(const MealPalApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Find my calorie target'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('STEP 1 OF 4'));
    await tester.pumpAndSettle();
    expect(find.text('Find my calorie target'), findsOneWidget);

    await tester.tap(find.text('Find my calorie target'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compute my target'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next: where you shop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build my plan (2)'));
    await tester.pumpAndSettle();
    expect(find.text('This week'), findsOneWidget);
    await tester.tap(find.text('STORES'));
    await tester.pumpAndSettle();
    expect(find.text('Where do you shop?'), findsOneWidget);
  });

  testWidgets('an emptied field stays empty after going back and returning', (
    tester,
  ) async {
    await phone(tester);
    await tester.pumpWidget(const MealPalApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find my calorie target'));
    await tester.pumpAndSettle();

    // Backspacing 74 a digit at a time writes 7, then empties the field.
    const weight = ValueKey('field-weight');
    await tester.enterText(find.byKey(weight), '7');
    await tester.enterText(find.byKey(weight), '');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Find my calorie target'), findsOneWidget);

    await tester.tap(find.text('Find my calorie target'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(weight)).controller!.text, '');
    expect(
      find.text('Fill in age, height and weight to continue.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Compute my target'));
    await tester.pumpAndSettle();
    expect(find.text('Your daily target'), findsNothing);
  });

  group('planner choice', () {
    test('a release build refuses a server URL that is not https', () {
      expect(
        () => plannerFor(
          serverUrl: 'http://192.168.42.202:8090',
          appKey: 'k',
          release: true,
        ),
        throwsArgumentError,
      );
      expect(
        plannerFor(serverUrl: 'https://x.run.app', release: true),
        isA<HttpPlanner>(),
      );
      expect(plannerFor(serverUrl: '', release: true), isA<SamplePlanner>());
      expect(
        plannerFor(serverUrl: 'http://192.168.42.202:8090', release: false),
        isA<HttpPlanner>(),
      );
    });

    test('no server URL means the local sample bank', () {
      expect(plannerFor(serverUrl: ''), isA<SamplePlanner>());
    });

    test('a server URL means the HTTP planner, with or without a key', () {
      expect(
        plannerFor(serverUrl: 'http://192.168.42.202:8090'),
        isA<HttpPlanner>(),
      );
      expect(
        plannerFor(serverUrl: 'https://x.run.app/', appKey: 'k'),
        isA<HttpPlanner>(),
      );
    });
  });

  group('the grocery list follows the planned week', () {
    Future<void> toWeek(WidgetTester tester, Planner planner) async {
      await phone(tester);
      await tester.pumpWidget(MealPalApp(planner: planner));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Find my calorie target'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compute my target'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next: where you shop'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Build my plan (2)'));
      await tester.pumpAndSettle();
    }

    Future<void> openList(WidgetTester tester) async {
      await tester.tap(find.text('See grocery list'));
      await tester.pumpAndSettle();
    }

    /// Every visible string on the list, scrolled or not.
    Set<String> listTexts(WidgetTester tester) => {
      for (final t in tester.widgetList<Text>(
        find.byType(Text, skipOffstage: false),
      ))
        if (t.data != null) t.data!,
    };

    testWidgets('sample mode lists the planned meals under the picked stores', (
      tester,
    ) async {
      await toWeek(tester, SamplePlanner());
      await openList(tester);
      expect(find.text('Grocery list'), findsOneWidget);
      expect(find.text(groceryListNote), findsOneWidget);
      // Puregold and the wet market are the default picks, in that order of
      // type rank: wet market first.
      final wet = tester.getTopLeft(find.text('Wet market')).dy;
      final puregold = tester.getTopLeft(find.text('Puregold')).dy;
      expect(wet, lessThan(puregold));
      expect(find.text('Corner store'), findsNothing);
      expect(find.text('Elsewhere'), findsNothing);
      final texts = listTexts(tester);
      expect(texts, contains('Beef tapa cut'));
      expect(texts, contains('White rice'));
      expect(find.text('Nothing to buy yet'), findsNothing);
    });

    testWidgets('swapping a meal changes the list the next time it opens', (
      tester,
    ) async {
      await toWeek(tester, SamplePlanner());
      await openList(tester);
      final before = listTexts(tester);
      await tester.tap(find.text('THIS WEEK'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Swap breakfast'));
      await tester.pumpAndSettle();
      await openList(tester);
      final after = listTexts(tester);
      expect(after, isNot(equals(before)));
    });

    testWidgets('a server plan with ingredients drives the same list', (
      tester,
    ) async {
      await toWeek(tester, _IngredientPlanner());
      await openList(tester);
      expect(find.text(groceryListNote), findsOneWidget);
      expect(find.text('Wet market'), findsOneWidget);
      expect(find.text('Puregold'), findsOneWidget);
      final texts = listTexts(tester);
      expect(texts, contains('Pork belly'));
      expect(texts, contains('Jasmine rice'));
      // 2 x 200 g of pork, 2 x 90 g of rice, both rounded up to 5 g.
      expect(texts, contains('400 g'));
      expect(texts, contains('180 g'));
    });

    testWidgets('an older server that sends no ingredients says so, not that '
        'there is no plan', (tester) async {
      await toWeek(tester, _IngredientPlanner(withIngredients: false));
      await openList(tester);
      expect(find.text('Grocery list'), findsOneWidget);
      expect(find.text('Nothing to buy yet'), findsNothing);
      expect(find.text('No ingredients for this plan'), findsOneWidget);
      expect(find.textContaining('Update the server'), findsOneWidget);
    });
  });

  group('the plan follows the brief', () {
    Future<void> toStores(WidgetTester tester) async {
      await phone(tester);
      await tester.pumpWidget(MealPalApp(planner: _counting));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Find my calorie target'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compute my target'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next: where you shop'));
      await tester.pumpAndSettle();
    }

    setUp(() => _counting = _CountingPlanner());

    testWidgets('building shows while the planner works, then the week', (
      tester,
    ) async {
      _counting.hold = true;
      await toStores(tester);
      await tester.tap(find.text('Build my plan (2)'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Building your week'), findsOneWidget);
      expect(find.text('BREAKFAST'), findsNothing);
      _counting.release();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('BREAKFAST'), findsOneWidget);
    });

    testWidgets('a plan from the sample planner shows the grocery note', (
      tester,
    ) async {
      await toStores(tester);
      await tester.tap(find.text('Build my plan (2)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('See grocery list'));
      await tester.pumpAndSettle();
      expect(find.text(groceryListNote), findsOneWidget);
    });

    testWidgets('going back and forward with the same choices keeps the plan', (
      tester,
    ) async {
      await toStores(tester);
      await tester.tap(find.text('Build my plan (2)'));
      await tester.pumpAndSettle();
      expect(_counting.starts, 1);
      await tester.tap(find.text('STORES'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Build my plan (2)'));
      await tester.pumpAndSettle();
      expect(_counting.starts, 1);
    });

    testWidgets('changing the budget on the way back builds a new plan', (
      tester,
    ) async {
      await toStores(tester);
      await tester.tap(find.text('Build my plan (2)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('STORES'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Increase budget'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Build my plan (2)'));
      await tester.pumpAndSettle();
      expect(_counting.starts, 2);
      expect(_counting.briefs.last.budgetPhp, 2600);
      expect(find.text('≤ ₱2,600'), findsOneWidget);
    });
  });
}

late _CountingPlanner _counting;

/// The sample planner, counting starts and optionally holding them back.
class _CountingPlanner implements Planner {
  final _inner = SamplePlanner();
  final briefs = <PlanBrief>[];
  Completer<void>? _gate;
  set hold(bool v) => _gate = v ? Completer<void>() : null;

  int get starts => briefs.length;

  void release() => _gate!.complete();

  @override
  Future<PlanSnapshot> start(PlanBrief brief) async {
    briefs.add(brief);
    await _gate?.future;
    return _inner.start(brief);
  }

  @override
  Future<PlanSnapshot> fetch(String id) => _inner.fetch(id);

  @override
  Future<PlanSnapshot> swap(
    String id,
    Weekday day,
    MealSlot slot, {
    String? note,
  }) => _inner.swap(id, day, slot, note: note);
}

/// A server-style plan: two days, each with the same two ingredients.
class _IngredientPlanner implements Planner {
  _IngredientPlanner({this.withIngredients = true});

  final bool withIngredients;

  static const _pork = MealIngredient(
    id: 'pork',
    name: 'Pork belly',
    kind: GroceryKind.meat,
    unit: IngredientUnit.g,
    qty: 200,
    pricePhp: 66,
  );
  static const _rice = MealIngredient(
    id: 'rice',
    name: 'Jasmine rice',
    kind: GroceryKind.grain,
    unit: IngredientUnit.g,
    qty: 90,
    pricePhp: 4.5,
  );

  PlanSnapshot _snapshot() => PlanSnapshot(
    id: 'p1',
    status: PlanStatus.ready,
    week: [
      for (final d in [Weekday.mon, Weekday.tue])
        DayPlan(
          weekday: d,
          meals: [
            PlannedMeal(
              slot: MealSlot.lunch,
              name: 'Pork and rice',
              kcal: 700,
              pricePhp: 71,
              ingredients: withIngredients ? [_pork, _rice] : [],
            ),
          ],
        ),
    ],
  );

  @override
  Future<PlanSnapshot> start(PlanBrief brief) async => _snapshot();

  @override
  Future<PlanSnapshot> fetch(String id) async => _snapshot();

  @override
  Future<PlanSnapshot> swap(
    String id,
    Weekday day,
    MealSlot slot, {
    String? note,
  }) async => _snapshot();
}
