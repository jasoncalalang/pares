import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:test/test.dart';

void main() {
  const tapsilog = PlannedMeal(
    slot: MealSlot.breakfast,
    name: 'Tapsilog — beef tapa, garlic rice & egg',
    kcal: 560,
    pricePhp: 95,
    image: 'tapsilog',
  );
  const tinola = PlannedMeal(
    slot: MealSlot.lunch,
    name: 'Chicken tinola with moringa & rice',
    kcal: 620,
    pricePhp: 75,
    image: 'tinola',
  );

  group('DayPlan', () {
    test('totals calories and pesos across its meals', () {
      const day = DayPlan(weekday: Weekday.mon, meals: [tapsilog, tinola]);
      expect(day.kcal, 1180);
      expect(day.pricePhp, 170);
    });

    test('finds the meal for a slot', () {
      const day = DayPlan(weekday: Weekday.mon, meals: [tapsilog, tinola]);
      expect(day.meal(MealSlot.lunch), tinola);
      expect(day.meal(MealSlot.dinner), isNull);
    });
  });

  group('MealSlot', () {
    test('labels read as the UI copy', () {
      expect(MealSlot.breakfast.label, 'Breakfast');
      expect(MealSlot.snack.label, 'Snack');
    });
  });

  group('Weekday', () {
    test('has three-letter short names in English', () {
      expect(Weekday.mon.short, 'Mon');
      expect(Weekday.sun.short, 'Sun');
      expect(Weekday.wed.label, 'Wednesday');
    });
  });

  group('GrocerySection', () {
    const section = GrocerySection(
      storeId: 'wet-market',
      name: 'Wet market',
      monogram: 'W',
      local: true,
      items: [
        GroceryItem(name: 'Beef tapa cut', quantity: '400 g', pricePhp: 180),
        GroceryItem(name: 'Chicken', quantity: 'Tinola cut · 500 g', pricePhp: 140),
      ],
    );

    test('subtotals its items', () {
      expect(section.subtotalPhp, 320);
      expect(section.items.length, 2);
    });
  });

  group('GroceryList', () {
    const list = GroceryList(
      budgetPhp: 2500,
      sections: [
        GrocerySection(
          storeId: 'wet-market',
          name: 'Wet market',
          monogram: 'W',
          local: true,
          items: [GroceryItem(name: 'Beef', quantity: '400 g', pricePhp: 500)],
        ),
        GrocerySection(
          storeId: 'puregold',
          name: 'Puregold',
          monogram: 'P',
          local: false,
          items: [GroceryItem(name: 'Rice', quantity: '5 kg', pricePhp: 653)],
        ),
      ],
    );

    test('totals every section and reports headroom under budget', () {
      expect(list.totalPhp, 1153);
      expect(list.remainingPhp, 1347);
      expect(list.budgetFraction, closeTo(1153 / 2500, 1e-9));
      expect(list.overBudget, isFalse);
    });

    test('clamps the budget fraction at 1 and flags over-budget', () {
      const over = GroceryList(
        budgetPhp: 100,
        sections: [
          GrocerySection(
            storeId: 'x',
            name: 'X',
            monogram: 'X',
            local: false,
            items: [GroceryItem(name: 'a', quantity: '', pricePhp: 150)],
          ),
        ],
      );
      expect(over.budgetFraction, 1);
      expect(over.remainingPhp, -50);
      expect(over.overBudget, isTrue);
    });
  });
}
