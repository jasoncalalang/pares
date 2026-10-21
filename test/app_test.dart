import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/app.dart';

import 'helpers.dart';

void main() {
  testWidgets('walks the whole flow and carries the budget through',
      (tester) async {
    await phone(tester);
    await tester.pumpWidget(const MealPalApp());
    await tester.pumpAndSettle();

    expect(find.text('Find my calorie target'), findsOneWidget);
    await tester.tap(find.text('Find my calorie target'));
    await tester.pumpAndSettle();

    expect(find.text('Tell us about you'), findsOneWidget);
    await tester.tap(find.text('Compute my target'));
    await tester.pumpAndSettle();

    expect(find.text('Your daily target'), findsOneWidget);
    await tester.tap(find.text('Next: where you shop'));
    await tester.pumpAndSettle();

    expect(find.text('Where do you shop?'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Increase budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build my plan (2)'));
    await tester.pumpAndSettle();

    expect(find.text('This week'), findsOneWidget);
    expect(find.text('≤ ₱2,600'), findsOneWidget);
    await tester.tap(find.text('See grocery list'));
    await tester.pumpAndSettle();

    expect(find.text('Grocery list'), findsOneWidget);
    expect(find.text(' / ₱2,600'), findsOneWidget);
    await tester.tap(find.text('THIS WEEK'));
    await tester.pumpAndSettle();
    expect(find.text('This week'), findsOneWidget);
  });

  testWidgets('every screen has an on-screen way back', (tester) async {
    await phone(tester);
    await tester.pumpWidget(const MealPalApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Find my calorie target'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('STEP 1 OF 4'));
    await tester.pumpAndSettle();
    expect(find.text('Find my calorie target'), findsOneWidget);

    await tester.tap(find.text('Find my calorie target'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compute my target'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next: where you shop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build my plan (2)'));
    await tester.pumpAndSettle();
    expect(find.text('This week'), findsOneWidget);
    await tester.tap(find.text('STORES'));
    await tester.pumpAndSettle();
    expect(find.text('Where do you shop?'), findsOneWidget);
  });
}
