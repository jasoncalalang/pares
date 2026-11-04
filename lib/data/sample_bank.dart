import '../mealpal_ph.dart';

/// The offline copy of the server's meal bank
/// (`server/src/main/resources/meal-bank.json`), ingredients included.
/// test/data/bank_parity_test.dart fails if the two differ, so edit both
/// together. Quantities and unit prices are placeholder estimates until the
/// price checker's price book and the FNRI-based bank exist.

/// An ingredient the bank knows, priced per [unit].
class BankIngredient {
  const BankIngredient(this.name, this.kind, this.unit, this.pricePhpPerUnit);

  final String name;
  final GroceryKind kind;
  final IngredientUnit unit;
  final double pricePhpPerUnit;
}

/// How much of an ingredient one serving of a meal uses.
class BankIngredientRef {
  const BankIngredientRef(this.id, this.qty);

  final String id;
  final double qty;
}

class BankMeal {
  const BankMeal({
    required this.id,
    required this.name,
    required this.slots,
    required this.kcal,
    required this.pricePhp,
    required this.ingredients,
    this.image,
  });

  final String id;
  final String name;
  final List<MealSlot> slots;
  final int kcal;
  final int pricePhp;
  final String? image;
  final List<BankIngredientRef> ingredients;
}

/// [bank] placed in [slot] for [servings] portions. Quantities and line
/// prices are scaled and rounded to 2 decimals like the server does; the
/// meal's own kcal and price follow the same servings arithmetic.
PlannedMeal plannedMealFrom(
  BankMeal bank,
  MealSlot slot, {
  double servings = 1,
}) {
  double round2(double v) => (v * 100).roundToDouble() / 100;
  // The meal's price is its scaled ingredient cost, rounded once, so the day
  // prices and the grocery list tell the same money story.
  final cost = bank.ingredients.fold<double>(
    0,
    (sum, r) => sum + r.qty * servings * sampleIngredients[r.id]!.pricePhpPerUnit,
  );
  return PlannedMeal(
    slot: slot,
    id: bank.id,
    name: bank.name,
    kcal: (bank.kcal * servings).round(),
    pricePhp: (cost + 1e-9).round(),
    image: bank.image,
    servings: servings,
    ingredients: [
      for (final r in bank.ingredients)
        () {
          final info = sampleIngredients[r.id]!;
          final qty = r.qty * servings;
          return MealIngredient(
            id: r.id,
            name: info.name,
            kind: info.kind,
            unit: info.unit,
            qty: round2(qty),
            pricePhp: round2(qty * info.pricePhpPerUnit),
          );
        }(),
    ],
  );
}

const Map<String, BankIngredient> sampleIngredients = {
  'rice': BankIngredient('White rice', GroceryKind.grain, IngredientUnit.g, 0.05),
  'egg': BankIngredient('Egg', GroceryKind.egg, IngredientUnit.pc, 8.0),
  'garlic': BankIngredient('Garlic', GroceryKind.aromatics, IngredientUnit.g, 0.15),
  'onion': BankIngredient('Onion', GroceryKind.aromatics, IngredientUnit.g, 0.15),
  'ginger': BankIngredient('Ginger', GroceryKind.aromatics, IngredientUnit.g, 0.12),
  'spring-onion': BankIngredient('Spring onion', GroceryKind.aromatics, IngredientUnit.g, 0.2),
  'cooking-oil': BankIngredient('Cooking oil', GroceryKind.oil, IngredientUnit.ml, 0.11),
  'soy-sauce': BankIngredient('Soy sauce', GroceryKind.condiment, IngredientUnit.ml, 0.05),
  'vinegar': BankIngredient('Vinegar', GroceryKind.condiment, IngredientUnit.ml, 0.05),
  'fish-sauce': BankIngredient('Fish sauce', GroceryKind.condiment, IngredientUnit.ml, 0.07),
  'bagoong': BankIngredient('Bagoong (shrimp paste)', GroceryKind.condiment, IngredientUnit.g, 0.15),
  'sinigang-mix': BankIngredient('Sinigang (tamarind) mix', GroceryKind.pantry, IngredientUnit.g, 0.5),
  'beef-tapa': BankIngredient('Beef tapa cut', GroceryKind.meat, IngredientUnit.g, 0.45),
  'pork': BankIngredient('Pork', GroceryKind.meat, IngredientUnit.g, 0.33),
  'chicken': BankIngredient('Chicken (bone-in)', GroceryKind.poultry, IngredientUnit.g, 0.2),
  'daing-bangus': BankIngredient('Daing na bangus', GroceryKind.fish, IngredientUnit.g, 0.24),
  'green-papaya': BankIngredient('Green papaya', GroceryKind.produce, IngredientUnit.g, 0.04),
  'malunggay': BankIngredient('Malunggay leaves', GroceryKind.produce, IngredientUnit.g, 0.1),
  'kangkong': BankIngredient('Kangkong', GroceryKind.produce, IngredientUnit.g, 0.06),
  'tomato': BankIngredient('Tomato', GroceryKind.produce, IngredientUnit.g, 0.08),
  'radish': BankIngredient('Radish', GroceryKind.produce, IngredientUnit.g, 0.05),
  'string-beans': BankIngredient('String beans', GroceryKind.produce, IngredientUnit.g, 0.08),
  'eggplant': BankIngredient('Eggplant', GroceryKind.produce, IngredientUnit.g, 0.07),
  'squash': BankIngredient('Squash', GroceryKind.produce, IngredientUnit.g, 0.04),
  'okra': BankIngredient('Okra', GroceryKind.produce, IngredientUnit.g, 0.07),
  'ampalaya': BankIngredient('Ampalaya', GroceryKind.produce, IngredientUnit.g, 0.07),
  'mung-beans': BankIngredient('Mung beans', GroceryKind.legume, IngredientUnit.g, 0.12),
  'tofu': BankIngredient('Tofu', GroceryKind.produce, IngredientUnit.g, 0.1),
  'bay-leaf': BankIngredient('Bay leaves', GroceryKind.spice, IngredientUnit.g, 1.0),
  'peppercorn': BankIngredient('Peppercorns', GroceryKind.spice, IngredientUnit.g, 0.8),
  'saba': BankIngredient('Saba banana', GroceryKind.fruit, IngredientUnit.pc, 8.0),
  'peanuts': BankIngredient('Roasted peanuts', GroceryKind.pantry, IngredientUnit.g, 0.2),
  'grated-coconut': BankIngredient('Grated coconut', GroceryKind.produce, IngredientUnit.g, 0.1),
};

const List<BankMeal> sampleBankMeals = [
  BankMeal(
    id: 'tapsilog',
    name: 'Tapsilog: beef tapa, garlic rice and egg',
    slots: [MealSlot.breakfast],
    kcal: 560,
    pricePhp: 84,
    image: 'tapsilog',
    ingredients: [
      BankIngredientRef('beef-tapa', 150.0),
      BankIngredientRef('rice', 90.0),
      BankIngredientRef('egg', 1.0),
      BankIngredientRef('garlic', 10.0),
      BankIngredientRef('cooking-oil', 15.0),
      BankIngredientRef('soy-sauce', 10.0),
      BankIngredientRef('vinegar', 15.0),
    ],
  ),
  BankMeal(
    id: 'daingsilog',
    name: 'Daingsilog: fried milkfish, garlic rice and egg',
    slots: [MealSlot.breakfast],
    kcal: 540,
    pricePhp: 53,
    ingredients: [
      BankIngredientRef('daing-bangus', 150.0),
      BankIngredientRef('rice', 90.0),
      BankIngredientRef('egg', 1.0),
      BankIngredientRef('garlic', 10.0),
      BankIngredientRef('cooking-oil', 20.0),
      BankIngredientRef('vinegar', 15.0),
    ],
  ),
  BankMeal(
    id: 'lugaw',
    name: 'Lugaw with egg and toasted garlic',
    slots: [MealSlot.breakfast],
    kcal: 420,
    pricePhp: 17,
    ingredients: [
      BankIngredientRef('rice', 60.0),
      BankIngredientRef('egg', 1.0),
      BankIngredientRef('garlic', 10.0),
      BankIngredientRef('ginger', 10.0),
      BankIngredientRef('spring-onion', 5.0),
      BankIngredientRef('fish-sauce', 10.0),
      BankIngredientRef('cooking-oil', 10.0),
    ],
  ),
  BankMeal(
    id: 'tinola',
    name: 'Chicken tinola with moringa and rice',
    slots: [MealSlot.lunch, MealSlot.dinner],
    kcal: 620,
    pricePhp: 57,
    image: 'tinola',
    ingredients: [
      BankIngredientRef('chicken', 200.0),
      BankIngredientRef('green-papaya', 100.0),
      BankIngredientRef('malunggay', 15.0),
      BankIngredientRef('ginger', 10.0),
      BankIngredientRef('onion', 30.0),
      BankIngredientRef('garlic', 5.0),
      BankIngredientRef('fish-sauce', 10.0),
      BankIngredientRef('rice', 90.0),
    ],
  ),
  BankMeal(
    id: 'adobo',
    name: 'Chicken adobo with rice',
    slots: [MealSlot.lunch, MealSlot.dinner],
    kcal: 650,
    pricePhp: 53,
    ingredients: [
      BankIngredientRef('chicken', 200.0),
      BankIngredientRef('soy-sauce', 30.0),
      BankIngredientRef('vinegar', 30.0),
      BankIngredientRef('garlic', 15.0),
      BankIngredientRef('bay-leaf', 1.0),
      BankIngredientRef('peppercorn', 2.0),
      BankIngredientRef('cooking-oil', 10.0),
      BankIngredientRef('rice', 90.0),
    ],
  ),
  BankMeal(
    id: 'munggo',
    name: 'Ginisang munggo with tofu, water spinach and rice',
    slots: [MealSlot.lunch, MealSlot.dinner],
    kcal: 560,
    pricePhp: 32,
    image: 'munggo',
    ingredients: [
      BankIngredientRef('mung-beans', 60.0),
      BankIngredientRef('tofu', 80.0),
      BankIngredientRef('kangkong', 50.0),
      BankIngredientRef('tomato', 40.0),
      BankIngredientRef('onion', 25.0),
      BankIngredientRef('garlic', 5.0),
      BankIngredientRef('fish-sauce', 10.0),
      BankIngredientRef('cooking-oil', 10.0),
      BankIngredientRef('rice', 90.0),
    ],
  ),
  BankMeal(
    id: 'sinigang',
    name: 'Pork sinigang with rice',
    slots: [MealSlot.lunch, MealSlot.dinner],
    kcal: 610,
    pricePhp: 79,
    ingredients: [
      BankIngredientRef('pork', 150.0),
      BankIngredientRef('sinigang-mix', 10.0),
      BankIngredientRef('radish', 60.0),
      BankIngredientRef('kangkong', 40.0),
      BankIngredientRef('string-beans', 40.0),
      BankIngredientRef('eggplant', 50.0),
      BankIngredientRef('tomato', 40.0),
      BankIngredientRef('onion', 25.0),
      BankIngredientRef('fish-sauce', 10.0),
      BankIngredientRef('rice', 90.0),
    ],
  ),
  BankMeal(
    id: 'pinakbet',
    name: 'Pinakbet with rice',
    slots: [MealSlot.lunch, MealSlot.dinner],
    kcal: 480,
    pricePhp: 45,
    ingredients: [
      BankIngredientRef('squash', 80.0),
      BankIngredientRef('eggplant', 60.0),
      BankIngredientRef('okra', 40.0),
      BankIngredientRef('string-beans', 40.0),
      BankIngredientRef('ampalaya', 40.0),
      BankIngredientRef('tomato', 40.0),
      BankIngredientRef('onion', 25.0),
      BankIngredientRef('garlic', 5.0),
      BankIngredientRef('bagoong', 15.0),
      BankIngredientRef('pork', 40.0),
      BankIngredientRef('cooking-oil', 10.0),
      BankIngredientRef('rice', 90.0),
    ],
  ),
  BankMeal(
    id: 'saba-peanuts',
    name: 'Saba banana and peanuts',
    slots: [MealSlot.snack],
    kcal: 347,
    pricePhp: 22,
    image: 'saba-peanuts',
    ingredients: [
      BankIngredientRef('saba', 2.0),
      BankIngredientRef('peanuts', 30.0),
    ],
  ),
  BankMeal(
    id: 'boiled-saba',
    name: 'Boiled saba with grated coconut',
    slots: [MealSlot.snack],
    kcal: 300,
    pricePhp: 19,
    ingredients: [
      BankIngredientRef('saba', 2.0),
      BankIngredientRef('grated-coconut', 30.0),
    ],
  ),
];
