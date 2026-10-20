import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/data/sample_week.dart';
import 'package:mealpal_ph/screens/this_week_screen.dart';
import 'package:mealpal_ph/state/plan_draft.dart';

import '../helpers.dart';

void main() {
  late PlanDraft draft;
  var groceries = 0;
  var news = 0;

  Future<void> pump(WidgetTester tester) async {
    await phone(tester);
    draft = PlanDraft();
    groceries = 0;
    news = 0;
    await tester.pumpWidget(
      host(ThisWeekScreen(
        draft: draft,
        week: sampleWeek(),
        onGrocery: () => groceries++,
        onNew: () => news++,
      )),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the header pills, day strip and Monday meals',
      (tester) async {
    await pump(tester);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('2,087 kcal/day'), findsOneWidget);
    expect(find.text('≤ ₱2,500'), findsOneWidget);
    expect(find.text('Grocery list'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    for (final d in ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']) {
      expect(find.text(d), findsOneWidget, reason: d);
    }
    expect(find.text('Monday · 2,087 kcal · ₱250'), findsOneWidget);
    expect(find.text('BREAKFAST'), findsOneWidget);
    expect(find.text('Tapsilog — beef tapa, garlic rice & egg'), findsOneWidget);
    expect(find.text('560 kcal · ₱95'), findsOneWidget);
    expect(find.text('LUNCH'), findsOneWidget);
    expect(find.text('DINNER'), findsOneWidget);
    expect(find.text('SNACK'), findsOneWidget);
    expect(find.text('See grocery list'), findsOneWidget);
  });

  testWidgets('selecting a day swaps the summary and meals', (tester) async {
    await pump(tester);
    await tester.tap(find.text('TUE'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tuesday · '), findsOneWidget);
    expect(find.text('Monday · 2,087 kcal · ₱250'), findsNothing);
  });

  testWidgets('both grocery entry points and New fire their callbacks',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('Grocery list'));
    await tester.tap(find.text('See grocery list'));
    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();
    expect(groceries, 2);
    expect(news, 1);
  });
}
