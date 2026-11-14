import 'package:mealpal_ph/data/sample_bank.dart';
import 'package:mealpal_ph/data/sample_week.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:mealpal_ph/state/plan_draft.dart';
import 'package:test/test.dart';

void main() {
  test('no ingredient name carries a hyphenated compound, which a narrow '
      'grocery row would break in two', () {
    for (final ingredient in sampleIngredients.values) {
      expect(ingredient.name, isNot(matches(RegExp(r'\w-\w'))));
    }
  });

  test('no dish name carries an em dash', () {
    for (final day in sampleWeek()) {
      for (final meal in day.meals) {
        expect(meal.name, isNot(contains('—')), reason: meal.name);
      }
    }
  });

  test('swapping walks the alternatives for the same slot and wraps', () {
    final monday = sampleWeek().first;
    final breakfast = monday.meal(MealSlot.breakfast)!;
    expect(breakfast.name, 'Tapsilog: beef tapa, garlic rice and egg');

    final next = nextAlternative(breakfast);
    expect(next.slot, MealSlot.breakfast);
    expect(next.name, 'Daingsilog: fried milkfish, garlic rice and egg');

    final third = nextAlternative(next);
    expect(third.name, 'Lugaw with egg and toasted garlic');
    // The 20 new dishes follow the original 10, in bank order.
    expect(nextAlternative(third).name, startsWith('Longsilog'));
  });

  test('swapping walks every dish for the slot in bank order, then wraps', () {
    for (final slot in MealSlot.values) {
      final start = sampleWeek().first.meal(slot)!;
      final seen = <String>[start.name];
      for (var m = nextAlternative(start); m.name != start.name; m = nextAlternative(m)) {
        seen.add(m.name);
        expect(seen.length, lessThan(40), reason: 'swap never wrapped for ${slot.name}');
      }
      final inBank = [
        for (final m in mealBank)
          if (m.slot == slot) m.name,
      ];
      expect(seen, inBank, reason: slot.name);
      expect(seen.toSet(), hasLength(seen.length), reason: 'repeat in ${slot.name}');
    }
  });

  test('every bank dish can be swapped in, in each slot it is eaten at', () {
    final offered = {for (final m in mealBank) '${m.id}/${m.slot.name}'};
    for (final bank in sampleBankMeals) {
      expect(
        mealBank.any((m) => m.id == bank.id),
        isTrue,
        reason: '${bank.id} is not offered at all',
      );
    }
    // The 20 new dishes are offered at every slot they list.
    for (final bank in sampleBankMeals.skip(10)) {
      for (final slot in bank.slots) {
        expect(offered, contains('${bank.id}/${slot.name}'), reason: bank.id);
      }
    }
    expect(mealBank.map((m) => m.slot).toSet(), MealSlot.values.toSet());
  });

  test('a swapped-in new dish carries the bank kcal and price', () {
    final lunch = sampleWeek().first.meal(MealSlot.lunch)!;
    var m = nextAlternative(lunch);
    while (m.id != 'menudo') {
      m = nextAlternative(m);
    }
    final bank = sampleBankMeals.firstWhere((b) => b.id == 'menudo');
    expect(m.kcal, bank.kcal);
    expect(m.pricePhp, bank.pricePhp);
    expect(m.slot, MealSlot.lunch);
  });

  test('every slot has at least two options to swap between', () {
    for (final slot in MealSlot.values) {
      final first = sampleWeek().first.meal(slot)!;
      expect(nextAlternative(first).name, isNot(first.name), reason: slot.name);
    }
  });

  test('every sample day is within 3% of the default brief\'s calorie target', () {
    // The sample week is what the app shows without a server, under the
    // pill "2,087 kcal/day"; a day far over it would contradict the pill.
    final target = PlanDraft().brief.targetKcal;
    for (final day in sampleWeek()) {
      expect(
        day.kcal,
        inInclusiveRange(target * 0.97, target * 1.03),
        reason: '${day.weekday.name} is ${day.kcal} kcal against $target',
      );
    }
  });

  test('sample servings are ones the planner may plan', () {
    final allowed = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    for (final day in sampleWeek()) {
      for (final meal in day.meals) {
        expect(allowed, contains(meal.servings), reason: meal.name);
      }
    }
  });

  test('every sample meal carries its bank id and ingredients', () {
    for (final day in sampleWeek()) {
      for (final meal in day.meals) {
        expect(meal.id, isNotNull, reason: meal.name);
        expect(meal.ingredients, isNotEmpty, reason: meal.name);
      }
    }
    for (final meal in mealBank) {
      expect(meal.id, isNotNull);
      expect(meal.ingredients, isNotEmpty);
    }
  });

  test('sample prices are the bank prices at the planned servings, Monday adds up to 161 and the week to 1105', () {
    final monday = sampleWeek().first;
    expect(monday.meals.map((m) => m.pricePhp), [63, 57, 24, 17]);
    expect(monday.pricePhp, 161);
    expect(sampleWeek().fold(0, (s, d) => s + d.pricePhp), 1105);
  });

  test('a swapped-in alternative carries its own ingredients', () {
    final breakfast = sampleWeek().first.meal(MealSlot.breakfast)!;
    final next = nextAlternative(breakfast);
    expect(next.id, 'daingsilog');
    expect(next.ingredients.map((i) => i.id), contains('daing-bangus'));
    expect(next.ingredients.map((i) => i.id), isNot(contains('beef-tapa')));
  });
}
