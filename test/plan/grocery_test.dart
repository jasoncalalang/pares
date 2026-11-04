import 'package:mealpal_ph/data/sample_week.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:test/test.dart';

MealIngredient ing(
  String id,
  GroceryKind kind,
  double qty,
  double price, {
  IngredientUnit unit = IngredientUnit.g,
  String? name,
}) => MealIngredient(
  id: id,
  name: name ?? id,
  kind: kind,
  unit: unit,
  qty: qty,
  pricePhp: price,
);

DayPlan day(Weekday d, List<List<MealIngredient>> meals) => DayPlan(
  weekday: d,
  meals: [
    for (var i = 0; i < meals.length; i++)
      PlannedMeal(
        slot: MealSlot.values[i],
        name: 'Meal $i',
        kcal: 500,
        pricePhp: 50,
        ingredients: meals[i],
      ),
  ],
);

ShoppingStop stop(String id, StoreType type, [String? name]) => ShoppingStop(
  id: id,
  name: name ?? id,
  monogram: id[0].toUpperCase(),
  type: type,
);

const allStops = [
  ShoppingStop(id: 'palengke', name: 'Wet market', monogram: 'W', type: StoreType.wetMarket),
  ShoppingStop(id: 'puregold', name: 'Puregold', monogram: 'P', type: StoreType.supermarket),
  ShoppingStop(id: 'sari-sari', name: 'Corner store', monogram: 'C', type: StoreType.sariSari),
];

GroceryList listFor(
  List<MealIngredient> items, {
  List<ShoppingStop> stops = allStops,
  int budget = 2500,
}) => groceryListFor(
  week: [
    day(Weekday.mon, [items]),
  ],
  stops: stops,
  budgetPhp: budget,
);

GrocerySection? section(GroceryList l, String id) {
  for (final s in l.sections) {
    if (s.storeId == id) return s;
  }
  return null;
}

void main() {
  group('quantity text rounds up, never down', () {
    String q(double v, IngredientUnit u) => groceryQuantityText(v, u);
    test('grams under 1000 go to the next 5', () {
      expect(q(1, IngredientUnit.g), '5 g');
      expect(q(5, IngredientUnit.g), '5 g');
      expect(q(5.01, IngredientUnit.g), '10 g');
      expect(q(448.5, IngredientUnit.g), '450 g');
      expect(q(450, IngredientUnit.g), '450 g');
      expect(q(995, IngredientUnit.g), '995 g');
    });
    test('1000 g and over is kilograms rounded up to 0.1', () {
      expect(q(1000, IngredientUnit.g), '1 kg');
      expect(q(1201, IngredientUnit.g), '1.3 kg');
      expect(q(1300, IngredientUnit.g), '1.3 kg');
      expect(q(2000, IngredientUnit.g), '2 kg');
      expect(q(2000.4, IngredientUnit.g), '2.1 kg');
    });
    test('a sum that only looks over by float noise is not rounded up', () {
      expect(q(450.00000000000006, IngredientUnit.g), '450 g');
      expect(q(1300.0000000000002, IngredientUnit.g), '1.3 kg');
    });
    test('a gram total that rounds up to 1000 reads as 1 kg', () {
      expect(q(997, IngredientUnit.g), '1 kg');
    });
    test('millilitres follow the same rule with L', () {
      expect(q(30, IngredientUnit.ml), '30 ml');
      expect(q(32, IngredientUnit.ml), '35 ml');
      expect(q(1000, IngredientUnit.ml), '1 L');
      expect(q(1450, IngredientUnit.ml), '1.5 L');
    });
    test('pieces are whole numbers', () {
      expect(q(1, IngredientUnit.pc), '1 pc');
      expect(q(1.2, IngredientUnit.pc), '2 pcs');
      expect(q(9, IngredientUnit.pc), '9 pcs');
    });
  });

  group('aggregation', () {
    test('adds quantities and exact prices across days, then rounds', () {
      final list = groceryListFor(
        week: [
          day(Weekday.mon, [
            [ing('rice', GroceryKind.grain, 90, 4.5, name: 'White rice')],
            [ing('rice', GroceryKind.grain, 135, 6.75, name: 'White rice')],
          ]),
          day(Weekday.tue, [
            [ing('rice', GroceryKind.grain, 90, 4.5, name: 'White rice')],
          ]),
        ],
        stops: allStops,
        budgetPhp: 2500,
      );
      final items = list.sections.expand((s) => s.items).toList();
      expect(items, hasLength(1));
      expect(items.single.name, 'White rice');
      expect(items.single.quantity, '315 g');
      // 4.5 + 6.75 + 4.5 = 15.75, rounded only at the end.
      expect(items.single.pricePhp, 16);
      expect(items.single.kind, GroceryKind.grain);
    });

    test('line prices round half up, only after summing', () {
      final list = listFor([
        ing('a', GroceryKind.grain, 10, 0.4),
        ing('a', GroceryKind.grain, 10, 0.4),
        ing('b', GroceryKind.grain, 10, 2.5),
      ]);
      final byName = {
        for (final i in list.sections.expand((s) => s.items)) i.name: i,
      };
      expect(byName['a']!.pricePhp, 1);
      expect(byName['b']!.pricePhp, 3);
    });

    test('an empty week gives a list with no sections', () {
      final list = groceryListFor(week: const [], stops: allStops, budgetPhp: 900);
      expect(list.sections, isEmpty);
      expect(list.budgetPhp, 900);
      expect(list.totalPhp, 0);
    });

    test('meals without ingredients add nothing', () {
      final list = listFor(const []);
      expect(list.sections, isEmpty);
    });

    test('the list keeps the budget it was given', () {
      expect(listFor([ing('x', GroceryKind.grain, 1, 1)], budget: 1234).budgetPhp, 1234);
    });
  });

  group('store assignment', () {
    final all = [
      ing('beef', GroceryKind.meat, 100, 45),
      ing('hen', GroceryKind.poultry, 100, 20),
      ing('bangus', GroceryKind.fish, 100, 24),
      ing('kangkong', GroceryKind.produce, 100, 6),
      ing('saba', GroceryKind.fruit, 100, 8),
      ing('garlic', GroceryKind.aromatics, 100, 15),
      ing('rice', GroceryKind.grain, 100, 5),
      ing('egg', GroceryKind.egg, 2, 16, unit: IngredientUnit.pc),
      ing('mung', GroceryKind.legume, 100, 12),
      ing('oil', GroceryKind.oil, 100, 11, unit: IngredientUnit.ml),
      ing('soy', GroceryKind.condiment, 100, 5, unit: IngredientUnit.ml),
      ing('pepper', GroceryKind.spice, 10, 8),
      ing('peanuts', GroceryKind.pantry, 100, 20),
    ];

    Set<String> names(GrocerySection? s) =>
        {for (final i in s?.items ?? const <GroceryItem>[]) i.name};

    test('fresh food goes to the wet market, the rest to the supermarket', () {
      final list = listFor(all);
      expect(names(section(list, 'palengke')), {
        'beef', 'hen', 'bangus', 'kangkong', 'saba', 'garlic', 'egg',
      });
      expect(names(section(list, 'puregold')), {
        'rice', 'mung', 'oil', 'soy', 'pepper', 'peanuts',
      });
      expect(section(list, 'sari-sari'), isNull);
      expect(section(list, 'elsewhere'), isNull);
    });

    test('with only a supermarket, it sells everything', () {
      final list = listFor(all, stops: [stop('puregold', StoreType.supermarket)]);
      expect(list.sections, hasLength(1));
      expect(list.sections.single.items, hasLength(all.length));
    });

    test('pantry kinds fall back to the wet market with no supermarket', () {
      final list = listFor(all, stops: [stop('palengke', StoreType.wetMarket)]);
      expect(list.sections, hasLength(1));
      expect(list.sections.single.items, hasLength(all.length));
    });

    test('fresh falls back along the order: hypermarket, club, online', () {
      final meat = [ing('beef', GroceryKind.meat, 100, 45)];
      for (final t in [
        StoreType.hypermarket,
        StoreType.warehouseClub,
        StoreType.online,
      ]) {
        final list = listFor(meat, stops: [stop('s', StoreType.sariSari), stop('x', t)]);
        expect(list.sections.single.storeId, 'x', reason: t.name);
      }
    });

    test('a sari-sari store never gets meat, fish, produce or fruit', () {
      final only = [stop('sari-sari', StoreType.sariSari)];
      for (final k in [
        GroceryKind.meat,
        GroceryKind.poultry,
        GroceryKind.fish,
        GroceryKind.produce,
        GroceryKind.fruit,
      ]) {
        final list = listFor([ing('x', k, 100, 10)], stops: only);
        expect(list.sections.single.storeId, 'elsewhere', reason: k.name);
      }
    });

    test('a sari-sari store takes aromatics, eggs and pantry goods', () {
      final only = [stop('sari-sari', StoreType.sariSari)];
      for (final k in [
        GroceryKind.aromatics,
        GroceryKind.egg,
        GroceryKind.grain,
        GroceryKind.oil,
        GroceryKind.condiment,
      ]) {
        final list = listFor([ing('x', k, 100, 10)], stops: only);
        expect(list.sections.single.storeId, 'sari-sari', reason: k.name);
      }
    });

    test('a convenience store takes eggs and pantry goods, not aromatics', () {
      final only = [stop('7-eleven', StoreType.convenience)];
      expect(
        listFor([ing('x', GroceryKind.egg, 1, 8)], stops: only).sections.single.storeId,
        '7-eleven',
      );
      expect(
        listFor([ing('x', GroceryKind.condiment, 1, 8)], stops: only).sections.single.storeId,
        '7-eleven',
      );
      expect(
        listFor([ing('x', GroceryKind.aromatics, 1, 8)], stops: only).sections.single.storeId,
        'elsewhere',
      );
    });

    test('eggs prefer the wet market, aromatics prefer it over a sari-sari', () {
      final list = listFor([
        ing('egg', GroceryKind.egg, 2, 16, unit: IngredientUnit.pc),
        ing('garlic', GroceryKind.aromatics, 10, 1.5),
      ]);
      expect(section(list, 'palengke')!.items, hasLength(2));
    });

    test('several stops of one type: the first in stop order gets it all', () {
      final list = listFor(
        [
          ing('rice', GroceryKind.grain, 100, 5),
          ing('oil', GroceryKind.oil, 100, 11, unit: IngredientUnit.ml),
        ],
        stops: [
          stop('savemore', StoreType.supermarket),
          stop('puregold', StoreType.supermarket),
        ],
      );
      expect(list.sections, hasLength(1));
      expect(list.sections.single.storeId, 'savemore');
    });

    test('hypermarkets and clubs are used in that order', () {
      final list = listFor(
        [ing('rice', GroceryKind.grain, 100, 5)],
        stops: [
          stop('club', StoreType.warehouseClub),
          stop('hyper', StoreType.hypermarket),
        ],
      );
      expect(list.sections.single.storeId, 'hyper');
    });
  });

  group('Elsewhere', () {
    test('holds what no picked store sells, and comes last', () {
      final list = listFor(
        [
          ing('beef', GroceryKind.meat, 100, 45),
          ing('oil', GroceryKind.oil, 100, 11, unit: IngredientUnit.ml),
        ],
        stops: [stop('sari-sari', StoreType.sariSari, 'Corner store')],
      );
      expect(list.sections.map((s) => s.storeId), ['sari-sari', 'elsewhere']);
      final e = list.sections.last;
      expect(e.name, 'Elsewhere');
      expect(e.note, '(not sold at the stores you picked)');
      expect(e.monogram, 'E');
      expect(e.local, isFalse);
      expect(e.items.single.name, 'beef');
    });

    test('with no stops picked, everything is Elsewhere', () {
      final list = listFor([ing('beef', GroceryKind.meat, 100, 45)], stops: const []);
      expect(list.sections.single.storeId, 'elsewhere');
    });
  });

  group('order', () {
    test('sections follow the store type rank, not the stop order', () {
      final stops = [
        stop('corner', StoreType.sariSari),
        stop('7', StoreType.convenience),
        stop('grab', StoreType.online),
        stop('club', StoreType.warehouseClub),
        stop('hyper', StoreType.hypermarket),
        stop('pure', StoreType.supermarket),
        stop('wet', StoreType.wetMarket),
      ];
      // Fresh food and eggs go to the wet market, pantry goods to the
      // supermarket; the other stops sell nothing here.
      final list = listFor([
        ing('a', GroceryKind.meat, 1, 1),
        ing('b', GroceryKind.grain, 1, 1),
        ing('c', GroceryKind.egg, 1, 1),
      ], stops: stops);
      expect(list.sections.map((s) => s.storeId), ['wet', 'pure']);

      final onlyLocal = listFor([
        ing('a', GroceryKind.grain, 1, 1),
      ], stops: [stop('corner', StoreType.sariSari), stop('7', StoreType.convenience)]);
      // Convenience ranks before sari-sari, and the grain goes to the first
      // type in the pantry order, which is sari-sari.
      expect(onlyLocal.sections.map((s) => s.storeId), ['corner']);

      final two = listFor(
        [
          ing('a', GroceryKind.grain, 1, 1),
          ing('m', GroceryKind.meat, 1, 1),
        ],
        stops: [
          stop('club', StoreType.warehouseClub),
          stop('wet', StoreType.wetMarket),
        ],
      );
      expect(two.sections.map((s) => s.storeId), ['wet', 'club']);
    });

    test('local is true for the wet market and the sari-sari store only', () {
      final list = listFor([
        ing('m', GroceryKind.meat, 1, 1),
        ing('r', GroceryKind.grain, 1, 1),
      ]);
      expect(section(list, 'palengke')!.local, isTrue);
      expect(section(list, 'puregold')!.local, isFalse);
      expect(
        listFor(
          [ing('r', GroceryKind.grain, 1, 1)],
          stops: [stop('corner', StoreType.sariSari)],
        ).sections.single.local,
        isTrue,
      );
    });

    test('no section carries a top-up note and none is empty', () {
      final list = listFor([ing('r', GroceryKind.grain, 1, 1)]);
      expect(list.sections.every((s) => s.note == null), isTrue);
      expect(list.sections.every((s) => s.items.isNotEmpty), isTrue);
    });

    test('items run by kind, then by name', () {
      final list = listFor(
        [
          ing('z', GroceryKind.oil, 1, 1, name: 'Zed oil'),
          ing('a', GroceryKind.condiment, 1, 1, name: 'Apple vinegar'),
          ing('b', GroceryKind.grain, 1, 1, name: 'Brown rice'),
          ing('c', GroceryKind.grain, 1, 1, name: 'Amber rice'),
        ],
        stops: [stop('pure', StoreType.supermarket)],
      );
      expect(list.sections.single.items.map((i) => i.name), [
        'Amber rice',
        'Brown rice',
        'Zed oil',
        'Apple vinegar',
      ]);
    });
  });

  group('a week whose meals carry no ingredients', () {
    test('is flagged, unlike an empty week', () {
      final none = groceryListFor(
        week: [day(Weekday.mon, [<MealIngredient>[]])],
        stops: allStops,
        budgetPhp: 2500,
      );
      expect(none.sections, isEmpty);
      expect(none.mealsLackIngredients, isTrue);
      final empty = groceryListFor(week: [], stops: allStops, budgetPhp: 2500);
      expect(empty.mealsLackIngredients, isFalse);
    });
  });

  group('the sample week', () {
    test('its list total is within 2% of the sum of the day prices', () {
      final week = sampleWeek();
      final dayTotal = week.fold(0, (s, d) => s + d.pricePhp);
      final list = groceryListFor(
        week: week,
        stops: allStops,
        budgetPhp: 2500,
      );
      expect(
        (list.totalPhp - dayTotal).abs() / dayTotal,
        lessThan(0.02),
        reason: 'list ${list.totalPhp} vs days $dayTotal',
      );
    });

    test('shopping a wet market and a supermarket splits fresh from pantry', () {
      final list = groceryListFor(
        week: sampleWeek(),
        stops: allStops,
        budgetPhp: 2500,
      );
      expect(list.sections.map((s) => s.storeId), ['palengke', 'puregold']);
      final wet = section(list, 'palengke')!.items.map((i) => i.name);
      expect(wet, containsAll(['Beef tapa cut', 'Egg', 'Saba banana']));
      final shop = section(list, 'puregold')!.items.map((i) => i.name);
      expect(shop, containsAll(['White rice', 'Cooking oil']));
      expect(shop, isNot(contains('Egg')));
    });
  });
}
