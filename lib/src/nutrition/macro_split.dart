/// Grams of protein / carbohydrate / fat for a daily calorie target.
class MacroSplit {
  const MacroSplit({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.proteinShare,
    required this.carbsShare,
    required this.fatShare,
  });

  final int proteinG;
  final int carbsG;
  final int fatG;

  /// Each macro's share of total calories (sums to 1).
  final double proteinShare;
  final double carbsShare;
  final double fatShare;
}

const _proteinShare = 0.30;
const _carbsShare = 0.45;
const _fatShare = 0.25;

const _kcalPerGramProtein = 4;
const _kcalPerGramCarbs = 4;
const _kcalPerGramFat = 9;

/// Split [targetCalories] into macro grams with a 30 / 45 / 25 ratio
/// (protein / carbs / fat by calories) — a sensible general-purpose default
/// for a rice-centred Filipino diet with a modest protein emphasis. Not
/// personalised; the meal bank, not this number, is what the plan is built on.
MacroSplit macroSplit(int targetCalories) {
  if (targetCalories <= 0) {
    throw ArgumentError.value(targetCalories, 'targetCalories', 'must be > 0');
  }
  return MacroSplit(
    proteinG: (targetCalories * _proteinShare / _kcalPerGramProtein).round(),
    carbsG: (targetCalories * _carbsShare / _kcalPerGramCarbs).round(),
    fatG: (targetCalories * _fatShare / _kcalPerGramFat).round(),
    proteinShare: _proteinShare,
    carbsShare: _carbsShare,
    fatShare: _fatShare,
  );
}
