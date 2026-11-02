import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:test/test.dart';

void main() {
  group('PlanBrief', () {
    test('sorts and freezes store ids', () {
      final brief = PlanBrief(
        targetKcal: 1800,
        budgetPhp: 2500,
        goal: Goal.lose,
        storeIds: ['puregold', 'palengke'],
      );
      expect(brief.storeIds, ['palengke', 'puregold']);
      expect(() => brief.storeIds.add('sm'), throwsUnsupportedError);
    });

    test('has value equality regardless of store order', () {
      PlanBrief make(List<String> stores) => PlanBrief(
        targetKcal: 1800,
        budgetPhp: 2500,
        goal: Goal.gain,
        storeIds: stores,
      );
      expect(make(['a', 'b']), make(['b', 'a']));
      expect(make(['a', 'b']).hashCode, make(['b', 'a']).hashCode);
      expect(make(['a']), isNot(make(['b'])));
      expect(
        make(['a']),
        isNot(
          PlanBrief(
            targetKcal: 1801,
            budgetPhp: 2500,
            goal: Goal.gain,
            storeIds: ['a'],
          ),
        ),
      );
    });

    test('toJson matches the server request', () {
      final brief = PlanBrief(
        targetKcal: 1800,
        budgetPhp: 2500,
        goal: Goal.maintain,
        storeIds: ['puregold', 'palengke'],
      );
      expect(brief.toJson(), {
        'targetKcal': 1800,
        'budgetPhp': 2500,
        'goal': 'maintain',
        'storeIds': ['palengke', 'puregold'],
      });
    });
  });

  group('PlannedMeal', () {
    test('carries an optional bank id', () {
      const withId = PlannedMeal(
        slot: MealSlot.lunch,
        name: 'Adobo',
        kcal: 1,
        pricePhp: 1,
        id: 'adobo',
      );
      const without = PlannedMeal(
        slot: MealSlot.lunch,
        name: 'Adobo',
        kcal: 1,
        pricePhp: 1,
      );
      expect(withId.id, 'adobo');
      expect(without.id, isNull);
    });
  });

  group('PlannerException', () {
    test('describes itself with kind and message', () {
      const e = PlannerException(
        PlannerErrorKind.busy,
        message: 'Still building.',
      );
      expect(e.kind, PlannerErrorKind.busy);
      expect(e.message, 'Still building.');
      expect(e.problems, isEmpty);
      expect(e.toString(), contains('busy'));
    });
  });
}
