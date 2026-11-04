/// The four meal slots a day is planned around.
enum MealSlot {
  breakfast('Breakfast'),
  lunch('Lunch'),
  dinner('Dinner'),
  snack('Snack');

  const MealSlot(this.label);
  final String label;
}

enum Weekday {
  mon('Monday', 'Mon'),
  tue('Tuesday', 'Tue'),
  wed('Wednesday', 'Wed'),
  thu('Thursday', 'Thu'),
  fri('Friday', 'Fri'),
  sat('Saturday', 'Sat'),
  sun('Sunday', 'Sun');

  const Weekday(this.label, this.short);
  final String label;
  final String short;
}

/// One meal placed in a day's plan. Nutrition and price come from the meal
/// bank, never from the model that picked it.
class PlannedMeal {
  const PlannedMeal({
    required this.slot,
    required this.name,
    required this.kcal,
    required this.pricePhp,
    this.image,
    this.id,
    this.servings = 1,
    this.ingredients = const [],
  });

  final MealSlot slot;
  final String name;
  final int kcal;
  final int pricePhp;

  /// Image key, e.g. `tapsilog` → `assets/images/meals/tapsilog.jpg`.
  /// Null when the bank has no photo yet; the card falls back to a tinted
  /// initial.
  final String? image;

  /// The meal bank's id, when the plan came from the server.
  final String? id;

  /// How many portions [kcal] and [pricePhp] already cover (0.5 to 2 from
  /// the server; 1 for the sample bank).
  final double servings;

  /// What the meal is made of, already scaled by [servings]. Empty when the
  /// source (an older server) did not send any.
  final List<MealIngredient> ingredients;
}

/// The unit a bank ingredient is measured and priced in.
enum IngredientUnit { g, ml, pc }

/// One ingredient of a planned meal. [qty] and [pricePhp] already cover the
/// meal's servings.
class MealIngredient {
  const MealIngredient({
    required this.id,
    required this.name,
    required this.kind,
    required this.unit,
    required this.qty,
    required this.pricePhp,
  });

  final String id;
  final String name;
  final GroceryKind kind;
  final IngredientUnit unit;
  final double qty;
  final double pricePhp;
}

class DayPlan {
  const DayPlan({required this.weekday, required this.meals});

  final Weekday weekday;
  final List<PlannedMeal> meals;

  int get kcal => meals.fold(0, (sum, m) => sum + m.kcal);
  int get pricePhp => meals.fold(0, (sum, m) => sum + m.pricePhp);

  PlannedMeal? meal(MealSlot slot) {
    for (final m in meals) {
      if (m.slot == slot) return m;
    }
    return null;
  }
}

class GroceryItem {
  const GroceryItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.pricePhp,
    this.kind = GroceryKind.pantry,
  });

  /// The ingredient id, so a tick can follow the item when the list changes.
  /// Falls back to the name when null.
  final String? id;
  final String name;
  final String quantity;
  final int pricePhp;

  /// What identifies this item within its section.
  String get key => id ?? name;

  /// Drives the little ingredient icon and its tint in the list.
  final GroceryKind kind;
}

enum GroceryKind {
  meat,
  poultry,
  fish,
  produce,
  fruit,
  aromatics,
  grain,
  egg,
  legume,
  oil,
  condiment,
  spice,
  pantry,
}

/// Items to buy at one store.
class GrocerySection {
  const GrocerySection({
    required this.storeId,
    required this.name,
    required this.monogram,
    required this.local,
    required this.items,
    this.note,
  });

  final String storeId;
  final String name;
  final String monogram;

  /// True for the wet market / corner store (green accent, in-person run).
  final bool local;

  /// e.g. "(top-up)"
  final String? note;

  final List<GroceryItem> items;

  int get subtotalPhp => items.fold(0, (sum, i) => sum + i.pricePhp);
}

class GroceryList {
  const GroceryList({required this.budgetPhp, required this.sections});

  final int budgetPhp;
  final List<GrocerySection> sections;

  int get totalPhp => sections.fold(0, (sum, s) => sum + s.subtotalPhp);
  int get remainingPhp => budgetPhp - totalPhp;
  bool get overBudget => totalPhp > budgetPhp;

  /// Spent share of the budget for the progress bar, clamped to [0, 1].
  double get budgetFraction =>
      budgetPhp <= 0 ? 1 : (totalPhp / budgetPhp).clamp(0, 1).toDouble();
}
