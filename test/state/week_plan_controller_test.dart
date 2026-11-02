import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/data/sample_week.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:mealpal_ph/state/week_plan_controller.dart';

PlanBrief brief({int budget = 2500}) => PlanBrief(
  targetKcal: 2000,
  budgetPhp: budget,
  goal: Goal.maintain,
  storeIds: ['puregold'],
);

PlanSnapshot building({String id = 'p1', List<DayPlan>? week}) =>
    PlanSnapshot(id: id, status: PlanStatus.building, week: week);

PlanSnapshot ready({String id = 'p1', List<DayPlan>? week, String? message}) =>
    PlanSnapshot(
      id: id,
      status: PlanStatus.ready,
      week: week ?? sampleWeek(),
      message: message,
    );

PlannerException err(
  PlannerErrorKind k, {
  String? message,
  List<String> problems = const [],
}) => PlannerException(k, message: message, problems: problems);

/// Scripted planner: each call pops the next reply (a snapshot, an exception,
/// or a Future of either) from its queue.
class FakePlanner implements Planner {
  final starts = <PlanBrief>[];
  final fetches = <String>[];
  final swaps = <(String, Weekday, MealSlot)>[];
  final startReplies = <Object>[];
  final fetchReplies = <Object>[];
  final swapReplies = <Object>[];

  Future<PlanSnapshot> _next(List<Object> q) async {
    final r = q.removeAt(0);
    final v = r is Future ? await r : r;
    if (v is PlannerException) throw v;
    return v as PlanSnapshot;
  }

  @override
  Future<PlanSnapshot> start(PlanBrief b) {
    starts.add(b);
    return _next(startReplies);
  }

  @override
  Future<PlanSnapshot> fetch(String id) {
    fetches.add(id);
    return _next(fetchReplies);
  }

  @override
  Future<PlanSnapshot> swap(
    String id,
    Weekday day,
    MealSlot slot, {
    String? note,
  }) {
    swaps.add((id, day, slot));
    return _next(swapReplies);
  }
}

const two = Duration(seconds: 2);

void main() {
  late FakePlanner planner;
  setUp(() => planner = FakePlanner());

  test('build shows building, then the week once the planner is ready', () {
    fakeAsync((async) {
      planner.startReplies.add(building());
      planner.fetchReplies.addAll([building(), ready()]);
      final c = WeekPlanController(planner);
      c.build(brief());
      expect(c.status, PlanStatus.building);
      expect(c.week, isNull);
      expect(c.brief, brief());
      async.flushMicrotasks();
      expect(planner.fetches, isEmpty);
      async.elapse(two);
      expect(planner.fetches, ['p1']);
      expect(c.status, PlanStatus.building);
      async.elapse(two);
      expect(c.status, PlanStatus.ready);
      expect(c.week, hasLength(7));
      expect(c.notice, isNull);
      expect(c.failure, isNull);
      async.elapse(const Duration(minutes: 1));
      expect(planner.fetches, hasLength(2));
      c.dispose();
    });
  });

  test('a plan that is ready at once needs no polling', () {
    fakeAsync((async) {
      planner.startReplies.add(ready());
      final c = WeekPlanController(planner)..build(brief());
      async.flushMicrotasks();
      expect(c.status, PlanStatus.ready);
      expect(planner.fetches, isEmpty);
      c.dispose();
    });
  });

  test('build is a no-op for the same brief while building or ready', () {
    fakeAsync((async) {
      planner.startReplies.add(building());
      planner.fetchReplies.add(ready());
      final c = WeekPlanController(planner)..build(brief());
      async.flushMicrotasks();
      c.build(brief());
      expect(planner.starts, hasLength(1));
      async.elapse(two);
      expect(c.status, PlanStatus.ready);
      c.build(brief());
      async.flushMicrotasks();
      expect(planner.starts, hasLength(1));
      expect(c.status, PlanStatus.ready);
      c.dispose();
    });
  });

  test('a different brief drops the old plan and starts a new one', () {
    fakeAsync((async) {
      planner.startReplies.addAll([ready(), building(id: 'p2')]);
      final c = WeekPlanController(planner)..build(brief());
      async.flushMicrotasks();
      expect(c.status, PlanStatus.ready);
      c.build(brief(budget: 3000));
      expect(c.status, PlanStatus.building);
      expect(c.week, isNull);
      async.flushMicrotasks();
      expect(planner.starts.last.budgetPhp, 3000);
      c.dispose();
    });
  });

  test('a failed plan shows the server message', () {
    fakeAsync((async) {
      planner.startReplies.add(building());
      planner.fetchReplies.add(
        const PlanSnapshot(
          id: 'p1',
          status: PlanStatus.failed,
          message: 'The planner ran out of meals under that budget.',
        ),
      );
      final c = WeekPlanController(planner)..build(brief());
      async.elapse(two);
      expect(c.status, PlanStatus.failed);
      expect(c.failure, 'The planner ran out of meals under that budget.');
      expect(c.week, isNull);
      c.dispose();
    });
  });

  test('a failed plan with no message still says something honest', () {
    fakeAsync((async) {
      planner.startReplies.add(
        const PlanSnapshot(id: 'p1', status: PlanStatus.failed),
      );
      final c = WeekPlanController(planner)..build(brief());
      async.flushMicrotasks();
      expect(c.status, PlanStatus.failed);
      expect(c.failure, isNotEmpty);
      expect(c.failure, isNot(contains('\u2014')));
      c.dispose();
    });
  });

  test('each error kind gets plain copy on the failed card', () {
    final copies = <PlannerErrorKind, String>{};
    for (final kind in PlannerErrorKind.values) {
      fakeAsync((async) {
        final p = FakePlanner()
          ..startReplies.add(
            err(
              kind,
              message: 'raw server words',
              problems: ['budgetPhp too low'],
            ),
          );
        final c = WeekPlanController(p)..build(brief());
        async.flushMicrotasks();
        expect(c.status, PlanStatus.failed, reason: kind.name);
        copies[kind] = c.failure!;
        c.dispose();
      });
    }
    expect(copies[PlannerErrorKind.network], contains('connection'));
    expect(copies[PlannerErrorKind.rejected], contains('budgetPhp too low'));
    expect(copies[PlannerErrorKind.unauthorized], contains('app'));
    expect(copies.values.toSet(), hasLength(PlannerErrorKind.values.length));
    for (final c in copies.values) {
      expect(c, isNot(contains('\u2014')));
      expect(c, isNot(contains('Exception')));
    }
  });

  test('gives up after three minutes with an honest failure', () {
    fakeAsync((async) {
      planner.startReplies.add(building());
      planner.fetchReplies.addAll(List.generate(200, (_) => building()));
      final c = WeekPlanController(planner)..build(brief());
      async.elapse(const Duration(minutes: 2, seconds: 58));
      expect(c.status, PlanStatus.building);
      async.elapse(const Duration(seconds: 4));
      expect(c.status, PlanStatus.failed);
      expect(c.failure, contains('3 minutes'));
      final polls = planner.fetches.length;
      async.elapse(const Duration(minutes: 5));
      expect(planner.fetches.length, polls);
      c.dispose();
    });
  });

  test('survives three dropped polls in a row, fails on the fourth', () {
    fakeAsync((async) {
      planner.startReplies.add(building());
      planner.fetchReplies.addAll([
        err(PlannerErrorKind.network),
        err(PlannerErrorKind.network),
        err(PlannerErrorKind.network),
        building(),
        err(PlannerErrorKind.network),
        err(PlannerErrorKind.network),
        err(PlannerErrorKind.network),
        ready(),
      ]);
      final c = WeekPlanController(planner)..build(brief());
      async.elapse(two * 8);
      // The success in the middle reset the count.
      expect(c.status, PlanStatus.ready);
      c.dispose();
    });
    fakeAsync((async) {
      final p = FakePlanner()
        ..startReplies.add(building())
        ..fetchReplies.addAll(
          List.generate(10, (_) => err(PlannerErrorKind.network)),
        );
      final c = WeekPlanController(p)..build(brief());
      async.elapse(two * 3);
      expect(c.status, PlanStatus.building);
      async.elapse(two);
      expect(c.status, PlanStatus.failed);
      expect(c.failure, contains('connection'));
      c.dispose();
    });
  });

  test('a poll error that is not the network fails the plan at once', () {
    fakeAsync((async) {
      planner.startReplies.add(building());
      planner.fetchReplies.add(err(PlannerErrorKind.notFound));
      final c = WeekPlanController(planner)..build(brief());
      async.elapse(two);
      expect(c.status, PlanStatus.failed);
      c.dispose();
    });
  });

  test('retry starts the last brief again from scratch', () {
    fakeAsync((async) {
      planner.startReplies.addAll([
        err(PlannerErrorKind.unavailable),
        ready(id: 'p2'),
      ]);
      final c = WeekPlanController(planner)..build(brief());
      async.flushMicrotasks();
      expect(c.status, PlanStatus.failed);
      c.retry();
      expect(c.status, PlanStatus.building);
      expect(c.failure, isNull);
      async.flushMicrotasks();
      expect(c.status, PlanStatus.ready);
      expect(planner.starts, [brief(), brief()]);
      c.dispose();
    });
  });

  test('build with the same brief after a failure starts again', () {
    fakeAsync((async) {
      planner.startReplies.addAll([err(PlannerErrorKind.network), ready()]);
      final c = WeekPlanController(planner)..build(brief());
      async.flushMicrotasks();
      c.build(brief());
      async.flushMicrotasks();
      expect(c.status, PlanStatus.ready);
      c.dispose();
    });
  });

  test('retry before any build does nothing', () {
    final c = WeekPlanController(planner)..retry();
    expect(planner.starts, isEmpty);
    c.dispose();
  });

  test('an older plan never overwrites a newer one', () {
    fakeAsync((async) {
      final slow = Completer<PlanSnapshot>();
      planner.startReplies.addAll([slow.future, ready(id: 'new')]);
      final c = WeekPlanController(planner)..build(brief());
      async.flushMicrotasks();
      c.build(brief(budget: 4000));
      async.flushMicrotasks();
      expect(c.status, PlanStatus.ready);
      final newWeek = c.week;
      slow.complete(ready(id: 'old', week: sampleWeek().take(2).toList()));
      async.flushMicrotasks();
      expect(c.week, same(newWeek));
      expect(c.brief!.budgetPhp, 4000);
      c.dispose();
    });
  });

  test('an older polling loop stops when a newer build starts', () {
    fakeAsync((async) {
      planner.startReplies.addAll([building(id: 'old'), ready(id: 'new')]);
      planner.fetchReplies.addAll(List.generate(5, (_) => building(id: 'old')));
      final c = WeekPlanController(planner)..build(brief());
      async.flushMicrotasks();
      c.build(brief(budget: 4000));
      async.elapse(const Duration(minutes: 1));
      expect(planner.fetches, isEmpty);
      expect(c.status, PlanStatus.ready);
      c.dispose();
    });
  });

  group('swap', () {
    test('keeps the week visible, marks the card, then shows the new meal', () {
      fakeAsync((async) {
        final swapped = sampleWeek();
        planner.startReplies.add(ready());
        planner.swapReplies.add(building(week: sampleWeek()));
        planner.fetchReplies.addAll([
          building(week: sampleWeek()),
          ready(week: swapped.reversed.toList()),
        ]);
        final c = WeekPlanController(planner)..build(brief());
        async.flushMicrotasks();
        final before = c.week;
        c.swap(Weekday.wed, MealSlot.lunch);
        expect(c.swapping, (Weekday.wed, MealSlot.lunch));
        expect(c.status, PlanStatus.ready);
        expect(c.week, same(before));
        async.flushMicrotasks();
        expect(planner.swaps.single, ('p1', Weekday.wed, MealSlot.lunch));
        // Second swap while one is in flight is ignored.
        c.swap(Weekday.thu, MealSlot.dinner);
        async.flushMicrotasks();
        expect(planner.swaps, hasLength(1));
        async.elapse(two);
        expect(c.swapping, isNotNull);
        expect(c.week, same(before));
        async.elapse(two);
        expect(c.swapping, isNull);
        expect(c.week, isNot(same(before)));
        expect(c.status, PlanStatus.ready);
        c.dispose();
      });
    });

    test('a swap that is ready at once needs no polling', () {
      fakeAsync((async) {
        planner.startReplies.add(ready());
        planner.swapReplies.add(ready(week: sampleWeek().reversed.toList()));
        final c = WeekPlanController(planner)..build(brief());
        async.flushMicrotasks();
        c.swap(Weekday.mon, MealSlot.snack);
        async.flushMicrotasks();
        expect(c.swapping, isNull);
        expect(c.week!.first.weekday, Weekday.sun);
        expect(planner.fetches, isEmpty);
        c.dispose();
      });
    });

    test('a message on the ready record becomes a notice, week unchanged', () {
      fakeAsync((async) {
        planner.startReplies.add(ready());
        planner.swapReplies.add(
          ready(
            message: 'No other dinner fits the budget, so Monday dinner stays.',
          ),
        );
        final c = WeekPlanController(planner)..build(brief());
        async.flushMicrotasks();
        c.swap(Weekday.mon, MealSlot.dinner);
        async.flushMicrotasks();
        expect(
          c.notice,
          'No other dinner fits the budget, so Monday dinner stays.',
        );
        expect(c.status, PlanStatus.ready);
        expect(c.swapping, isNull);
        c.dispose();
      });
    });

    test('the notice clears on the next swap', () {
      fakeAsync((async) {
        planner.startReplies.add(ready());
        planner.swapReplies.addAll([
          ready(message: 'Nothing changed.'),
          building(),
        ]);
        final c = WeekPlanController(planner)..build(brief());
        async.flushMicrotasks();
        c.swap(Weekday.mon, MealSlot.dinner);
        async.flushMicrotasks();
        expect(c.notice, isNotNull);
        c.swap(Weekday.mon, MealSlot.dinner);
        expect(c.notice, isNull);
        c.dispose();
      });
    });

    test('409 becomes a notice and the plan stays ready', () {
      fakeAsync((async) {
        planner.startReplies.add(ready());
        planner.swapReplies.add(err(PlannerErrorKind.busy, message: 'busy'));
        final c = WeekPlanController(planner)..build(brief());
        async.flushMicrotasks();
        final week = c.week;
        c.swap(Weekday.mon, MealSlot.lunch);
        async.flushMicrotasks();
        expect(c.status, PlanStatus.ready);
        expect(c.week, same(week));
        expect(c.notice, contains('Try the swap again'));
        expect(c.swapping, isNull);
        c.dispose();
      });
    });

    test('other errors become a notice and the old week stays', () {
      for (final kind in PlannerErrorKind.values) {
        fakeAsync((async) {
          final p = FakePlanner()
            ..startReplies.add(ready())
            ..swapReplies.add(err(kind, problems: ['bad slot']));
          final c = WeekPlanController(p)..build(brief());
          async.flushMicrotasks();
          final week = c.week;
          c.swap(Weekday.mon, MealSlot.lunch);
          async.flushMicrotasks();
          expect(c.status, PlanStatus.ready, reason: kind.name);
          expect(c.week, same(week), reason: kind.name);
          expect(c.notice, isNotEmpty, reason: kind.name);
          expect(c.notice, isNot(contains('\u2014')));
          expect(c.swapping, isNull, reason: kind.name);
          c.dispose();
        });
      }
    });

    test('a swap that never finishes gives up with a notice, week kept', () {
      fakeAsync((async) {
        planner.startReplies.add(ready());
        planner.swapReplies.add(building());
        planner.fetchReplies.addAll(List.generate(200, (_) => building()));
        final c = WeekPlanController(planner)..build(brief());
        async.flushMicrotasks();
        final week = c.week;
        c.swap(Weekday.mon, MealSlot.lunch);
        async.elapse(const Duration(minutes: 4));
        expect(c.swapping, isNull);
        expect(c.notice, contains('3 minutes'));
        expect(c.week, same(week));
        expect(c.status, PlanStatus.ready);
        c.dispose();
      });
    });

    test('is ignored unless the plan is ready', () {
      fakeAsync((async) {
        planner.startReplies.add(building());
        final c = WeekPlanController(planner);
        c.swap(Weekday.mon, MealSlot.lunch);
        c.build(brief());
        async.flushMicrotasks();
        c.swap(Weekday.mon, MealSlot.lunch);
        async.flushMicrotasks();
        expect(planner.swaps, isEmpty);
        expect(c.swapping, isNull);
        c.dispose();
      });
    });

    test('a new build cancels a swap in flight', () {
      fakeAsync((async) {
        final slow = Completer<PlanSnapshot>();
        planner.startReplies.addAll([ready(), ready(id: 'p2')]);
        planner.swapReplies.add(slow.future);
        final c = WeekPlanController(planner)..build(brief());
        async.flushMicrotasks();
        c.swap(Weekday.mon, MealSlot.lunch);
        async.flushMicrotasks();
        c.build(brief(budget: 5000));
        expect(c.swapping, isNull);
        async.flushMicrotasks();
        final week = c.week;
        slow.complete(ready(week: sampleWeek().take(1).toList()));
        async.flushMicrotasks();
        expect(c.week, same(week));
        expect(c.notice, isNull);
        c.dispose();
      });
    });
  });

  group('dispose', () {
    test('stops polling and never notifies afterwards', () {
      fakeAsync((async) {
        planner.startReplies.add(building());
        planner.fetchReplies.addAll(List.generate(20, (_) => building()));
        final c = WeekPlanController(planner)..build(brief());
        async.elapse(two);
        final polls = planner.fetches.length;
        var pings = 0;
        c.addListener(() => pings++);
        c.dispose();
        async.elapse(const Duration(minutes: 1));
        expect(planner.fetches.length, polls);
        expect(pings, 0);
      });
    });

    test('an answer that lands after dispose is dropped quietly', () {
      fakeAsync((async) {
        final slow = Completer<PlanSnapshot>();
        planner.startReplies.add(slow.future);
        final c = WeekPlanController(planner)..build(brief());
        async.flushMicrotasks();
        c.dispose();
        slow.complete(ready());
        async.flushMicrotasks();
        expect(async.nonPeriodicTimerCount, 0);
      });
    });
  });

  test('notifies listeners as the plan moves', () {
    fakeAsync((async) {
      planner.startReplies.add(ready());
      final c = WeekPlanController(planner);
      var pings = 0;
      c.addListener(() => pings++);
      c.build(brief());
      expect(pings, 1);
      async.flushMicrotasks();
      expect(pings, 2);
      c.dispose();
    });
  });
}
