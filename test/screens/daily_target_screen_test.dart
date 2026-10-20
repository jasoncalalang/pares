import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:mealpal_ph/screens/daily_target_screen.dart';
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
      host(DailyTargetScreen(draft: draft, onNext: () => nexts++)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the hero target, breakdown and macros', (tester) async {
    await pump(tester);
    expect(find.text('STEP 2 OF 4'), findsOneWidget);
    expect(find.text('Your daily target'), findsOneWidget);
    expect(find.text('DAILY ENERGY'), findsOneWidget);
    // Hero number and the number inside the ring (after its count-up).
    expect(find.text('2,087'), findsNWidgets(2));
    expect(find.text('KCAL/DAY'), findsOneWidget);
    expect(find.textContaining('to lose ~0.5 kg per week'), findsOneWidget);

    expect(find.text('BMR (at rest)'), findsOneWidget);
    expect(find.text('1,669 kcal'), findsOneWidget);
    expect(find.text('Activity ×1.55 (moderate)'), findsOneWidget);
    expect(find.text('2,587 kcal'), findsOneWidget);
    expect(find.text('Deficit for losing'), findsOneWidget);
    expect(find.text('−500 kcal'), findsOneWidget);

    expect(find.text('157g'), findsOneWidget);
    expect(find.text('235g'), findsOneWidget);
    expect(find.text('58g'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('Fat'), findsOneWidget);
    expect(find.text('Next: where you shop'), findsOneWidget);
  });

  testWidgets('switching goal recomputes the target live', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Maintain'));
    await tester.pumpAndSettle();
    expect(draft.goal, Goal.maintain);
    expect(find.text('2,587'), findsNWidgets(2));
    expect(find.text('Maintenance'), findsOneWidget);
    expect(find.text('0 kcal'), findsOneWidget);
    expect(find.textContaining('to hold your weight'), findsOneWidget);

    await tester.tap(find.text('Gain'));
    await tester.pumpAndSettle();
    expect(find.text('2,987'), findsNWidgets(2));
    expect(find.text('Surplus for gaining'), findsOneWidget);
    expect(find.text('+400 kcal'), findsOneWidget);
  });

  testWidgets('the CTA advances', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Next: where you shop'));
    await tester.pumpAndSettle();
    expect(nexts, 1);
  });
}
