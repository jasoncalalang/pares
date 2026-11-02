import 'package:mealpal_ph/data/sample_planner.dart';
import 'package:mealpal_ph/data/sample_week.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:test/test.dart';

PlanBrief _brief() => PlanBrief(
  targetKcal: 2000,
  budgetPhp: 2500,
  goal: Goal.maintain,
  storeIds: ['puregold'],
);

void main() {
  test('start answers ready at once with the sample week', () async {
    final snap = await SamplePlanner().start(_brief());
    expect(snap.status, PlanStatus.ready);
    expect(snap.message, isNull);
    expect(snap.week, hasLength(7));
    expect(snap.week!.first.meals.first.name, sampleWeek().first.meals.first.name);
  });

  test('fetch returns the current week', () async {
    final p = SamplePlanner();
    final started = await p.start(_brief());
    final snap = await p.fetch(started.id);
    expect(snap.status, PlanStatus.ready);
    expect(snap.week!.length, 7);
  });

  test('fetch of an unknown id is notFound', () async {
    expect(
      SamplePlanner().fetch('nope'),
      throwsA(
        isA<PlannerException>().having((e) => e.kind, 'kind', PlannerErrorKind.notFound),
      ),
    );
  });

  test('swap replaces one meal with the next alternative and nothing else', () async {
    final p = SamplePlanner();
    final id = (await p.start(_brief())).id;
    final before = sampleWeek();
    final snap = await p.swap(id, Weekday.tue, MealSlot.dinner);
    expect(snap.status, PlanStatus.ready);
    final tue = snap.week![1];
    expect(
      tue.meal(MealSlot.dinner)!.name,
      nextAlternative(before[1].meal(MealSlot.dinner)!).name,
    );
    expect(tue.meal(MealSlot.lunch)!.name, before[1].meal(MealSlot.lunch)!.name);
    expect(snap.week![0].meal(MealSlot.dinner)!.name, before[0].meal(MealSlot.dinner)!.name);
    // The change sticks for later fetches and keeps walking.
    final again = await p.swap(id, Weekday.tue, MealSlot.dinner);
    expect(
      again.week![1].meal(MealSlot.dinner)!.name,
      nextAlternative(nextAlternative(before[1].meal(MealSlot.dinner)!)).name,
    );
    expect((await p.fetch(id)).week![1].meal(MealSlot.dinner)!.name,
        again.week![1].meal(MealSlot.dinner)!.name);
  });

  test('a new start resets the swaps', () async {
    final p = SamplePlanner();
    final id = (await p.start(_brief())).id;
    await p.swap(id, Weekday.mon, MealSlot.breakfast);
    final fresh = await p.start(_brief());
    expect(fresh.week!.first.meal(MealSlot.breakfast)!.name,
        sampleWeek().first.meal(MealSlot.breakfast)!.name);
  });

  test('swap before a plan exists is notFound', () {
    expect(
      SamplePlanner().swap('sample', Weekday.mon, MealSlot.lunch),
      throwsA(isA<PlannerException>()),
    );
  });
}
