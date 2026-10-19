import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:test/test.dart';

void main() {
  group('calorie target (Mifflin-St Jeor)', () {
    test('BMR for a reference man: 80kg, 180cm, 30y = 1780', () {
      final t = calorieTarget(
        weightKg: 80,
        heightCm: 180,
        age: 30,
        sex: BiologicalSex.male,
        activity: ActivityLevel.sedentary,
        goal: Goal.maintain,
      );
      expect(t.bmr.round(), 1780);
    });

    test('BMR for a reference woman: 60kg, 165cm, 30y = 1320', () {
      final t = calorieTarget(
        weightKg: 60,
        heightCm: 165,
        age: 30,
        sex: BiologicalSex.female,
        activity: ActivityLevel.sedentary,
        goal: Goal.maintain,
      );
      expect(t.bmr.round(), 1320);
    });

    test('TDEE applies the activity multiplier (moderate = 1.55)', () {
      final t = calorieTarget(
        weightKg: 80,
        heightCm: 180,
        age: 30,
        sex: BiologicalSex.male,
        activity: ActivityLevel.moderate,
        goal: Goal.maintain,
      );
      expect(t.tdee.round(), (1780 * 1.55).round()); // 2759
    });

    test('maintain target equals TDEE (rounded)', () {
      final t = calorieTarget(
        weightKg: 80,
        heightCm: 180,
        age: 30,
        sex: BiologicalSex.male,
        activity: ActivityLevel.moderate,
        goal: Goal.maintain,
      );
      expect(t.targetCalories, t.tdee.round());
      expect(t.clampedToFloor, isFalse);
    });

    test('lose goal applies a ~500 kcal deficit', () {
      final t = calorieTarget(
        weightKg: 80,
        heightCm: 180,
        age: 30,
        sex: BiologicalSex.male,
        activity: ActivityLevel.moderate,
        goal: Goal.lose,
      );
      expect(t.targetCalories, t.tdee.round() - 500);
    });

    test('gain goal applies a surplus', () {
      final t = calorieTarget(
        weightKg: 80,
        heightCm: 180,
        age: 30,
        sex: BiologicalSex.male,
        activity: ActivityLevel.moderate,
        goal: Goal.gain,
      );
      expect(t.targetCalories, greaterThan(t.tdee.round()));
    });

    test('never recommends below a safe floor, and flags when it clamps', () {
      // Small, sedentary person on a deficit would compute below the floor.
      final t = calorieTarget(
        weightKg: 45,
        heightCm: 150,
        age: 60,
        sex: BiologicalSex.female,
        activity: ActivityLevel.sedentary,
        goal: Goal.lose,
      );
      expect(t.targetCalories, greaterThanOrEqualTo(1200));
      expect(t.clampedToFloor, isTrue);
    });

    test('target is a whole number of calories', () {
      final t = calorieTarget(
        weightKg: 72.4,
        heightCm: 171,
        age: 28,
        sex: BiologicalSex.female,
        activity: ActivityLevel.light,
        goal: Goal.maintain,
      );
      expect(t.targetCalories, isA<int>());
    });

    test('rejects nonsensical input', () {
      expect(
        () => calorieTarget(
          weightKg: 0,
          heightCm: 170,
          age: 30,
          sex: BiologicalSex.male,
          activity: ActivityLevel.moderate,
          goal: Goal.maintain,
        ),
        throwsArgumentError,
      );
    });
  });
}
