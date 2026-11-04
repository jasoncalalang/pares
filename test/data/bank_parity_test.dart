import 'dart:convert';
import 'dart:io';

import 'package:mealpal_ph/data/sample_bank.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:test/test.dart';

/// The server's meal-bank.json is the single source; the offline sample bank
/// in lib/data is a copy. This test is what stops the two drifting apart.
void main() {
  final json =
      jsonDecode(
            File('server/src/main/resources/meal-bank.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final catalog = json['ingredients'] as Map<String, dynamic>;
  final meals = (json['meals'] as List).cast<Map<String, dynamic>>();

  test('the catalog has the same ingredients, in the same terms', () {
    expect(sampleIngredients.keys.toSet(), catalog.keys.toSet());
    catalog.forEach((id, raw) {
      final e = raw as Map<String, dynamic>;
      final mine = sampleIngredients[id]!;
      expect(mine.name, e['name'], reason: id);
      expect(mine.kind.name, e['kind'], reason: id);
      expect(mine.unit.name, e['unit'], reason: id);
      expect(mine.pricePhpPerUnit, (e['pricePhpPerUnit'] as num).toDouble(),
          reason: id);
    });
  });

  test('the meals match on id, name, slots, kcal, price and image', () {
    expect(sampleBankMeals.map((m) => m.id), meals.map((m) => m['id']));
    for (var i = 0; i < meals.length; i++) {
      final j = meals[i];
      final m = sampleBankMeals[i];
      expect(m.name, j['name'], reason: m.id);
      expect(m.slots.map((s) => s.name), j['slots'], reason: m.id);
      expect(m.kcal, j['kcal'], reason: m.id);
      expect(m.pricePhp, j['pricePhp'], reason: m.id);
      expect(m.image, j['image'], reason: m.id);
    }
  });

  test('the ingredient refs match, in the same order', () {
    for (var i = 0; i < meals.length; i++) {
      final refs = (meals[i]['ingredients'] as List).cast<Map<String, dynamic>>();
      final mine = sampleBankMeals[i].ingredients;
      expect(mine.map((r) => r.id), refs.map((r) => r['id']),
          reason: meals[i]['id'] as String);
      expect(mine.map((r) => r.qty),
          refs.map((r) => (r['qty'] as num).toDouble()),
          reason: meals[i]['id'] as String);
    }
  });

  test('every meal price is the rounded cost of its ingredients', () {
    for (final m in sampleBankMeals) {
      final cost = m.ingredients.fold<double>(
        0,
        (sum, r) => sum + r.qty * sampleIngredients[r.id]!.pricePhpPerUnit,
      );
      expect(m.pricePhp, (cost + 1e-9).round(), reason: m.id);
    }
  });

  test('a meal planned at 1.5 servings scales quantities and prices', () {
    final tapsilog = sampleBankMeals.firstWhere((m) => m.id == 'tapsilog');
    final planned = plannedMealFrom(tapsilog, MealSlot.breakfast, servings: 1.5);
    expect(planned.id, 'tapsilog');
    expect(planned.servings, 1.5);
    // 84.40 a serving: 126.60 for one and a half, rounded once.
    expect(planned.pricePhp, 127);
    final rice = planned.ingredients.firstWhere((i) => i.id == 'rice');
    expect(rice.qty, 135.0);
    expect(rice.pricePhp, 6.75);
    expect(rice.name, 'White rice');
    expect(rice.kind, GroceryKind.grain);
    expect(rice.unit, IngredientUnit.g);
  });

  test('the list total for a tight week matches the figure the server checks', () {
    MealSlot s(String id) => MealSlot.values.firstWhere((x) => x.name == id);
    PlannedMeal m(String id, String slot, double servings) => plannedMealFrom(
      sampleBankMeals.firstWhere((b) => b.id == id),
      s(slot),
      servings: servings,
    );
    final meals = [
      m('tapsilog', 'breakfast', 0.75),
      m('tinola', 'lunch', 1),
      m('adobo', 'dinner', 1.25),
      m('boiled-saba', 'snack', 0.75),
    ];
    final list = groceryListFor(
      week: [for (final d in Weekday.values) DayPlan(weekday: d, meals: meals)],
      stops: const [
        ShoppingStop(id: 'palengke', name: 'Wet market', monogram: 'W', type: StoreType.wetMarket),
      ],
      budgetPhp: 1400,
    );
    // The server rejects this week at 1,400 with "The week costs 1,412".
    expect(list.totalPhp, 1412);
  });
}
