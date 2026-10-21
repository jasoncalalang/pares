import '../mealpal_ph.dart';

/// Hand-written stand-in for the meal bank + AI selection. Monday is the
/// approved mockup; the other days rotate a few alternates so the day strip
/// has something to show. Replace with the real recommender later.

const _tapsilog = PlannedMeal(
  slot: MealSlot.breakfast,
  name: 'Tapsilog: beef tapa, garlic rice and egg',
  kcal: 560,
  pricePhp: 95,
  image: 'tapsilog',
);
const _tinola = PlannedMeal(
  slot: MealSlot.lunch,
  name: 'Chicken tinola with moringa and rice',
  kcal: 620,
  pricePhp: 75,
  image: 'tinola',
);
const _munggo = PlannedMeal(
  slot: MealSlot.dinner,
  name: 'Ginisang munggo with tofu, water spinach and rice',
  kcal: 560,
  pricePhp: 55,
  image: 'munggo',
);
const _sabaPeanuts = PlannedMeal(
  slot: MealSlot.snack,
  name: 'Saba banana and peanuts',
  kcal: 347,
  pricePhp: 25,
  image: 'saba-peanuts',
);

const _daingsilog = PlannedMeal(
  slot: MealSlot.breakfast,
  name: 'Daingsilog: fried milkfish, garlic rice and egg',
  kcal: 540,
  pricePhp: 80,
);
const _lugaw = PlannedMeal(
  slot: MealSlot.breakfast,
  name: 'Lugaw with egg and toasted garlic',
  kcal: 420,
  pricePhp: 35,
);
const _adobo = PlannedMeal(
  slot: MealSlot.lunch,
  name: 'Chicken adobo with rice',
  kcal: 650,
  pricePhp: 70,
);
const _sinigang = PlannedMeal(
  slot: MealSlot.dinner,
  name: 'Pork sinigang with rice',
  kcal: 610,
  pricePhp: 85,
);
const _pinakbet = PlannedMeal(
  slot: MealSlot.dinner,
  name: 'Pinakbet with rice',
  kcal: 480,
  pricePhp: 50,
);
const _boiledSaba = PlannedMeal(
  slot: MealSlot.snack,
  name: 'Boiled saba with grated coconut',
  kcal: 300,
  pricePhp: 20,
);

/// Every meal the stand-in bank knows, in slot order. Swapping a meal walks
/// this list within the meal's slot.
const List<PlannedMeal> mealBank = [
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
];

/// The next option in [mealBank] for the same slot as [meal], wrapping round
/// to the first. Meals are matched by name, so a meal that is not in the bank
/// starts the cycle at the slot's first option.
PlannedMeal nextAlternative(PlannedMeal meal) {
  final options = [for (final m in mealBank) if (m.slot == meal.slot) m];
  final i = options.indexWhere((m) => m.name == meal.name);
  return options[(i + 1) % options.length];
}

List<DayPlan> sampleWeek() => const [
      DayPlan(weekday: Weekday.mon, meals: [_tapsilog, _tinola, _munggo, _sabaPeanuts]),
      DayPlan(weekday: Weekday.tue, meals: [_daingsilog, _tinola, _sinigang, _sabaPeanuts]),
      DayPlan(weekday: Weekday.wed, meals: [_lugaw, _adobo, _munggo, _boiledSaba]),
      DayPlan(weekday: Weekday.thu, meals: [_tapsilog, _adobo, _pinakbet, _sabaPeanuts]),
      DayPlan(weekday: Weekday.fri, meals: [_daingsilog, _tinola, _munggo, _boiledSaba]),
      DayPlan(weekday: Weekday.sat, meals: [_lugaw, _adobo, _sinigang, _sabaPeanuts]),
      DayPlan(weekday: Weekday.sun, meals: [_tapsilog, _tinola, _pinakbet, _boiledSaba]),
    ];

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
