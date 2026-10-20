import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/screens/where_you_shop_screen.dart';
import 'package:mealpal_ph/state/plan_draft.dart';

import '../helpers.dart';

void main() {
  late PlanDraft draft;
  var nexts = 0;

  Future<void> pump(WidgetTester tester) async {
    await phone(tester);
    draft = PlanDraft();
    nexts = 0;
    await tester.pumpWidget(
      host(WhereYouShopScreen(draft: draft, onNext: () => nexts++)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows budget, the store grid and local stores', (tester) async {
    await pump(tester);
    expect(find.text('STEP 3 OF 4'), findsOneWidget);
    expect(find.text('Where do you shop?'), findsOneWidget);
    expect(find.text('WEEKLY BUDGET'), findsOneWidget);
    expect(find.text('₱2,500'), findsOneWidget);
    expect(find.text('/ week'), findsOneWidget);
    for (final s in [
      'SM Supermarket',
      'Puregold',
      'Savemore',
      'Robinsons',
      'S&R',
      'Landers',
      'WalterMart',
      'GrabMart',
    ]) {
      // "S&R" is also its own monogram, so it legitimately appears twice.
      expect(find.text(s), findsAtLeastNWidgets(1), reason: s);
    }
    expect(find.text('LOCAL TO THE PHILIPPINES'), findsOneWidget);
    expect(find.text('Pick the ones you actually use'), findsOneWidget);
    expect(find.text('Wet market'), findsOneWidget);
    expect(find.text('Corner store'), findsOneWidget);
    expect(find.text('Build my plan (2)'), findsOneWidget);
  });

  testWidgets('steppers move the budget by ₱100', (tester) async {
    await pump(tester);
    await tester.tap(find.bySemanticsLabel('Increase budget'));
    await tester.pumpAndSettle();
    expect(find.text('₱2,600'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Decrease budget'));
    await tester.tap(find.bySemanticsLabel('Decrease budget'));
    await tester.pumpAndSettle();
    expect(find.text('₱2,400'), findsOneWidget);
    expect(draft.weeklyBudgetPhp, 2400);
  });

  testWidgets('tapping tiles toggles stores and the CTA count follows',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('SM Supermarket'));
    await tester.pumpAndSettle();
    expect(draft.isStoreSelected('sm-supermarket'), isTrue);
    expect(find.text('Build my plan (3)'), findsOneWidget);

    await tester.tap(find.text('Wet market'));
    await tester.pumpAndSettle();
    expect(draft.isStoreSelected('palengke'), isFalse);
    expect(find.text('Build my plan (2)'), findsOneWidget);
  });

  testWidgets('the CTA advances', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Build my plan (2)'));
    await tester.pumpAndSettle();
    expect(nexts, 1);
  });
}
