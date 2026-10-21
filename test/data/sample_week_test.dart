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
}
