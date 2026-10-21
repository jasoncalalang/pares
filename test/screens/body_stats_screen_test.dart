import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:mealpal_ph/screens/body_stats_screen.dart';
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
      host(BodyStatsScreen(draft: draft, onNext: () => nexts++)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows step 1 copy, every field and the CTA', (tester) async {
    await pump(tester);
    expect(find.text('STEP 1 OF 4'), findsOneWidget);
    expect(find.text('Tell us about you'), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Age'), findsOneWidget);
    expect(find.text('Height'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('yrs'), findsOneWidget);
    expect(find.text('cm'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);
    expect(find.text('Activity level'), findsOneWidget);
    for (final a in ['Sedentary', 'Light', 'Moderate', 'Active']) {
      expect(find.text(a), findsOneWidget);
    }
    expect(find.text('Compute my target'), findsOneWidget);
    expect(find.textContaining('Everything is in metric: kg and cm.'),
        findsOneWidget);
    expect(find.text('An estimate, not medical advice. You can adjust it anytime.'),
        findsOneWidget);
  });

  testWidgets('prefills the draft values', (tester) async {
    await pump(tester);
    expect(find.widgetWithText(TextField, '29'), findsOneWidget);
    expect(find.widgetWithText(TextField, '171'), findsOneWidget);
    expect(find.widgetWithText(TextField, '74'), findsOneWidget);
  });

  testWidgets('gender and activity toggles write to the draft',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('Female'));
    await tester.pumpAndSettle();
    expect(draft.sex, BiologicalSex.female);

    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();
    expect(draft.activity, ActivityLevel.active);
  });

  testWidgets('typing a weight writes to the draft', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const ValueKey('field-weight')), '80');
    expect(draft.weightKg, 80);
    await tester.enterText(find.byKey(const ValueKey('field-age')), '35');
    expect(draft.age, 35);
  });

  testWidgets('the CTA advances', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Compute my target'));
    await tester.pumpAndSettle();
    expect(nexts, 1);
  });

  testWidgets('an emptied field disables the CTA until it is filled again',
      (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const ValueKey('field-weight')), '');
    await tester.pumpAndSettle();
    expect(find.text('Fill in age, height and weight to continue.'),
        findsOneWidget);
    await tester.tap(find.text('Compute my target'));
    await tester.pumpAndSettle();
    expect(nexts, 0);
    expect(draft.weightKg, 74, reason: 'the draft keeps its last valid value');

    await tester.enterText(find.byKey(const ValueKey('field-weight')), '80');
    await tester.pumpAndSettle();
    expect(find.text('Fill in age, height and weight to continue.'), findsNothing);
    await tester.tap(find.text('Compute my target'));
    await tester.pumpAndSettle();
    expect(nexts, 1);
    expect(draft.weightKg, 80);
  });
}
