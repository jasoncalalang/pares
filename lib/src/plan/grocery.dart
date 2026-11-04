import '../stores/catalog.dart';
import 'plan_models.dart';

/// A store the shopper picked, in the shape the grocery list needs. The app
/// builds these from its store tiles and the catalog's [StoreType].
class ShoppingStop {
  const ShoppingStop({
    required this.id,
    required this.name,
    required this.monogram,
    required this.type,
  });

  final String id;
  final String name;
  final String monogram;
  final StoreType type;
}

const _elsewhereId = 'elsewhere';

const _fresh = [
  StoreType.wetMarket,
  StoreType.supermarket,
  StoreType.hypermarket,
  StoreType.warehouseClub,
  StoreType.online,
];

const _aromatics = [..._fresh, StoreType.sariSari];

const _egg = [..._fresh, StoreType.sariSari, StoreType.convenience];

const _pantry = [
  StoreType.supermarket,
  StoreType.hypermarket,
  StoreType.warehouseClub,
  StoreType.wetMarket,
  StoreType.online,
  StoreType.sariSari,
  StoreType.convenience,
];

/// The kinds of store that sell [kind], most natural first. A type that is
/// not listed never gets that kind: a sari-sari store never sells fresh meat.
List<StoreType> _preference(GroceryKind kind) => switch (kind) {
  GroceryKind.meat ||
  GroceryKind.poultry ||
  GroceryKind.fish ||
  GroceryKind.produce ||
  GroceryKind.fruit => _fresh,
  GroceryKind.aromatics => _aromatics,
  GroceryKind.egg => _egg,
  GroceryKind.grain ||
  GroceryKind.legume ||
  GroceryKind.oil ||
  GroceryKind.condiment ||
  GroceryKind.spice ||
  GroceryKind.pantry => _pantry,
};

/// Section order on the list.
const _rank = [
  StoreType.wetMarket,
  StoreType.supermarket,
  StoreType.hypermarket,
  StoreType.warehouseClub,
  StoreType.online,
  StoreType.convenience,
  StoreType.sariSari,
];

/// Quantity noise below this is float error from summing, not real grams.
const _epsilon = 1e-6;

/// "450 g", "1.3 kg", "35 ml", "1.5 L", "9 pcs". Always rounded up: the
/// shopper buys at least what the week uses.
String groceryQuantityText(double qty, IngredientUnit unit) {
  switch (unit) {
    case IngredientUnit.pc:
      final n = (qty - _epsilon).ceil().clamp(1, 1 << 30);
      return n == 1 ? '1 pc' : '$n pcs';
    case IngredientUnit.g:
      return _metric(qty, 'g', 'kg');
    case IngredientUnit.ml:
      return _metric(qty, 'ml', 'L');
  }
}

String _metric(double qty, String small, String large) {
  if (qty < 1000) {
    final rounded = ((qty - _epsilon) / 5).ceil().clamp(1, 200) * 5;
    if (rounded < 1000) return '$rounded $small';
  }
  final tenths = ((qty - _epsilon) / 100).ceil();
  final whole = tenths ~/ 10;
  final rest = tenths % 10;
  return rest == 0 ? '$whole $large' : '$whole.$rest $large';
}

class _Line {
  _Line(this.first);

  final MealIngredient first;
  double qty = 0;
  double price = 0;
}

/// The shopping list for [week], split by the [stops] the shopper picked.
///
/// Every meal's ingredients are summed by ingredient id across the week; the
/// exact prices are summed too and rounded once, at the end. An empty week
/// gives a list with no sections.
GroceryList groceryListFor({
  required List<DayPlan> week,
  required List<ShoppingStop> stops,
  required int budgetPhp,
}) {
  final lines = <String, _Line>{};
  for (final day in week) {
    for (final meal in day.meals) {
      for (final i in meal.ingredients) {
        final line = lines.putIfAbsent(i.id, () => _Line(i));
        line.qty += i.qty;
        line.price += i.pricePhp;
      }
    }
  }

  // The first picked stop of each type wins that type.
  final byType = <StoreType, ShoppingStop>{};
  for (final s in stops) {
    byType.putIfAbsent(s.type, () => s);
  }

  final grouped = <String, List<GroceryItem>>{};
  for (final line in lines.values) {
    final i = line.first;
    ShoppingStop? seller;
    for (final type in _preference(i.kind)) {
      seller = byType[type];
      if (seller != null) break;
    }
    grouped
        .putIfAbsent(seller?.id ?? _elsewhereId, () => [])
        .add(
          GroceryItem(
            id: i.id,
            name: i.name,
            quantity: groceryQuantityText(line.qty, i.unit),
            pricePhp: (line.price + 0.5 + _epsilon).floor(),
            kind: i.kind,
          ),
        );
  }

  int byKindThenName(GroceryItem a, GroceryItem b) {
    final k = a.kind.index.compareTo(b.kind.index);
    return k != 0 ? k : a.name.compareTo(b.name);
  }

  final picked = [
    for (final s in stops)
      if (byType[s.type] == s && grouped.containsKey(s.id)) s,
  ]..sort((a, b) => _rank.indexOf(a.type).compareTo(_rank.indexOf(b.type)));

  return GroceryList(
    budgetPhp: budgetPhp,
    sections: [
      for (final s in picked)
        GrocerySection(
          storeId: s.id,
          name: s.name,
          monogram: s.monogram,
          local: s.type == StoreType.wetMarket || s.type == StoreType.sariSari,
          items: grouped[s.id]!..sort(byKindThenName),
        ),
      if (grouped.containsKey(_elsewhereId))
        GrocerySection(
          storeId: _elsewhereId,
          name: 'Elsewhere',
          note: '(not sold at the stores you picked)',
          monogram: 'E',
          local: false,
          items: grouped[_elsewhereId]!..sort(byKindThenName),
        ),
    ],
  );
}
