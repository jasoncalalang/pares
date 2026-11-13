import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mealpal_ph/data/sample_planner.dart';
import 'package:mealpal_ph/data/sample_week.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:mealpal_ph/design_system/design_system.dart';
import 'package:mealpal_ph/screens/this_week_screen.dart';
import 'package:mealpal_ph/state/plan_draft.dart';
import 'package:mealpal_ph/state/week_plan_controller.dart';
import 'package:mealpal_ph/widgets/widgets.dart';

import '../helpers.dart';

/// A planner the test steers by hand: start and swap answer when their
/// completer does, fetch answers with [fetchReply].
class _ScriptedPlanner implements Planner {
  Completer<PlanSnapshot> startReply = Completer();
  Completer<PlanSnapshot> swapReply = Completer();
  PlanSnapshot Function() fetchReply = () => throw StateError('no fetch');
  int starts = 0;
  final swaps = <(Weekday, MealSlot)>[];

  @override
  Future<PlanSnapshot> start(PlanBrief brief) {
    starts++;
    return startReply.future;
  }

  @override
  Future<PlanSnapshot> fetch(String id) async => fetchReply();

  @override
  Future<PlanSnapshot> swap(
    String id,
    Weekday day,
    MealSlot slot, {
    String? note,
  }) {
    swaps.add((day, slot));
    return swapReply.future;
  }
}

PlanSnapshot _ready({String? message, List<DayPlan>? week}) => PlanSnapshot(
  id: 'p1',
  status: PlanStatus.ready,
  week: week ?? sampleWeek(),
  message: message,
);

/// The day line the screen writes, read from the data so a bank change
/// cannot leave a stale number in the tests.
String _dayLine(DayPlan day) =>
    '${day.weekday.label} · ${formatThousands(day.kcal)} kcal · '
    '${formatPeso(day.pricePhp, decimals: 0)}';

/// Monday of the sample week, with the breakfast replaced by [breakfast].
DayPlan _mondayWith(PlannedMeal breakfast) {
  final monday = sampleWeek().first;
  return DayPlan(weekday: monday.weekday, meals: [
    for (final m in monday.meals) m.slot == MealSlot.breakfast ? breakfast : m,
  ]);
}

String _mealLine(PlannedMeal m) =>
    '${m.servings == 1 ? '' : '${m.servings} servings · '}'
    '${m.kcal} kcal · ₱${m.pricePhp}';

void main() {
  late PlanDraft draft;
  late WeekPlanController controller;
  var groceries = 0;

  Future<void> show(
    WidgetTester tester,
    WeekPlanController c, {
    VoidCallback? onBack,
  }) async {
    await phone(tester);
    draft = PlanDraft();
    controller = c;
    addTearDown(controller.dispose);
    groceries = 0;
    controller.build(draft.brief);
    await tester.pumpWidget(
      host(
        ThisWeekScreen(
          draft: draft,
          controller: controller,
          onGrocery: () => groceries++,
          onBack: onBack,
        ),
      ),
    );
    // Building and swapping spin forever, so they can never settle.
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> pump(WidgetTester tester) async {
    await show(tester, WeekPlanController(SamplePlanner()));
    await tester.pumpAndSettle();
  }

  /// A ready plan on a planner the test can steer.
  Future<_ScriptedPlanner> pumpScripted(WidgetTester tester) async {
    final planner = _ScriptedPlanner();
    await show(
      tester,
      WeekPlanController(planner, wait: (_) => Future.value()),
    );
    planner.startReply.complete(_ready());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return planner;
  }

  testWidgets('shows the header pills, day strip and Monday meals', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('2,087 kcal/day'), findsOneWidget);
    expect(find.text('≤ ₱2,500'), findsOneWidget);
    expect(find.text('Grocery list'), findsNothing);
    expect(find.text('New'), findsNothing);
    for (final d in ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']) {
      expect(find.text(d), findsOneWidget, reason: d);
    }
    expect(find.text(_dayLine(sampleWeek().first)), findsOneWidget);
    expect(find.text('BREAKFAST'), findsOneWidget);
    expect(
      find.text('Tapsilog: beef tapa, garlic rice and egg'),
      findsOneWidget,
    );
    expect(find.text(_mealLine(sampleWeek().first.meals.first)), findsOneWidget);
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
    expect(find.text(_dayLine(sampleWeek().first)), findsNothing);
  });

  testWidgets('swapping a meal replaces it and re-totals the day', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.bySemanticsLabel('Swap breakfast'));
    await tester.pumpAndSettle();
    expect(
      find.text('Daingsilog: fried milkfish, garlic rice and egg'),
      findsOneWidget,
    );
    expect(find.text('Tapsilog: beef tapa, garlic rice and egg'), findsNothing);
    final second = nextAlternative(sampleWeek().first.meals.first);
    expect(find.text(_dayLine(_mondayWith(second))), findsOneWidget);
    // The swap belongs to Monday only.
    await tester.tap(find.text('THU'));
    await tester.pumpAndSettle();
    expect(
      find.text('Tapsilog: beef tapa, garlic rice and egg'),
      findsOneWidget,
    );
  });

  testWidgets('swapping again moves on from the meal now showing', (
    tester,
  ) async {
    await pump(tester);
    final swap = find.bySemanticsLabel('Swap breakfast');
    await tester.tap(swap);
    await tester.pumpAndSettle();
    expect(
      find.text('Daingsilog: fried milkfish, garlic rice and egg'),
      findsOneWidget,
    );
    await tester.tap(swap);
    await tester.pumpAndSettle();
    expect(find.text('Lugaw with egg and toasted garlic'), findsOneWidget);
    final second = nextAlternative(sampleWeek().first.meals.first);
    final third = nextAlternative(second);
    expect(find.text(_dayLine(_mondayWith(third))), findsOneWidget);
    // The bank has more breakfasts now, so a third swap does not come home.
    await tester.tap(swap);
    await tester.pumpAndSettle();
    final fourth = nextAlternative(third);
    expect(fourth.name, isNot('Tapsilog: beef tapa, garlic rice and egg'));
    expect(find.text(fourth.name), findsOneWidget);
    expect(find.text(_dayLine(_mondayWith(fourth))), findsOneWidget);
  });

  testWidgets('a swap survives visiting another day', (tester) async {
    await pump(tester);
    await tester.tap(find.bySemanticsLabel('Swap breakfast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TUE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MON'));
    await tester.pumpAndSettle();
    expect(
      find.text('Daingsilog: fried milkfish, garlic rice and egg'),
      findsOneWidget,
    );
    final second = nextAlternative(sampleWeek().first.meals.first);
    expect(find.text(_dayLine(_mondayWith(second))), findsOneWidget);
  });

  testWidgets('day buttons stay full tap targets on a 360dp phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final c = WeekPlanController(SamplePlanner());
    addTearDown(c.dispose);
    final d = PlanDraft();
    c.build(d.brief);
    await tester.pumpWidget(
      host(ThisWeekScreen(draft: d, controller: c, onGrocery: () {})),
    );
    await tester.pumpAndSettle();
    final days = find.descendant(
      of: find.byType(MpDayStrip),
      matching: find.byType(MpPress),
    );
    expect(days, findsNWidgets(7));
    for (var i = 0; i < 7; i++) {
      final size = tester.getSize(days.at(i));
      expect(size.width, greaterThanOrEqualTo(MpSize.tap), reason: 'day $i');
      expect(size.height, greaterThanOrEqualTo(MpSize.tap), reason: 'day $i');
    }
  });

  testWidgets('the pinned footer is the one way to the grocery list', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byType(MpPillButton), findsNothing);
    await tester.tap(find.text('See grocery list'));
    await tester.pumpAndSettle();
    expect(groceries, 1);
  });

  testWidgets('says the meal numbers are rough estimates under the day line', (
    tester,
  ) async {
    await pump(tester);
    final note = find.text('Calories and prices are rough estimates for now.');
    expect(note, findsOneWidget);
    final line = find.text(_dayLine(sampleWeek().first));
    expect(
      tester.getTopLeft(note).dy,
      greaterThan(tester.getBottomLeft(line).dy - 1),
    );
    expect(paintedColor(tester, note), paintedColor(tester, line));
  });

  testWidgets('no estimates line while the plan is building', (tester) async {
    await show(tester, WeekPlanController(_ScriptedPlanner()));
    expect(
      find.text('Calories and prices are rough estimates for now.'),
      findsNothing,
    );
  });

  testWidgets('the target pill says when the planner capped it', (
    tester,
  ) async {
    await show(tester, WeekPlanController(SamplePlanner()));
    await tester.pumpAndSettle();
    expect(find.textContaining('planner max'), findsNothing);
    draft
      ..weightKg = 150
      ..heightCm = 190
      ..age = 20
      ..activity = ActivityLevel.active
      ..goal = Goal.gain;
    await tester.pumpAndSettle();
    expect(find.text('4,500 kcal/day (planner max)'), findsOneWidget);
  });

  testWidgets('while the plan is building it says so and hides the meals', (
    tester,
  ) async {
    await show(tester, WeekPlanController(_ScriptedPlanner()));
    expect(find.text('Building your week'), findsOneWidget);
    expect(
      find.text(
        'Matching meals to your 2,087 kcal target and ₱2,500 weekly '
        'budget from the stores you picked.',
      ),
      findsOneWidget,
    );
    expect(find.text('BREAKFAST'), findsNothing);
    expect(find.text('See grocery list'), findsNothing);
    expect(find.text('Grocery list'), findsNothing);
  });

  testWidgets('the week appears when the planner finishes', (tester) async {
    final planner = await pumpScripted(tester);
    expect(planner.starts, 1);
    expect(find.text('Building your week'), findsNothing);
    expect(find.text('BREAKFAST'), findsOneWidget);
  });

  testWidgets('a failed build shows the planner message and can be retried', (
    tester,
  ) async {
    final planner = _ScriptedPlanner();
    await show(
      tester,
      WeekPlanController(planner, wait: (_) => Future.value()),
    );
    planner.startReply.complete(
      PlanSnapshot(
        id: 'p1',
        status: PlanStatus.failed,
        message: 'The price checker was not reachable.',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text("We couldn't build your week."), findsOneWidget);
    expect(find.text('The price checker was not reachable.'), findsOneWidget);
    expect(find.text('BREAKFAST'), findsNothing);

    planner.startReply = Completer();
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(planner.starts, 2);
    expect(find.text('Building your week'), findsOneWidget);
    planner.startReply.complete(_ready());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('BREAKFAST'), findsOneWidget);
  });

  testWidgets('a swap keeps the week on screen and marks only its own card', (
    tester,
  ) async {
    final planner = await pumpScripted(tester);
    await tester.tap(find.bySemanticsLabel('Swap lunch'));
    await tester.pump();
    expect(planner.swaps, [(Weekday.mon, MealSlot.lunch)]);
    expect(find.text('Swapping this meal'), findsOneWidget);
    expect(find.text(_dayLine(sampleWeek().first)), findsOneWidget);
    expect(find.text('BREAKFAST'), findsOneWidget);
    // Other swap buttons are off while one swap is in flight.
    await tester.tap(find.bySemanticsLabel('Swap dinner'));
    await tester.pump();
    expect(planner.swaps, hasLength(1));

    final swapped = sampleWeek();
    planner.swapReply.complete(
      _ready(
        week: [
          for (final d in swapped)
            if (d.weekday != Weekday.mon)
              d
            else
              DayPlan(
                weekday: d.weekday,
                meals: [
                  for (final m in d.meals)
                    m.slot == MealSlot.lunch ? nextAlternative(m) : m,
                ],
              ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Swapping this meal'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Swap dinner'));
    await tester.pump();
    expect(planner.swaps, hasLength(2));
  });

  testWidgets('a swap that changed nothing shows its message above the meals', (
    tester,
  ) async {
    final planner = await pumpScripted(tester);
    await tester.tap(find.bySemanticsLabel('Swap lunch'));
    await tester.pump();
    planner.swapReply.complete(
      _ready(message: 'No other lunch fits your budget today.'),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final notice = find.text('No other lunch fits your budget today.');
    expect(notice, findsOneWidget);
    expect(
      tester.getTopLeft(notice).dy,
      lessThan(tester.getTopLeft(find.text('BREAKFAST')).dy),
    );
    expect(find.text(_dayLine(sampleWeek().first)), findsOneWidget);

    // The next action clears it.
    planner.swapReply = Completer();
    await tester.tap(find.bySemanticsLabel('Swap snack'));
    await tester.pump();
    expect(notice, findsNothing);
  });

  testWidgets('a swapping card is announced to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScripted(tester);
    await tester.tap(find.bySemanticsLabel('Swap lunch'));
    await tester.pump();
    expect(
      tester.getSemantics(find.text('Swapping this meal')),
      isSemantics(isLiveRegion: true),
    );
    handle.dispose();
  });


  testWidgets('a rejected brief offers Go back, not a Try again that cannot '
      'work', (tester) async {
    final planner = _ScriptedPlanner();
    var backs = 0;
    await show(
      tester,
      WeekPlanController(planner, wait: (_) => Future.value()),
      onBack: () => backs++,
    );
    planner.startReply.completeError(
      const PlannerException(
        PlannerErrorKind.rejected,
        problems: ['budgetPhp must be at least 500.'],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Try again'), findsNothing);
    expect(find.textContaining('budgetPhp'), findsNothing);
    // A way back points back: the forward arrow is for a step forward.
    final goBack = find.widgetWithText(MpCta, 'Go back');
    expect(
      find.descendant(of: goBack, matching: find.byIcon(LucideIcons.arrowLeft)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: goBack, matching: find.byIcon(LucideIcons.arrowRight)),
      findsNothing,
    );
    await tester.tap(find.text('Go back').last);
    expect(backs, 1);
  });

  testWidgets('the sample week says it is a sample, under the numbers it '
      'does not match', (tester) async {
    await show(tester, WeekPlanController(SamplePlanner()));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'This is a sample week. It is not matched to your target, budget or '
        'stores yet.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the screen title is a heading for screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await show(tester, WeekPlanController(SamplePlanner()));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('This week')),
      isSemantics(isHeader: true, label: 'This week'),
    );
    handle.dispose();
  });

  testWidgets('the building and failed cards are live regions, read once', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final planner = _ScriptedPlanner();
    await show(
      tester,
      WeekPlanController(planner, wait: (_) => Future.value()),
    );
    expect(find.bySemanticsLabel(RegExp('Building your week')), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Building your week')),
      isSemantics(isLiveRegion: true),
    );
    planner.startReply.complete(
      PlanSnapshot(id: 'p1', status: PlanStatus.failed, message: 'No.'),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.getSemantics(find.text("We couldn't build your week.")),
      isSemantics(isLiveRegion: true),
    );
    handle.dispose();
  });

  testWidgets('Enter on a swap button keeps focus on it while it builds', (
    tester,
  ) async {
    await pumpScripted(tester);
    String? focused() {
      final at = FocusManager.instance.primaryFocus?.context;
      return at?.findAncestorWidgetOfExactType<MpPress>()?.semanticLabel;
    }

    for (var i = 0; i < 20 && focused() != 'Swap lunch'; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(focused(), 'Swap lunch');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.text('Swapping this meal'), findsOneWidget);
    expect(focused(), 'Swap lunch');
  });

  testWidgets('another day says why its swaps are off while one runs', (
    tester,
  ) async {
    await pumpScripted(tester);
    await tester.tap(find.bySemanticsLabel('Swap lunch'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(RegExp('^Tuesday')));
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text("Swapping Monday's lunch. Swaps on other meals wait until it "
          'is done.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Tab reaches every meal before the pinned CTA, and the CTA once',
    (tester) async {
      await pump(tester);
      String focused() {
        final at = FocusManager.instance.primaryFocus!.context!;
        final press = at.findAncestorWidgetOfExactType<MpPress>()!;
        return press.semanticLabel ??
            tester
                .widget<Text>(
                  find
                      .descendant(
                        of: find.byWidget(press),
                        matching: find.byType(Text),
                      )
                      .first,
                )
                .data!;
      }

      // Seven days, four swaps and the CTA: one full pass.
      final stops = <String>[];
      for (var i = 0; i < 12; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        stops.add(focused());
      }
      expect(
        stops.where((s) => s == 'See grocery list'),
        hasLength(1),
        reason: stops.join(', '),
      );
      expect(stops.last, 'See grocery list', reason: stops.join(', '));
      expect(
        stops.indexOf('Swap snack'),
        lessThan(stops.indexOf('See grocery list')),
      );
    },
  );
}
