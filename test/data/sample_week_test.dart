import 'package:mealpal_ph/data/sample_week.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:test/test.dart';

void main() {
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
    // Past the last breakfast in the bank it wraps to the first.
    expect(nextAlternative(third).name, breakfast.name);
  });

  test('every slot has at least two options to swap between', () {
    for (final slot in MealSlot.values) {
      final first = sampleWeek().first.meal(slot)!;
      expect(nextAlternative(first).name, isNot(first.name), reason: slot.name);
    }
  });

  test('every sample meal carries its bank id and ingredients', () {
    for (final day in sampleWeek()) {
      for (final meal in day.meals) {
        expect(meal.id, isNotNull, reason: meal.name);
        expect(meal.ingredients, isNotEmpty, reason: meal.name);
        expect(meal.servings, 1);
      }
    }
    for (final meal in mealBank) {
      expect(meal.id, isNotNull);
      expect(meal.ingredients, isNotEmpty);
    }
  });

  test('sample prices are the bank prices, Monday adds up to 195 and the week to 1268', () {
    final monday = sampleWeek().first;
    expect(monday.meals.map((m) => m.pricePhp), [84, 57, 32, 22]);
    expect(monday.pricePhp, 195);
    expect(sampleWeek().fold(0, (s, d) => s + d.pricePhp), 1268);
  });

  test('a swapped-in alternative carries its own ingredients', () {
    final breakfast = sampleWeek().first.meal(MealSlot.breakfast)!;
    final next = nextAlternative(breakfast);
    expect(next.id, 'daingsilog');
    expect(next.ingredients.map((i) => i.id), contains('daing-bangus'));
    expect(next.ingredients.map((i) => i.id), isNot(contains('beef-tapa')));
  });
}
