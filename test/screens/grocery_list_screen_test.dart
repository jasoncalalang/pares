import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/data/sample_week.dart';
import 'package:mealpal_ph/screens/grocery_list_screen.dart';

import '../helpers.dart';

void main() {
  var backs = 0;
  var orders = 0;

  Future<void> pump(WidgetTester tester) async {
    await phone(tester);
    backs = 0;
    orders = 0;
    await tester.pumpWidget(
      host(GroceryListScreen(
        list: sampleGroceryList(budgetPhp: 2500),
        onBack: () => backs++,
        onOrder: () => orders++,
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
    expect(find.text('Order delivery via GrabMart'), findsOneWidget);
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

  testWidgets('back and order fire their callbacks', (tester) async {
    await pump(tester);
    await tester.tap(find.text('THIS WEEK'));
    await tester.ensureVisible(find.text('Order delivery via GrabMart'));
    await tester.tap(find.text('Order delivery via GrabMart'));
    await tester.pumpAndSettle();
    expect(backs, 1);
    expect(orders, 1);
  });
}
