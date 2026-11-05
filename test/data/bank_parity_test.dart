import 'dart:convert';
import 'dart:io';

import 'package:mealpal_ph/data/sample_bank.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:test/test.dart';

/// An exact decimal: [units] / 10^[scale]. Dart has no BigDecimal, and the
/// kcal rule must not drift in doubles, so numbers are read from the text the
/// JSON decoder prints back (the shortest form, which is the written literal).
class _Dec {
  _Dec(this.units, this.scale);

  factory _Dec.of(num n) {
    final text = n.toString();
    if (text.contains('e') || text.contains('E')) {
      throw FormatException('write $text as a plain decimal in meal-bank.json');
    }
    final dot = text.indexOf('.');
    if (dot < 0) return _Dec(BigInt.parse(text), 0);
    final scale = text.length - dot - 1;
    return _Dec(BigInt.parse(text.replaceFirst('.', '')), scale);
  }

  final BigInt units;
  final int scale;

  _Dec operator *(_Dec o) => _Dec(units * o.units, scale + o.scale);

  _Dec operator +(_Dec o) {
    final s = scale > o.scale ? scale : o.scale;
    BigInt up(_Dec d) => d.units * BigInt.from(10).pow(s - d.scale);
    return _Dec(up(this) + up(o), s);
  }

  /// Rounded to a whole number, halves up (the values are never negative).
  int roundHalfUp() {
    final den = BigInt.from(10).pow(scale);
    return ((units * BigInt.two + den) ~/ (den * BigInt.two)).toInt();
  }
}

/// kcal of one serving of [meal], from the JSON's own USDA fields:
/// round_half_up(sum(qty * gramsPerUnit * edibleFraction * kcalPer100g / 100)).
int _computedKcal(Map<String, dynamic> meal, Map<String, dynamic> catalog) {
  var total = _Dec(BigInt.zero, 0);
  for (final r in (meal['ingredients'] as List).cast<Map<String, dynamic>>()) {
    final ing = catalog[r['id']] as Map<String, dynamic>;
    var eaten = _Dec.of(r['qty'] as num) * _Dec.of(ing['gramsPerUnit'] as num);
    final edible = ing['edible'] as Map<String, dynamic>?;
    if (edible != null) eaten = eaten * _Dec.of(edible['fraction'] as num);
    total = total + eaten * _Dec.of(ing['kcalPer100g'] as num);
  }
  // The "/ 100" is two more decimal places.
  return _Dec(total.units, total.scale + 2).roundHalfUp();
}

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

  test('every meal kcal is computed from its ingredients\' USDA numbers', () {
    for (final m in meals) {
      expect(m['kcal'], _computedKcal(m, catalog), reason: m['id'] as String);
    }
  });

  test('the decimal helper rounds halves up and keeps decimals exact', () {
    expect(_Dec(BigInt.from(25), 1).roundHalfUp(), 3); // 2.5
    expect(_Dec(BigInt.from(24), 1).roundHalfUp(), 2); // 2.4
    expect(_Dec.of(0.1) + _Dec.of(0.2), isA<_Dec>()
        .having((d) => d.units, 'units', BigInt.from(3))
        .having((d) => d.scale, 'scale', 1));
  });

  test('every ingredient has USDA provenance the kcal can be traced to', () {
    catalog.forEach((id, raw) {
      final e = raw as Map<String, dynamic>;
      expect(e['kcalPer100g'], isA<num>(), reason: id);
      expect(e['gramsPerUnit'], isA<num>(), reason: id);
      final usda = e['usda'] as Map<String, dynamic>;
      expect(usda['fdcId'], isA<int>(), reason: id);
      expect(usda['description'], isNotEmpty, reason: id);
      expect(usda['match'], anyOf('exact', 'closest'), reason: id);
      if (usda['match'] == 'closest') {
        expect(usda['note'], isNotEmpty, reason: '$id needs a note');
      }
    });
  });

  test('the bank has 30 meals with unique ids', () {
    expect(meals, hasLength(30));
    expect(meals.map((m) => m['id']).toSet(), hasLength(30));
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
