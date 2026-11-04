import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/data/sample_planner.dart';
import 'package:mealpal_ph/data/sample_week.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:mealpal_ph/data/store_tiles.dart';
import 'package:mealpal_ph/design_system/design_system.dart';
import 'package:mealpal_ph/screens/daily_target_screen.dart';
import 'package:mealpal_ph/screens/grocery_list_screen.dart';
import 'package:mealpal_ph/screens/this_week_screen.dart';
import 'package:mealpal_ph/screens/welcome_screen.dart';
import 'package:mealpal_ph/screens/where_you_shop_screen.dart';
import 'package:mealpal_ph/state/plan_draft.dart';
import 'package:mealpal_ph/state/week_plan_controller.dart';
import 'package:mealpal_ph/widgets/widgets.dart';

import '../helpers.dart';

/// Screens at the text sizes people set on their phones. The real fonts
/// are loaded by flutter_test_config.dart, so wrapping here is where
/// Fraunces and Plus Jakarta Sans actually wrap.
void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    Widget screen, {
    required double scale,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(host(screen));
    await tester.pumpAndSettle();
  }

  RenderParagraph paragraph(WidgetTester tester, Finder f) =>
      tester.renderObject<RenderParagraph>(f);

  /// How many lines [text] (the whole of [f]'s text, or a slice) takes.
  int lines(WidgetTester tester, Finder f, [int start = 0, int? end]) {
    final p = paragraph(tester, f);
    final boxes = p.getBoxesForSelection(
      TextSelection(
        baseOffset: start,
        extentOffset: end ?? p.text.toPlainText().length,
      ),
    );
    return boxes.map((b) => b.top.round()).toSet().length;
  }

  /// No word of [f]'s text is broken across two lines.
  void expectWholeWords(WidgetTester tester, Finder f, {String? reason}) {
    final text = paragraph(tester, f).text.toPlainText();
    for (final m in RegExp(r'\S+').allMatches(text)) {
      expect(
        lines(tester, f, m.start, m.end),
        1,
        reason: '${reason ?? text}: "${m.group(0)}" breaks mid-word',
      );
    }
    expect(
      paragraph(tester, f).didExceedMaxLines,
      isFalse,
      reason: '${reason ?? text} is cut off',
    );
  }

  for (final scale in [1.5, 2.0]) {
    testWidgets('Daily target keeps its number whole at ${scale}x', (
      tester,
    ) async {
      await pumpAt(
        tester,
        DailyTargetScreen(draft: PlanDraft(), onNext: () {}),
        scale: scale,
      );
      expect(tester.takeException(), isNull);
      final numbers = find.text('2,087');
      expect(numbers, findsOneWidget);
      expect(lines(tester, numbers), 1);
    });
  }

  // The centre text must clear the stroke: every corner of each line sits
  // inside the ring's inner circle with a little air, not merely inside the
  // ring's square bounding box (a wide caption there touches the stroke).
  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('Daily target ring centre clears the stroke at ${scale}x', (
      tester,
    ) async {
      await pumpAt(
        tester,
        DailyTargetScreen(draft: PlanDraft(), onNext: () {}),
        scale: scale,
      );
      expect(tester.takeException(), isNull);
      final ring = tester.getRect(find.byType(MpCalorieRing));
      final inner = ring.width / 2 - MpSize.ringStroke - MpSize.ringStroke / 2;
      for (final f in [find.text('81%'), find.text('OF MAINTENANCE')]) {
        expect(lines(tester, f), 1);
        expectWholeWords(tester, f);
        final r = tester.getRect(f);
        for (final corner in [
          r.topLeft,
          r.topRight,
          r.bottomLeft,
          r.bottomRight,
        ]) {
          expect(
            (corner - ring.center).distance,
            lessThanOrEqualTo(inner),
            reason: '$f corner $corner',
          );
        }
      }
    });
  }

  testWidgets('step header with its back arrow keeps its words whole at 2x', (
    tester,
  ) async {
    await pumpAt(
      tester,
      WhereYouShopScreen(draft: PlanDraft(), onNext: () {}, onBack: () {}),
      scale: 2.0,
      size: const Size(360, 844),
    );
    expect(tester.takeException(), isNull);
    expectWholeWords(tester, find.text('STEP 3 OF 4'));
  });

  testWidgets('Daily target goal buttons hold their labels at 2x on 360dp', (
    tester,
  ) async {
    await pumpAt(
      tester,
      DailyTargetScreen(draft: PlanDraft(), onNext: () {}),
      scale: 2.0,
      size: const Size(360, 844),
    );
    expect(tester.takeException(), isNull);
    for (final goal in ['Lose', 'Maintain', 'Gain']) {
      await tester.ensureVisible(find.text(goal));
      expectWholeWords(tester, find.text(goal));
    }
  });

  testWidgets('This week day strip grows with 2x text', (tester) async {
    final plan = WeekPlanController(SamplePlanner());
    addTearDown(plan.dispose);
    final draft = PlanDraft();
    plan.build(draft.brief);
    await pumpAt(
      tester,
      ThisWeekScreen(draft: draft, controller: plan, onGrocery: () {}),
      scale: 2.0,
    );
    expect(tester.takeException(), isNull);
    for (final d in ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']) {
      expect(lines(tester, find.text(d)), 1, reason: d);
    }
  });

  testWidgets('This week capped target pill and estimates line fit at 2x', (
    tester,
  ) async {
    final plan = WeekPlanController(SamplePlanner());
    addTearDown(plan.dispose);
    final draft = PlanDraft()
      ..weightKg = 150
      ..heightCm = 190
      ..age = 20
      ..activity = ActivityLevel.active
      ..goal = Goal.gain;
    plan.build(draft.brief);
    await pumpAt(
      tester,
      ThisWeekScreen(draft: draft, controller: plan, onGrocery: () {}),
      scale: 2.0,
      size: const Size(360, 844),
    );
    expect(tester.takeException(), isNull);
    expectWholeWords(tester, find.text('4,500 kcal/day (planner max)'));
    expectWholeWords(
      tester,
      find.text('Calories and prices are rough estimates for now.'),
    );
  });

  group('This week states at 2x text on 360dp', () {
    final planner = _ThisWeekPlanner();
    late WeekPlanController plan;
    late PlanDraft draft;

    Future<void> pumpState(WidgetTester tester) async {
      plan = WeekPlanController(planner, wait: (_) => Future.value());
      addTearDown(plan.dispose);
      draft = PlanDraft();
      plan.build(draft.brief);
      tester.view.physicalSize = const Size(360, 844);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        host(ThisWeekScreen(draft: draft, controller: plan, onGrocery: () {})),
      );
      // Spinners never settle.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('the failed card keeps a long message and Try again whole', (
      tester,
    ) async {
      planner.startReply = PlanSnapshot(
        id: 'p',
        status: PlanStatus.failed,
        message:
            'The price checker could not be reached, so no week could '
            'be built within your budget. Try again in a minute.',
      );
      await pumpState(tester);
      expect(tester.takeException(), isNull);
      expectWholeWords(tester, find.text("We couldn't build your week."));
      expectWholeWords(tester, find.textContaining('The price checker'));
      await tester.ensureVisible(find.text('Try again'));
      expectWholeWords(tester, find.text('Try again'));
    });

    testWidgets('a notice and a swapping card wrap without overflow', (
      tester,
    ) async {
      planner.startReply = PlanSnapshot(
        id: 'p',
        status: PlanStatus.ready,
        week: sampleWeek(),
        message:
            'No other lunch fits your budget today, so your lunch is '
            'unchanged.',
      );
      await pumpState(tester);
      expect(tester.takeException(), isNull);
      expectWholeWords(tester, find.textContaining('No other lunch'));

      planner.swapReply = Completer();
      await tester.ensureVisible(find.bySemanticsLabel('Swap breakfast'));
      await tester.tap(find.bySemanticsLabel('Swap breakfast'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expectWholeWords(tester, find.text('Swapping this meal'));
    });
  });

  testWidgets('the grocery note, a long item and Elsewhere stay whole at 2x, '
      '360dp', (tester) async {
    const long = 'Sinigang (tamarind) mix';
    await pumpAt(
      tester,
      GroceryListScreen(
        list: const GroceryList(
          budgetPhp: 2500,
          sections: [
            GrocerySection(
              storeId: 'puregold',
              name: 'Puregold',
              monogram: 'P',
              local: false,
              items: [
                GroceryItem(
                  name: long,
                  quantity: '1.3 kg',
                  pricePhp: 40,
                  kind: GroceryKind.pantry,
                ),
              ],
            ),
            GrocerySection(
              storeId: 'elsewhere',
              name: 'Elsewhere',
              monogram: 'E',
              local: false,
              note: '(not sold at the stores you picked)',
              items: [
                GroceryItem(
                  name: 'Daing na bangus',
                  quantity: '300 g',
                  pricePhp: 72,
                  kind: GroceryKind.fish,
                ),
              ],
            ),
          ],
        ),
        onBack: () {},
      ),
      scale: 2.0,
      size: const Size(360, 844),
    );
    expect(tester.takeException(), isNull);
    expectWholeWords(tester, find.text(groceryListNote));
    await tester.ensureVisible(find.text(long));
    expectWholeWords(tester, find.text(long));
    await tester.ensureVisible(find.text('Elsewhere'));
    expectWholeWords(tester, find.text('Elsewhere'));
    expectWholeWords(tester, find.text('(not sold at the stores you picked)'));
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(390, 844), const Size(360, 844)]) {
    testWidgets('Welcome CTA names its action in full at 2x, ${size.width}dp', (
      tester,
    ) async {
      await pumpAt(
        tester,
        WelcomeScreen(exampleDay: sampleWeek().first, onStart: () {}),
        scale: 2.0,
        size: size,
      );
      expect(tester.takeException(), isNull);
      expectWholeWords(tester, find.text('Find my calorie target'));
    });
  }

  for (final (scale, size) in [
    (1.0, const Size(360, 640)),
    (1.5, const Size(390, 844)),
    (2.0, const Size(390, 844)),
  ]) {
    testWidgets('store names stay whole at ${scale}x, ${size.width}dp', (
      tester,
    ) async {
      await pumpAt(
        tester,
        WhereYouShopScreen(draft: PlanDraft(), onNext: () {}),
        scale: scale,
        size: size,
      );
      expect(tester.takeException(), isNull);
      for (final t in [...chainTiles, ...localTiles]) {
        // The name, not the monogram ("S&R" is both).
        final name = find.text(t.name).last;
        await tester.ensureVisible(name);
        expectWholeWords(tester, name);
      }
    });
  }

  for (final (size, fullSize) in [
    (const Size(390, 844), true),
    (const Size(360, 640), false),
  ]) {
    testWidgets('at default text the store grid stays two a row, '
        '${size.width}dp', (tester) async {
      await pumpAt(
        tester,
        WhereYouShopScreen(draft: PlanDraft(), onNext: () {}),
        scale: 1.0,
        size: size,
      );
      final sm = tester.getRect(find.text('SM Supermarket'));
      final puregold = tester.getRect(find.text('Puregold'));
      expect(puregold.left, greaterThan(sm.right), reason: 'side by side');
      final fontSize = paragraph(
        tester,
        find.text('Puregold'),
      ).text.style!.fontSize!;
      if (fullSize) {
        expect(fontSize, 14);
      } else {
        expect(fontSize, inInclusiveRange(14 * MpStoreTile.minNameScale, 14));
      }
    });
  }
}

/// Answers start with [startReply] at once; swaps wait on [swapReply].
class _ThisWeekPlanner implements Planner {
  late PlanSnapshot startReply;
  Completer<PlanSnapshot> swapReply = Completer();

  @override
  Future<PlanSnapshot> start(PlanBrief brief) async => startReply;

  @override
  Future<PlanSnapshot> fetch(String id) async => startReply;

  @override
  Future<PlanSnapshot> swap(
    String id,
    Weekday day,
    MealSlot slot, {
    String? note,
  }) => swapReply.future;
}
