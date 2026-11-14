import '../mealpal_ph.dart';

/// The offline copy of the server's meal bank
/// (`server/src/main/resources/meal-bank.json`), ingredients included.
/// test/data/bank_parity_test.dart fails if the two differ, so edit both
/// together. Each meal's kcal is computed on the server from USDA FoodData
/// Central energy per ingredient (the USDA provenance stays in the JSON; this
/// copy keeps only what the app reads). Quantities are recipe estimates and
/// unit prices are placeholders until the price checker's price book exists.

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
  'chicken': BankIngredient('Chicken (bone in)', GroceryKind.poultry, IngredientUnit.g, 0.2),
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
  'longganisa': BankIngredient('Longganisa', GroceryKind.meat, IngredientUnit.g, 0.32),
  'tocino': BankIngredient('Tocino', GroceryKind.meat, IngredientUnit.g, 0.32),
  'glutinous-rice': BankIngredient('Glutinous rice (malagkit)', GroceryKind.grain, IngredientUnit.g, 0.07),
  'tablea': BankIngredient('Tablea (cacao tablet)', GroceryKind.pantry, IngredientUnit.g, 0.4),
  'sugar': BankIngredient('White sugar', GroceryKind.pantry, IngredientUnit.g, 0.09),
  'brown-sugar': BankIngredient('Brown sugar', GroceryKind.pantry, IngredientUnit.g, 0.07),
  'evaporated-milk': BankIngredient('Evaporated milk', GroceryKind.pantry, IngredientUnit.ml, 0.14),
  'pandesal': BankIngredient('Pandesal', GroceryKind.pantry, IngredientUnit.pc, 4.0),
  'potato': BankIngredient('Potato', GroceryKind.produce, IngredientUnit.g, 0.12),
  'carrot': BankIngredient('Carrot', GroceryKind.produce, IngredientUnit.g, 0.08),
  'bell-pepper': BankIngredient('Bell pepper', GroceryKind.produce, IngredientUnit.g, 0.2),
  'coconut-milk': BankIngredient('Coconut milk', GroceryKind.pantry, IngredientUnit.ml, 0.15),
  'taro-leaves': BankIngredient('Taro leaves (dahon ng gabi)', GroceryKind.produce, IngredientUnit.g, 0.05),
  'tilapia': BankIngredient('Tilapia fillet', GroceryKind.fish, IngredientUnit.g, 0.3),
  'beef-sirloin': BankIngredient('Beef sirloin', GroceryKind.meat, IngredientUnit.g, 0.55),
  'beef-shank': BankIngredient('Beef shank', GroceryKind.meat, IngredientUnit.g, 0.42),
  'cabbage': BankIngredient('Cabbage', GroceryKind.produce, IngredientUnit.g, 0.06),
  'corn': BankIngredient('Corn on the cob', GroceryKind.produce, IngredientUnit.pc, 15.0),
  'chicken-breast': BankIngredient('Chicken breast (boneless)', GroceryKind.poultry, IngredientUnit.g, 0.26),
  'rice-noodles': BankIngredient('Rice noodles (bihon)', GroceryKind.pantry, IngredientUnit.g, 0.12),
  'sardines': BankIngredient('Sardines in tomato sauce', GroceryKind.pantry, IngredientUnit.g, 0.2),
  'misua': BankIngredient('Misua noodles', GroceryKind.pantry, IngredientUnit.g, 0.15),
  'sweet-potato': BankIngredient('Sweet potato (kamote)', GroceryKind.produce, IngredientUnit.g, 0.05),
  'lumpia-wrapper': BankIngredient('Lumpia wrapper', GroceryKind.produce, IngredientUnit.pc, 3.0),
  'silken-tofu': BankIngredient('Silken tofu', GroceryKind.produce, IngredientUnit.g, 0.08),
  'sago': BankIngredient('Sago pearls', GroceryKind.pantry, IngredientUnit.g, 0.15),
  'chili': BankIngredient('Chili (siling labuyo)', GroceryKind.produce, IngredientUnit.g, 0.4),
  'calamansi': BankIngredient('Calamansi', GroceryKind.fruit, IngredientUnit.g, 0.12),
  'tomato-sauce': BankIngredient('Tomato sauce', GroceryKind.pantry, IngredientUnit.g, 0.13),
};

const List<BankMeal> sampleBankMeals = [
  BankMeal(
    id: 'tapsilog',
    name: 'Tapsilog: beef tapa, garlic rice and egg',
    slots: [MealSlot.breakfast],
    kcal: 797,
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
    kcal: 802,
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
    kcal: 401,
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
    kcal: 674,
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
    kcal: 724,
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
    kcal: 774,
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
    kcal: 779,
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
    kcal: 634,
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
    kcal: 320,
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
    kcal: 250,
    pricePhp: 19,
    ingredients: [
      BankIngredientRef('saba', 2.0),
      BankIngredientRef('grated-coconut', 30.0),
    ],
  ),
  BankMeal(
    id: 'longsilog',
    name: 'Longsilog: longganisa, garlic rice and egg',
    slots: [MealSlot.breakfast],
    kcal: 731,
    pricePhp: 41,
    ingredients: [
      BankIngredientRef('longganisa', 80.0),
      BankIngredientRef('rice', 90.0),
      BankIngredientRef('egg', 1.0),
      BankIngredientRef('garlic', 10.0),
      BankIngredientRef('cooking-oil', 10.0),
      BankIngredientRef('vinegar', 15.0),
    ],
  ),
  BankMeal(
    id: 'tocilog',
    name: 'Tocilog: tocino, garlic rice and egg',
    slots: [MealSlot.breakfast],
    kcal: 745,
    pricePhp: 48,
    ingredients: [
      BankIngredientRef('tocino', 100.0),
      BankIngredientRef('rice', 90.0),
      BankIngredientRef('egg', 1.0),
      BankIngredientRef('garlic', 10.0),
      BankIngredientRef('cooking-oil', 10.0),
      BankIngredientRef('vinegar', 15.0),
    ],
  ),
  BankMeal(
    id: 'champorado',
    name: 'Champorado: chocolate rice porridge with evaporated milk',
    slots: [MealSlot.breakfast],
    kcal: 615,
    pricePhp: 27,
    ingredients: [
      BankIngredientRef('glutinous-rice', 70.0),
      BankIngredientRef('tablea', 30.0),
      BankIngredientRef('sugar', 20.0),
      BankIngredientRef('evaporated-milk', 60.0),
    ],
  ),
  BankMeal(
    id: 'arroz-caldo',
    name: 'Arroz caldo: chicken rice porridge with ginger, garlic and egg',
    slots: [MealSlot.breakfast],
    kcal: 602,
    pricePhp: 49,
    ingredients: [
      BankIngredientRef('rice', 60.0),
      BankIngredientRef('chicken', 150.0),
      BankIngredientRef('ginger', 10.0),
      BankIngredientRef('garlic', 8.0),
      BankIngredientRef('onion', 20.0),
      BankIngredientRef('egg', 1.0),
      BankIngredientRef('fish-sauce', 10.0),
      BankIngredientRef('spring-onion', 5.0),
      BankIngredientRef('cooking-oil', 10.0),
    ],
  ),
  BankMeal(
    id: 'pandesal-egg',
    name: 'Pandesal with scrambled egg',
    slots: [MealSlot.breakfast],
    kcal: 544,
    pricePhp: 38,
    ingredients: [
      BankIngredientRef('pandesal', 4.0),
      BankIngredientRef('egg', 2.0),
      BankIngredientRef('cooking-oil', 5.0),
      BankIngredientRef('onion', 20.0),
      BankIngredientRef('tomato', 30.0),
    ],
  ),
  BankMeal(
    id: 'menudo',
    name: 'Pork menudo with potato, carrot and rice',
    slots: [MealSlot.lunch, MealSlot.dinner],
    kcal: 845,
    pricePhp: 83,
    ingredients: [
      BankIngredientRef('pork', 120.0),
      BankIngredientRef('potato', 100.0),
      BankIngredientRef('carrot', 50.0),
      BankIngredientRef('bell-pepper', 30.0),
      BankIngredientRef('tomato', 50.0),
      BankIngredientRef('tomato-sauce', 50.0),
      BankIngredientRef('onion', 25.0),
      BankIngredientRef('garlic', 5.0),
      BankIngredientRef('soy-sauce', 15.0),
      BankIngredientRef('cooking-oil', 10.0),
      BankIngredientRef('rice', 90.0),
    ],
  ),
  BankMeal(
    id: 'afritada',
    name: 'Chicken afritada with potato, bell pepper and rice',
    slots: [MealSlot.lunch, MealSlot.dinner],
    kcal: 825,
    pricePhp: 88,
    ingredients: [
      BankIngredientRef('chicken', 200.0),
      BankIngredientRef('potato', 100.0),
      BankIngredientRef('carrot', 50.0),
      BankIngredientRef('bell-pepper', 50.0),
      BankIngredientRef('tomato', 40.0),
      BankIngredientRef('tomato-sauce', 60.0),
      BankIngredientRef('onion', 25.0),
      BankIngredientRef('garlic', 5.0),
      BankIngredientRef('fish-sauce', 10.0),
      BankIngredientRef('cooking-oil', 10.0),
      BankIngredientRef('rice', 90.0),
    ],
  ),
  BankMeal(
    id: 'ginataang-kalabasa',
    name: 'Ginataang kalabasa: squash and string beans in coconut milk, with rice',
    slots: [MealSlot.lunch, MealSlot.dinner],
    kcal: 646,
    pricePhp: 36,
    ingredients: [
      BankIngredientRef('squash', 150.0),
      BankIngredientRef('string-beans', 60.0),
      BankIngredientRef('coconut-milk', 100.0),
      BankIngredientRef('onion', 25.0),
      BankIngredientRef('garlic', 5.0),
      BankIngredientRef('fish-sauce', 10.0),
      BankIngredientRef('rice', 90.0),
    ],
  ),
  BankMeal(
    id: 'tortang-talong',
    name: 'Tortang talong: eggplant omelette with rice',
    slots: [MealSlot.lunch, MealSlot.dinner],
    kcal: 700,
    pricePhp: 40,
    ingredients: [
      BankIngredientRef('eggplant', 200.0),
      BankIngredientRef('egg', 2.0),
      BankIngredientRef('onion', 20.0),
      BankIngredientRef('garlic', 5.0),
      BankIngredientRef('cooking-oil', 20.0),
      BankIngredientRef('rice', 90.0),
    ],
  ),
  BankMeal(
    id: 'pritong-tilapia',
    name: 'Pritong tilapia: fried tilapia with tomato and rice',
    slots: [MealSlot.lunch, MealSlot.dinner],
    kcal: 629,
    pricePhp: 63,
    ingredients: [
      BankIngredientRef('tilapia', 150.0),
      BankIngredientRef('cooking-oil', 15.0),
      BankIngredientRef('tomato', 80.0),
      BankIngredientRef('onion', 25.0),
      BankIngredientRef('garlic', 5.0),
      BankIngredientRef('vinegar', 15.0),
      BankIngredientRef('rice', 90.0),
    ],
  ),
  BankMeal(
    id: 'bistek',
    name: 'Bistek tagalog: beef with onion rings and rice',
    slots: [MealSlot.lunch, MealSlot.dinner],
    kcal: 783,
    pricePhp: 110,
    ingredients: [
      BankIngredientRef('beef-sirloin', 150.0),
      BankIngredientRef('onion', 100.0),
      BankIngredientRef('soy-sauce', 30.0),
      BankIngredientRef('calamansi', 40.0),
      BankIngredientRef('garlic', 5.0),
      BankIngredientRef('cooking-oil', 10.0),
      BankIngredientRef('rice', 90.0),
    ],
  ),
  BankMeal(
    id: 'chopsuey',
    name: 'Chopsuey: mixed vegetables with chicken and rice',
    slots: [MealSlot.lunch, MealSlot.dinner],
    kcal: 616,
    pricePhp: 56,
    ingredients: [
      BankIngredientRef('chicken-breast', 100.0),
      BankIngredientRef('cabbage', 100.0),
      BankIngredientRef('carrot', 60.0),
      BankIngredientRef('bell-pepper', 40.0),
      BankIngredientRef('onion', 25.0),
      BankIngredientRef('garlic', 5.0),
      BankIngredientRef('soy-sauce', 15.0),
      BankIngredientRef('cooking-oil', 10.0),
      BankIngredientRef('rice', 90.0),
    ],
  ),
  BankMeal(
    id: 'pancit-bihon',
    name: 'Pancit bihon: rice noodles with chicken and vegetables',
    slots: [MealSlot.lunch, MealSlot.dinner],
    kcal: 671,
    pricePhp: 53,
    ingredients: [
      BankIngredientRef('rice-noodles', 100.0),
      BankIngredientRef('chicken-breast', 100.0),
      BankIngredientRef('carrot', 40.0),
      BankIngredientRef('cabbage', 80.0),
      BankIngredientRef('onion', 25.0),
      BankIngredientRef('garlic', 5.0),
      BankIngredientRef('soy-sauce', 20.0),
      BankIngredientRef('cooking-oil', 15.0),
    ],
  ),
  BankMeal(
    id: 'nilagang-baka',
    name: 'Nilagang baka: beef shank soup with potato, cabbage, corn and rice',
    slots: [MealSlot.lunch, MealSlot.dinner],
    kcal: 729,
    pricePhp: 107,
    ingredients: [
      BankIngredientRef('beef-shank', 150.0),
      BankIngredientRef('potato', 100.0),
      BankIngredientRef('cabbage', 100.0),
      BankIngredientRef('corn', 1.0),
      BankIngredientRef('onion', 25.0),
      BankIngredientRef('peppercorn', 2.0),
      BankIngredientRef('fish-sauce', 10.0),
      BankIngredientRef('rice', 90.0),
    ],
  ),
  BankMeal(
    id: 'laing',
    name: 'Laing: taro leaves in coconut milk, with rice',
    slots: [MealSlot.lunch, MealSlot.dinner],
    kcal: 823,
    pricePhp: 57,
    ingredients: [
      BankIngredientRef('taro-leaves', 150.0),
      BankIngredientRef('coconut-milk', 150.0),
      BankIngredientRef('pork', 40.0),
      BankIngredientRef('bagoong', 10.0),
      BankIngredientRef('ginger', 10.0),
      BankIngredientRef('garlic', 5.0),
      BankIngredientRef('onion', 25.0),
      BankIngredientRef('chili', 5.0),
      BankIngredientRef('rice', 90.0),
    ],
  ),
  BankMeal(
    id: 'sardinas-misua',
    name: 'Sardinas with misua: sardines in tomato sauce and thin noodles, with rice',
    slots: [MealSlot.lunch, MealSlot.dinner],
    kcal: 725,
    pricePhp: 40,
    ingredients: [
      BankIngredientRef('sardines', 100.0),
      BankIngredientRef('misua', 40.0),
      BankIngredientRef('tomato', 60.0),
      BankIngredientRef('onion', 25.0),
      BankIngredientRef('garlic', 5.0),
      BankIngredientRef('cooking-oil', 5.0),
      BankIngredientRef('rice', 90.0),
    ],
  ),
  BankMeal(
    id: 'turon',
    name: 'Turon: fried saba banana in a spring roll wrapper with brown sugar',
    slots: [MealSlot.snack],
    kcal: 385,
    pricePhp: 16,
    ingredients: [
      BankIngredientRef('saba', 1.0),
      BankIngredientRef('lumpia-wrapper', 2.0),
      BankIngredientRef('brown-sugar', 12.0),
      BankIngredientRef('cooking-oil', 10.0),
    ],
  ),
  BankMeal(
    id: 'kamote-cue',
    name: 'Kamote cue: sweet potato fried in caramelised sugar',
    slots: [MealSlot.snack],
    kcal: 305,
    pricePhp: 10,
    ingredients: [
      BankIngredientRef('sweet-potato', 150.0),
      BankIngredientRef('brown-sugar', 25.0),
      BankIngredientRef('cooking-oil', 10.0),
    ],
  ),
  BankMeal(
    id: 'nilagang-mais',
    name: 'Nilagang mais: boiled corn on the cob',
    slots: [MealSlot.snack],
    kcal: 175,
    pricePhp: 30,
    ingredients: [
      BankIngredientRef('corn', 2.0),
    ],
  ),
  BankMeal(
    id: 'taho',
    name: 'Taho: silken tofu with brown sugar syrup and sago pearls',
    slots: [MealSlot.snack],
    kcal: 249,
    pricePhp: 17,
    ingredients: [
      BankIngredientRef('silken-tofu', 150.0),
      BankIngredientRef('brown-sugar', 25.0),
      BankIngredientRef('sago', 20.0),
    ],
  ),
];
