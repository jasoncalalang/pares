/// Biological sex, as used by the BMR equation (clinical input, not identity).
/// The UI can let people pick or skip this; the domain needs one of the two
/// to run Mifflin–St Jeor.
enum BiologicalSex { male, female }

/// How active someone is day to day. Multipliers are the standard
/// Mifflin–St Jeor activity factors.
enum ActivityLevel {
  sedentary(1.2),
  light(1.375),
  moderate(1.55),
  active(1.725),
  veryActive(1.9);

  const ActivityLevel(this.factor);
  final double factor;
}

/// What the person is trying to do. The deltas are applied to TDEE.
enum Goal {
  lose(-500),
  maintain(0),
  gain(400);

  const Goal(this.kcalDelta);
  final int kcalDelta;
}

/// Lowest daily intake we will ever recommend, by sex. Below this a deficit is
/// unsafe to suggest without supervision, so we clamp and flag it.
const Map<BiologicalSex, int> _safeFloor = {
  BiologicalSex.female: 1200,
  BiologicalSex.male: 1500,
};

/// The result of a calorie-target calculation.
class CalorieTargetResult {
  const CalorieTargetResult({
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
    required this.clampedToFloor,
  });

  /// Basal metabolic rate (kcal/day).
  final double bmr;

  /// Total daily energy expenditure = BMR × activity factor (kcal/day).
  final double tdee;

  /// Recommended daily intake for the goal (kcal/day), never below the
  /// safe floor.
  final int targetCalories;

  /// True when the goal's deficit would have gone below the safe floor and
  /// the target was raised to it. Surface this to the user.
  final bool clampedToFloor;
}

/// Compute a daily calorie target with the Mifflin–St Jeor equation.
///
/// Metric only (kg, cm) — the Philippine norm. Throws [ArgumentError] on
/// non-physiological input rather than returning a nonsense number.
CalorieTargetResult calorieTarget({
  required double weightKg,
  required double heightCm,
  required int age,
  required BiologicalSex sex,
  required ActivityLevel activity,
  required Goal goal,
}) {
  if (weightKg <= 0 || heightCm <= 0 || age <= 0) {
    throw ArgumentError('weight, height and age must all be positive');
  }

  final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  final bmr = base + (sex == BiologicalSex.male ? 5 : -161);
  final tdee = bmr * activity.factor;

  final raw = tdee.round() + goal.kcalDelta;
  final floor = _safeFloor[sex]!;
  final clamped = raw < floor;

  return CalorieTargetResult(
    bmr: bmr,
    tdee: tdee,
    targetCalories: clamped ? floor : raw,
    clampedToFloor: clamped,
  );
}
