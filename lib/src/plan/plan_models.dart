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
    required this.image,
  });

  final MealSlot slot;
  final String name;
  final int kcal;
  final int pricePhp;

  /// Image key, e.g. `tapsilog` → `assets/images/meals/tapsilog.jpg`.
  final String image;
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
    required this.name,
    required this.quantity,
    required this.pricePhp,
    this.kind = GroceryKind.pantry,
  });

  final String name;
  final String quantity;
  final int pricePhp;

  /// Drives the little ingredient icon and its tint in the list.
  final GroceryKind kind;
}

enum GroceryKind { meat, produce, fruit, aromatics, grain, egg, pantry, oil }

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
