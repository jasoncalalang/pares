import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:mealpal_ph/state/plan_draft.dart';

void main() {
  group('PlanDraft', () {
    test('starts with defaults that reproduce the mockup numbers', () {
      // 29 y / 171 cm / 74 kg / moderate → BMR 1,669, TDEE 2,587, −500 = 2,087
      final d = PlanDraft();
      expect(d.sex, BiologicalSex.male);
      expect(d.age, 29);
      expect(d.heightCm, 171);
      expect(d.weightKg, 74);
      expect(d.activity, ActivityLevel.moderate);
      expect(d.goal, Goal.lose);
      expect(d.weeklyBudgetPhp, 2500);
      expect(d.selectedStoreIds, {'puregold', 'wet-market'});
    });

    test('derives the calorie target and macros from its stats', () {
      final d = PlanDraft();
      expect(d.target.targetCalories, 2087);
      expect(d.target.bmr.round(), 1669);
      expect(d.target.tdee.round(), 2587);
      expect(d.macros.proteinG, 157);
    });

    test('ring fraction is target over maintenance, capped at 1', () {
      final d = PlanDraft();
      expect(d.targetFraction, closeTo(2087 / d.target.tdee, 1e-6));
      d.goal = Goal.gain;
      expect(d.targetFraction, 1);
    });

    test('notifies listeners and recomputes when a stat changes', () {
      final d = PlanDraft();
      var pings = 0;
      d.addListener(() => pings++);
      d.goal = Goal.maintain;
      expect(pings, 1);
      expect(d.target.targetCalories, 2587);
      d.weightKg = 80;
      expect(pings, 2);
      expect(d.target.targetCalories, isNot(2587));
    });

    test('steps the weekly budget by ₱100 and never below ₱500', () {
      final d = PlanDraft();
      d.budgetUp();
      expect(d.weeklyBudgetPhp, 2600);
      d.budgetDown();
      d.budgetDown();
      expect(d.weeklyBudgetPhp, 2400);
      for (var i = 0; i < 40; i++) {
        d.budgetDown();
      }
      expect(d.weeklyBudgetPhp, 500);
    });

    test('toggles store selection', () {
      final d = PlanDraft();
      d.toggleStore('sm-supermarket');
      expect(d.selectedStoreIds, contains('sm-supermarket'));
      d.toggleStore('puregold');
      expect(d.selectedStoreIds, isNot(contains('puregold')));
      expect(d.selectedStoreCount, 2);
    });
  });
}
