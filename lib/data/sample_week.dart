import '../mealpal_ph.dart';
import 'sample_bank.dart';

/// Stand-in for the meal bank + AI selection. Every meal comes from
/// [sampleBankMeals], so its price, kcal and ingredients are the bank's.
/// Monday keeps the approved mockup's dishes, now at the servings that land
/// it on the default target; the other days rotate a few alternates so the
/// day strip has something to show. Replace with the real recommender later.

PlannedMeal _from(String id, MealSlot slot) => plannedMealFrom(
      sampleBankMeals.firstWhere((m) => m.id == id),
      slot,
    );

final _tapsilog = _from('tapsilog', MealSlot.breakfast);
final _daingsilog = _from('daingsilog', MealSlot.breakfast);
final _lugaw = _from('lugaw', MealSlot.breakfast);
final _tinola = _from('tinola', MealSlot.lunch);
final _adobo = _from('adobo', MealSlot.lunch);
final _munggo = _from('munggo', MealSlot.dinner);
final _sinigang = _from('sinigang', MealSlot.dinner);
final _pinakbet = _from('pinakbet', MealSlot.dinner);
final _sabaPeanuts = _from('saba-peanuts', MealSlot.snack);
final _boiledSaba = _from('boiled-saba', MealSlot.snack);

/// Every meal the stand-in bank knows, in slot order. Swapping a meal walks
/// this list within the meal's slot.
final List<PlannedMeal> mealBank = [
  _tapsilog,
  _daingsilog,
  _lugaw,
  _tinola,
  _adobo,
  _munggo,
  _sinigang,
  _pinakbet,
  _sabaPeanuts,
  _boiledSaba,
  ..._newerMeals,
];

/// The dishes added after the first ten, each offered at every slot it lists,
/// in bank order. The first ten keep the single slot they were first offered
/// at, so their swap cycles do not move.
final List<PlannedMeal> _newerMeals = [
  for (final bank in sampleBankMeals.skip(_firstTen))
    for (final slot in bank.slots) plannedMealFrom(bank, slot),
];

const _firstTen = 10;

/// The next option in [mealBank] for the same slot as [meal], wrapping round
/// to the first. Meals are matched by name, so a meal that is not in the bank
/// starts the cycle at the slot's first option.
PlannedMeal nextAlternative(PlannedMeal meal) {
  final options = [for (final m in mealBank) if (m.slot == meal.slot) m];
  final i = options.indexWhere((m) => m.name == meal.name);
  return options[(i + 1) % options.length];
}

/// [meal] planned at [servings] of the bank's portion, as the planner may
/// (0.5 to 2): kcal and price scale with it.
PlannedMeal _at(PlannedMeal meal, double servings) => plannedMealFrom(
      sampleBankMeals.firstWhere((b) => b.id == meal.id),
      meal.slot,
      servings: servings,
    );

/// The sample week as the offline planner serves it. Every day lands within
/// 3% of the default brief's 2,087 kcal target (a test holds it there): the
/// bank's dishes run bigger than the old placeholders, so Monday's approved
/// dishes keep their place and take smaller servings rather than being swapped
/// for lighter ones.
List<DayPlan> sampleWeek() => [
      DayPlan(weekday: Weekday.mon, meals: [_at(_tapsilog, 0.75), _tinola, _at(_munggo, 0.75), _at(_sabaPeanuts, 0.75)]),
      DayPlan(weekday: Weekday.tue, meals: [_at(_daingsilog, 0.75), _tinola, _at(_sinigang, 0.75), _at(_sabaPeanuts, 0.75)]),
      DayPlan(weekday: Weekday.wed, meals: [_lugaw, _adobo, _munggo, _at(_boiledSaba, 0.75)]),
      DayPlan(weekday: Weekday.thu, meals: [_at(_tapsilog, 0.75), _at(_adobo, 0.75), _pinakbet, _sabaPeanuts]),
      DayPlan(weekday: Weekday.fri, meals: [_at(_daingsilog, 0.75), _tinola, _at(_munggo, 0.75), _boiledSaba]),
      DayPlan(weekday: Weekday.sat, meals: [_at(_lugaw, 0.75), _adobo, _sinigang, _sabaPeanuts]),
      DayPlan(weekday: Weekday.sun, meals: [_at(_tapsilog, 0.75), _tinola, _pinakbet, _at(_boiledSaba, 0.75)]),
    ];

/// A fixed list for widget tests. The app builds its list with
/// [groceryListFor] and does not use this.
GroceryList sampleGroceryList({required int budgetPhp}) => GroceryList(
      budgetPhp: budgetPhp,
      sections: const [
        GrocerySection(
          storeId: 'palengke',
          name: 'Wet market',
          monogram: 'W',
          local: true,
          items: [
            GroceryItem(name: 'Beef tapa cut', quantity: '400 g', pricePhp: 180, kind: GroceryKind.meat),
            GroceryItem(name: 'Chicken', quantity: 'Tinola cut · 500 g', pricePhp: 140, kind: GroceryKind.poultry),
            GroceryItem(name: 'Water spinach', quantity: '2 bundles', pricePhp: 40, kind: GroceryKind.produce),
            GroceryItem(name: 'Moringa', quantity: '1 bundle', pricePhp: 25, kind: GroceryKind.produce),
            GroceryItem(name: 'Saba bananas', quantity: '1 kg', pricePhp: 60, kind: GroceryKind.fruit),
            GroceryItem(name: 'Tomato, onion, garlic, ginger', quantity: 'Aromatics mix', pricePhp: 100, kind: GroceryKind.aromatics),
          ],
        ),
        GrocerySection(
          storeId: 'puregold',
          name: 'Puregold',
          monogram: 'P',
          local: false,
          items: [
            GroceryItem(name: 'Rice', quantity: '5 kg', pricePhp: 285, kind: GroceryKind.grain),
            GroceryItem(name: 'Eggs', quantity: '1 dozen', pricePhp: 95, kind: GroceryKind.egg),
            GroceryItem(name: 'Firm tofu', quantity: '2 blocks', pricePhp: 50, kind: GroceryKind.legume),
            GroceryItem(name: 'Mung beans', quantity: '250 g', pricePhp: 45, kind: GroceryKind.legume),
            GroceryItem(name: 'Cooking oil', quantity: '1 L', pricePhp: 35, kind: GroceryKind.oil),
            GroceryItem(name: 'Peanuts', quantity: '200 g', pricePhp: 20, kind: GroceryKind.legume),
          ],
        ),
        GrocerySection(
          storeId: 'sari-sari',
          name: 'Corner store',
          note: '(top-up)',
          monogram: 'C',
          local: true,
          items: [
            GroceryItem(name: 'Soy sauce', quantity: '385 ml', pricePhp: 32, kind: GroceryKind.condiment),
            GroceryItem(name: 'Vinegar', quantity: '385 ml', pricePhp: 28, kind: GroceryKind.condiment),
            GroceryItem(name: 'Salt and pepper', quantity: 'Pantry top-up', pricePhp: 18, kind: GroceryKind.spice),
          ],
        ),
      ],
    );
