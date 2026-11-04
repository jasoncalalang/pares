import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/data/sample_week.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:mealpal_ph/screens/grocery_list_screen.dart';

import '../helpers.dart';

void main() {
  var backs = 0;

  Future<void> pump(WidgetTester tester, {GroceryList? list}) async {
    await phone(tester);
    backs = 0;
    await tester.pumpWidget(
      host(GroceryListScreen(
        list: list ?? sampleGroceryList(budgetPhp: 2500),
        onBack: () => backs++,
      )),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the total, headroom and every store section',
      (tester) async {
    await pump(tester);
    expect(find.text('THIS WEEK'), findsOneWidget);
    expect(find.text('Grocery list'), findsOneWidget);
    expect(find.text('ESTIMATED TOTAL'), findsOneWidget);
    expect(find.text('₱1,153'), findsOneWidget);
    expect(find.text(' / ₱2,500'), findsOneWidget);
    expect(find.text('₱1,347 under budget'), findsOneWidget);

    expect(find.text('Wet market'), findsOneWidget);
    expect(find.text('6 items'), findsNWidgets(2));
    expect(find.text('₱545'), findsOneWidget);
    expect(find.text('Puregold'), findsOneWidget);
    expect(find.text('₱530'), findsOneWidget);
    expect(find.text('Corner store'), findsOneWidget);
    expect(find.text('(top-up)'), findsOneWidget);
    expect(find.text('3 items'), findsOneWidget);
    expect(find.text('₱78'), findsOneWidget);

    expect(find.text('Beef tapa cut'), findsOneWidget);
    expect(find.text('400 g'), findsOneWidget);
    expect(find.text('₱180'), findsOneWidget);
  });

  testWidgets('says what the amounts and prices are and keeps the subtitle short',
      (tester) async {
    await pump(tester);
    expect(find.text(groceryListNote), findsOneWidget);
    expect(
      groceryListNote,
      'Amounts are what your meals use. Prices are rough estimates for now.',
    );
    expect(find.textContaining('Sample list'), findsNothing);
    expect(find.text('Grouped by where to buy it.'), findsOneWidget);
    expect(find.textContaining('Everything for this week'), findsNothing);
  });

  testWidgets('the note shows with an empty list too', (tester) async {
    await pump(tester, list: const GroceryList(budgetPhp: 2500, sections: []));
    expect(find.text(groceryListNote), findsOneWidget);
    expect(find.text('Nothing to buy yet'), findsOneWidget);
  });

  testWidgets('the delivery handoff is an honest coming-soon note, not a button',
      (tester) async {
    await pump(tester);
    expect(find.text('Order delivery via GrabMart'), findsNothing);
    await tester.ensureVisible(find.textContaining('coming soon'));
    expect(
      find.text('Delivery handoff to GrabMart is coming soon. For now, shop '
          'from the list.'),
      findsOneWidget,
    );
  });

  testWidgets('checking a row strikes it through', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Beef tapa cut'));
    await tester.pumpAndSettle();
    final text = tester.widget<Text>(find.text('Beef tapa cut'));
    expect(text.style?.decoration, TextDecoration.lineThrough);

    await tester.tap(find.text('Beef tapa cut'));
    await tester.pumpAndSettle();
    final again = tester.widget<Text>(find.text('Beef tapa cut'));
    expect(again.style?.decoration, isNot(TextDecoration.lineThrough));
  });

  testWidgets('a section header collapses and re-expands its rows',
      (tester) async {
    await pump(tester);
    expect(find.text('Rice'), findsOneWidget);
    // The Puregold header sits below the fold on a 390×844 phone.
    await tester.ensureVisible(find.text('Puregold'));
    await tester.tap(find.text('Puregold'));
    await tester.pumpAndSettle();
    expect(find.text('Rice'), findsNothing);
    await tester.tap(find.text('Puregold'));
    await tester.pumpAndSettle();
    expect(find.text('Rice'), findsOneWidget);
  });

  testWidgets('back fires its callback', (tester) async {
    await pump(tester);
    await tester.tap(find.text('THIS WEEK'));
    await tester.pumpAndSettle();
    expect(backs, 1);
  });

  testWidgets('with nothing to buy it says why and what to do', (tester) async {
    await pump(tester, list: const GroceryList(budgetPhp: 2500, sections: []));
    expect(find.text('Nothing to buy yet'), findsOneWidget);
    expect(
      find.text("Build this week's plan first. The list fills itself in, "
          'grouped by store.'),
      findsOneWidget,
    );
    expect(find.text('ESTIMATED TOTAL'), findsNothing);
  });

  testWidgets('ticks follow the item, not its position, when the list changes',
      (tester) async {
    GroceryList listOf(List<(String, String)> items) => GroceryList(
          budgetPhp: 2500,
          sections: [
            GrocerySection(
              storeId: 'palengke',
              name: 'Wet market',
              monogram: 'W',
              local: true,
              items: [
                for (final (id, name) in items)
                  GroceryItem(id: id, name: name, quantity: '100 g', pricePhp: 10),
              ],
            ),
          ],
        );
    bool struck(WidgetTester t, String name) =>
        t.widget<Text>(find.text(name)).style?.decoration ==
        TextDecoration.lineThrough;

    await phone(tester);
    Future<void> show(GroceryList l) async {
      await tester.pumpWidget(
        host(GroceryListScreen(list: l, onBack: () {})),
      );
      await tester.pumpAndSettle();
    }

    await show(listOf([('kangkong', 'Kangkong'), ('tomato', 'Tomato')]));
    await tester.tap(find.text('Kangkong'));
    await tester.pumpAndSettle();
    expect(struck(tester, 'Kangkong'), isTrue);

    // A swap lands: Pork joins at the top, Tomato goes.
    await show(listOf([('pork', 'Pork'), ('kangkong', 'Kangkong')]));
    expect(struck(tester, 'Kangkong'), isTrue);
    expect(struck(tester, 'Pork'), isFalse);

    // Tomato comes back later: it was dropped, so it is not ticked.
    await show(listOf([('kangkong', 'Kangkong'), ('tomato', 'Tomato')]));
    expect(struck(tester, 'Tomato'), isFalse);
  });

  testWidgets('meals without ingredients get their own honest state',
      (tester) async {
    await pump(
      tester,
      list: const GroceryList(
        budgetPhp: 2500,
        sections: [],
        mealsLackIngredients: true,
      ),
    );
    expect(find.text('Nothing to buy yet'), findsNothing);
    expect(find.text('No ingredients for this plan'), findsOneWidget);
    expect(find.text(groceryListNoIngredients), findsOneWidget);
  });
}
